#!/usr/bin/env python3
"""
D Vulkan bindings generator, based off of and using the Vulkan-Docs code.

to generate bindings run: vkdgen.py path/to/vulcan-docs outputdir
"""

import sys
import re
import os
from os import path
from itertools import islice

re_funcptr = re.compile(r"^typedef (.+) \(VKAPI_PTR \*$")
re_single_const = re.compile(r"^const\s+(.+)\*\s*$")
re_double_const = re.compile(r"^const\s+(.+)\*\s+const\*\s*$")
re_array = re.compile(r"^([^\[]+)\[(\d+)\]$")
re_camel_case = re.compile(r"([a-z])([A-Z])")
re_long_int = re.compile(r"([0-9]+)ULL")

if len( sys.argv ) > 2 and not sys.argv[ 2 ].startswith( "--" ):
	sys.path.append( sys.argv[ 1 ] + "/src/spec/" )

try:
	from reg import *
	from generator import OutputGenerator, GeneratorOptions, write
except ImportError as e:
	print( "Could not import Vulkan generator; please ensure that the first argument points to Vulkan-Docs directory", file = sys.stderr )
	print( "-----", file = sys.stderr )
	raise

PACKAGE_HEADER = """\
module {PACKAGE_PREFIX};
public import {PACKAGE_PREFIX}.types;
public import {PACKAGE_PREFIX}.functions;\
"""

TYPES_HEADER = """\
module {PACKAGE_PREFIX}.types;

alias uint8_t = ubyte;
alias uint16_t = ushort;
alias uint32_t = uint;
alias uint64_t = ulong;
alias int8_t = byte;
alias int16_t = short;
alias int32_t = int;
alias int64_t = long;

@nogc nothrow:
pure {{
	uint VK_MAKE_VERSION( uint major, uint minor, uint patch ) {{
		return ( major << 22 ) | ( minor << 12 ) | ( patch );
	}}

	// Vulkan 1.0 version number
	uint VK_API_VERSION_1_0() {{ return VK_MAKE_VERSION( 1, 0, 0 ); }}

	uint VK_VERSION_MAJOR( uint ver ) {{ return ver >> 22; }}
	uint VK_VERSION_MINOR( uint ver ) {{ return ( ver >> 12 ) & 0x3ff; }}
	uint VK_VERSION_PATCH( uint ver ) {{ return ver & 0xfff; }}
}}

// Linkage of debug and allocation callbacks
extern( System ):

// Version of corresponding c header file
{HEADER_VERSION}

enum VK_NULL_HANDLE = null;

enum VK_DEFINE_HANDLE( string name ) = "struct "~name~"_handle; alias "~name~" = "~name~"_handle*;";

version( X86_64 ) {{
	alias VK_DEFINE_NON_DISPATCHABLE_HANDLE( string name ) = VK_DEFINE_HANDLE!name;
	enum VK_NULL_ND_HANDLE = null;
}} else {{
	enum VK_DEFINE_NON_DISPATCHABLE_HANDLE( string name ) = "alias "~name~" = ulong;";
	enum VK_NULL_ND_HANDLE = 0uL;
}}\

"""

FUNCTIONS_HEADER = """\
module {PACKAGE_PREFIX}.functions;

public import {PACKAGE_PREFIX}.types;

extern( System ) @nogc nothrow {{\
"""

def getFullType( elem, opaqueStruct = None ):
	typ = elem.find( "type" )
	typstr = ( elem.text or "" ).lstrip() + typ.text.strip() + ( typ.tail or "" ).rstrip()

	# catch opaque structs
	if typstr.startswith( 'struct' ):
		typstr = typstr.lstrip( 'struct ' )
		if isinstance( opaqueStruct, set ):
			opaqueStruct.add( typstr.rstrip( '*' ))

	arrlen = elem.find( "enum" )
	if arrlen is not None:
		return "{0}[ {1} ]".format( typstr, arrlen.text )
	else:
		name = elem.find( "name" )
		return typstr + ( name.tail or "" )

def convertTypeConst( typ ):
	"""
	Converts C const syntax to D const syntax
	"""
	doubleConstMatch = re.match( re_double_const, typ )
	if doubleConstMatch:
		return "const( {0}* )*".format( doubleConstMatch.group( 1 ))
	else:
		singleConstMatch = re.match( re_single_const, typ )
		if singleConstMatch:
			return "const( {0} )*".format( singleConstMatch.group( 1 ))
	return typ

def convertTypeArray( typ, name ):
	arrMatch = re.match( re_array, name )
	if arrMatch:
		return "{0}[ {1} ]".format( typ, arrMatch.group( 2 )), arrMatch.group( 1 )
	else:
		return typ, name

class DGenerator( OutputGenerator ):
	# This is an ordered list of sections in the header file.
	TYPE_SECTIONS = [ 'include', 'define', 'basetype', 'handle', 'enum', 'group', 'bitmask', 'funcpointer', 'struct' ]
	ALL_SECTIONS = TYPE_SECTIONS + [ 'commandPointer', 'command' ]
	def __init__( self, errFile = sys.stderr, warnFile = sys.stderr, diagFile = sys.stderr ):
		super().__init__( errFile, warnFile, diagFile )
		self.headerVersion = ""
		self.typesFileContent = ""

		self.opaqueStruct = set()
		self.sections = dict( [ ( section, [] ) for section in self.ALL_SECTIONS ] )
		self.functionTypeName = dict()
		self.functionTypeDefinition = ""

		self.instanceLevelFuncNames = set()
		self.instanceLevelFunctions = ""
		self.deviceLevelFuncNames = set()
		self.deviceLevelFunctions = ""

		self.dispatchTypeDefinition = ""
		self.dispatchConvenienceFuncNames = dict()
		self.dispatchConvenienceFunctions = ""
		self.maxDispatchConvenienceFuncName = 0

		self.platformExtensions = {
			"// VK_KHR_android_surface"          : [ "VK_USE_PLATFORM_ANDROID_KHR", "public import android.native_window;\n" ],
			"// VK_KHR_mir_surface"              : [ "VK_USE_PLATFORM_MIR_KHR",     "public import mir_toolkit.client_types;\n" ],
			"// VK_KHR_wayland_surface"          : [ "VK_USE_PLATFORM_WAYLAND_KHR", "public import wayland.native.client;\n" ],
			"// VK_KHR_win32_surface"            : [ "VK_USE_PLATFORM_WIN32_KHR",   "public import core.sys.windows.windows;\n" ],
			"// VK_KHR_xlib_surface"             : [ "VK_USE_PLATFORM_XLIB_KHR",    "public import X11.Xlib;\n" ],
			"// VK_EXT_acquire_xlib_display"     : [ "VK_USE_PLATFORM_XLIB_KHR" ,   "" ],
			"// VK_KHR_xcb_surface"              : [ "VK_USE_PLATFORM_XCB_KHR",     "public import xcb.xcb;\n" ],
			"// VK_NV_external_memory_win32"     : [ "VK_USE_PLATFORM_WIN32_KHR",   "public import core.sys.windows.winnt;\n" ],
			"// VK_KHR_external_memory_win32"    : [ "VK_USE_PLATFORM_WIN32_KHR",   "" ],
			"// VK_NV_win32_keyed_mutex"         : [ "VK_USE_PLATFORM_WIN32_KHR",   "" ],
			"// VK_KHX_win32_keyed_mutex"        : [ "VK_USE_PLATFORM_WIN32_KHR",   "" ],
			"// VK_KHR_external_semaphore_win32" : [ "VK_USE_PLATFORM_WIN32_KHR",   "" ],
			"// VK_KHR_external_fence_win32"     : [ "VK_USE_PLATFORM_WIN32_KHR",   "" ],
		}

	def beginFile( self, genOpts ):
		self.genOpts = genOpts
		try:
			os.mkdir( genOpts.filename )
		except FileExistsError:
			pass

		self.typesFile = open( path.join( genOpts.filename, "types.d" ), "w", encoding = "utf-8" )
		self.funcsFile = open( path.join( genOpts.filename, "functions.d" ), "w", encoding = "utf-8" )

		#self.testsFile = open( path.join( genOpts.filename, "test.txt" ), "w", encoding = "utf-8" )

		with open( path.join( genOpts.filename, "package.d" ), "w", encoding = "utf-8" ) as packageFile:
			write( PACKAGE_HEADER.format( PACKAGE_PREFIX = genOpts.packagePrefix ), file = packageFile )

		write( FUNCTIONS_HEADER.format( PACKAGE_PREFIX = genOpts.packagePrefix ), file = self.funcsFile )

	def endFile( self ):

		# write types.d file
		write( TYPES_HEADER.format( PACKAGE_PREFIX = self.genOpts.packagePrefix, HEADER_VERSION = self.headerVersion ) + self.typesFileContent, file = self.typesFile )

		# write functions.d file
		write( "}}\n\n__gshared {{{GLOBAL_FUNCTION_DEFINITIONS}\n}}\n".format( GLOBAL_FUNCTION_DEFINITIONS = self.functionTypeDefinition ), file = self.funcsFile )
		write( """\
/// if not using version "with-derelict-loader" this function must be called first
/// sets vkCreateInstance function pointer and acquires basic functions to retrieve information about the implementation
void loadGlobalLevelFunctions( typeof( vkGetInstanceProcAddr ) getProcAddr ) {
	vkGetInstanceProcAddr = getProcAddr;
	vkEnumerateInstanceExtensionProperties = cast( typeof( vkEnumerateInstanceExtensionProperties )) vkGetInstanceProcAddr( null, "vkEnumerateInstanceExtensionProperties" );
	vkEnumerateInstanceLayerProperties = cast( typeof( vkEnumerateInstanceLayerProperties )) vkGetInstanceProcAddr( null, "vkEnumerateInstanceLayerProperties" );
	vkCreateInstance = cast( typeof( vkCreateInstance )) vkGetInstanceProcAddr( null, "vkCreateInstance" );
}

/// with a valid VkInstance call this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
void loadInstanceLevelFunctions( VkInstance instance ) {
	assert( vkGetInstanceProcAddr !is null, "Must call loadGlobalLevelFunctions before loadInstanceLevelFunctions" );\
"""
		+ self.instanceLevelFunctions
		+ """\n\
}

/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
/// use loadDeviceLevelFunctions( VkDevice device ) bellow to avoid this indirection and get the pointers directly form a VkDevice
void loadDeviceLevelFunctions( VkInstance instance ) {
	assert( vkGetInstanceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions" );\
"""
		+ self.deviceLevelFunctions.format( INSTANCE_OR_DEVICE = "Instance", instance_or_device = "instance" )
		+ """\n\
}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call directly VkDevice and related resources and can be retrieved for one and only one VkDevice
/// calling this function again with another VkDevices will overwrite the __gshared functions retrieved previously
/// use createGroupedDeviceLevelFunctions bellow if usage of multiple VkDevices is required
void loadDeviceLevelFunctions( VkDevice device ) {
	assert( vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions" );\
"""
		+ self.deviceLevelFunctions.format( INSTANCE_OR_DEVICE = "Device", instance_or_device = "device" )
		+ """\n\
}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions grouped in a DispatchDevice struct
/// the functions call directly VkDevice and related resources and can be retrieved for any VkDevice
deprecated( \"Use DispatchDevice( VkDevice ) or DispatchDevice.loadDeviceLevelFunctions( VkDevice ) instead\" )
DispatchDevice createDispatchDeviceLevelFunctions( VkDevice device ) {
	return DispatchDevice( device );
}


// struct to group per device deviceLevelFunctions into a custom namespace
// keeps track of the device to which the functions are bound
struct DispatchDevice {
	private VkDevice device = VK_NULL_HANDLE;
	VkCommandBuffer commandBuffer;

	// return copy of the internal VkDevice
	VkDevice vkDevice() {
		return device;
	}

	// Constructor forwards parameter 'device' to 'this.loadDeviceLevelFunctions'
	this( VkDevice device ) {
		this.loadDeviceLevelFunctions( device );
	}

	// load the device level member functions
	// this also sets the private member 'device' to the passed in VkDevice
	// now the DispatchDevice can be used e.g.:
	//		auto dd = DispatchDevice( device );
	//		dd.vkDestroyDevice( dd.vkDevice, pAllocator );
	// convenience functions to omit the first arg do exist, see bellow
	void loadDeviceLevelFunctions( VkDevice device ) {
		assert( vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions" );
		this.device = device;\
"""
			+ self.deviceLevelFunctions.format( INSTANCE_OR_DEVICE = "Device", instance_or_device = "device" ).replace( '\t', '\t\t' ).replace( '\t\t\t\t', '\t\t\t' )
			+ """\n\
	}

	// Convenience member functions, forwarded to corresponding vulkan functions
	// If the first arg of the vulkan function is VkDevice it can be omitted
	// private 'DipatchDevice' member 'device' will be passed to the forwarded vulkan functions
	// the crux is that function pointers can't be overloaded with regular functions
	// hence the vk prefix is ditched for the convenience variants
	// e.g.:
	//		auto dd = DispatchDevice( device );
	//		dd.DestroyDevice( pAllocator );		// instead of: dd.vkDestroyDevice( dd.vkDevice, pAllocator );
	//
	// Same mechanism works with functions which require a VkCommandBuffer as first arg
	// In this case the public member 'commandBuffer' must be set beforehand
	// e.g.:
	//		dd.commandBuffer = some_command_buffer;
	//		dd.BeginCommandBuffer( &beginInfo );
	//		dd.CmdBindPipeline( VK_PIPELINE_BIND_POINT_GRAPHICS, some_pipeline );
	//
	// Does not work with queues, there are just too few queue related functions"""

	+ self.dispatchConvenienceFunctions
	+ """\n\

	// Member vulkan function decelerations{DISPATCH_FUNCTION_DEFINITIONS}
}}

// Derelict loader to acquire entry point vkGetInstanceProcAddr
version( {NAME_PREFIX_UCASE}_FROM_DERELICT ) {{
	import derelict.util.loader;
	import derelict.util.system;

	private {{
		version( Windows )
			enum libNames = "vulkan-1.dll";

		else version( Posix )
			enum libNames = "libvulkan.so.1";

		else
			static assert( 0,"Need to implement Vulkan libNames for this operating system." );
	}}

	class Derelict{NAME_PREFIX}Loader : SharedLibLoader {{
		this() {{
			super( libNames );
		}}

		protected override void loadSymbols() {{
			typeof( vkGetInstanceProcAddr ) getProcAddr;
			bindFunc( cast( void** )&getProcAddr, "vkGetInstanceProcAddr" );
			loadGlobalLevelFunctions( getProcAddr );
		}}
	}}

	__gshared Derelict{NAME_PREFIX}Loader Derelict{NAME_PREFIX};

	shared static this() {{
		Derelict{NAME_PREFIX} = new Derelict{NAME_PREFIX}Loader();
	}}
}}

""".format(
	NAME_PREFIX = self.genOpts.namePrefix,
	NAME_PREFIX_UCASE = self.genOpts.namePrefix.upper(),
	DISPATCH_FUNCTION_DEFINITIONS = self.dispatchTypeDefinition ),
	file = self.funcsFile )

		self.typesFile.close()
		self.funcsFile.close()

	def beginFeature( self, interface, emit ):
		OutputGenerator.beginFeature( self, interface, emit )
		#if interface.attrib.get( 'protect' ):
			#write( interface.attrib[ 'name' ], file = self.testsFile )
		self.currentFeature = "// {0}".format( interface.attrib[ 'name' ] )
		self.sections = dict( [ ( section, [] ) for section in self.ALL_SECTIONS ] )
		self.opaqueStruct.clear()
		self.platformExtensionVersionIndent = ""
		self.isPlatformExtension = self.currentFeature in self.platformExtensions
		if self.isPlatformExtension:
			self.platformExtensionVersionIndent = "\t"

	def endFeature( self ):
		if self.emit:
			# first write all types into types.d

			# special treat for platform surface extension which get wrapped into a version block
			extIndent = self.platformExtensionVersionIndent
			fileContent = self.typesFileContent
			fileContent += "\n{0}\n".format( self.currentFeature )
			version_platform = ""
			if self.isPlatformExtension:
				version_platform = "version( {0} ) {{".format( self.platformExtensions[ self.currentFeature ][ 0 ] )
				fileContent += "{0}\n\t{1}\n".format( version_platform, self.platformExtensions[ self.currentFeature ][ 1 ] )

			isFirstSectionInFeature = True		# for output file formating
			for section in self.TYPE_SECTIONS:
				# write contents of type section
				contents = self.sections[ section ]
				if contents:
					# check if opaque structs were registered and write them into types file
					if section == 'struct':
						if self.opaqueStruct:
							for opaque in self.opaqueStruct:
								# special handling for wayland
								if opaque == "wl_display":
									continue
								elif opaque == "wl_surface":
									fileContent += "{0}alias wl_surface = wl_proxy;\n".format( extIndent );
								else:
									fileContent += "{1}struct {0};\n".format( opaque, extIndent )
							fileContent += '\n'

					elif not isFirstSectionInFeature:
						fileContent += '\n'

					# for output file formating
					isFirstSectionInFeature = False

					# write the rest of the contents, eg. enums, structs, etc. into types file
					for content in self.sections[ section ]:
						fileContent += "{1}{0}\n".format( content, extIndent )

			if self.isPlatformExtension:
				fileContent += "}\n"

			self.typesFileContent = fileContent

			fileContent = ""

			# currently the commandPointer token is not used by Khronos
			if self.genOpts.genFuncPointers and self.sections[ 'commandPointer' ]:
				if self.isPlatformExtension: fileContent += version_platform#write( version_platform, file = self.funcsFile )
				fileContent += '\n' + extIndent + ( '\n' + extIndent ).join( self.sections[ 'commandPointer' ] ) #write( extIndent + ( '\n' + extIndent ).join( self.sections[ 'commandPointer' ] ), file = self.funcsFile )
				if self.isPlatformExtension: fileContent += "\n}" #write( "}", file = self.funcsFile )
				fileContent += '\n' #write( '', file = self.funcsFile )
				write( fileContent, file = self.funcsFile )
				fileContent = ""

			# write function aliases into functions.d and build strings for later injection
			if self.sections[ 'command' ]:
				# update indention of currentFeature for functions.d content
				self.currentFeature = "\t" + self.currentFeature;

				# write the aliases to function types
				fileContent += "\n{0}".format( self.currentFeature ) #write( "\n{0}".format( self.currentFeature ), file = self.funcsFile )
				if self.isPlatformExtension: fileContent += "\n\t" + version_platform #write( "\t" + version_platform, file = self.funcsFile )
				fileContent += "\n" + extIndent + ( '\n' + extIndent ).join( self.sections[ 'command' ] ) #write( extIndent + ( '\n' + extIndent ).join( self.sections[ 'command' ] ), file = self.funcsFile )
				if self.isPlatformExtension: fileContent += "\n\t}" #write( "\t}", file = self.funcsFile )
				write( fileContent, file = self.funcsFile )
				fileContent = ""

				# capture if function is a instance or device level function
				inInstanceLevelFuncNames = False
				inDeviceLevelFuncNames = False
				inDispatchConvenienceFuncNames = False

				# comment the current feature
				self.functionTypeDefinition += "\n\n{0}".format( self.currentFeature )

				# surface extension version directive
				if self.isPlatformExtension: self.functionTypeDefinition += "\n\t" + version_platform

				# create string of functionTypes functionVars
				for command in self.sections[ 'command' ]:
					name = self.functionTypeName[ command ]
					self.functionTypeDefinition += "\n\t{1}PFN_{0} {0};".format( name, extIndent )

					# query if the current function is in instance or deviceLevelFuncNames for the next step
					if not inInstanceLevelFuncNames and name in self.instanceLevelFuncNames:
						inInstanceLevelFuncNames = True

					if not inDeviceLevelFuncNames and name in self.deviceLevelFuncNames:
						inDeviceLevelFuncNames = True

					inDispatchConvenienceFuncNames = name in self.dispatchConvenienceFuncNames

				# surface extension version closing curly brace
				if self.isPlatformExtension: self.functionTypeDefinition += "\n\t}"

				# create a strings to load instance level functions
				if inInstanceLevelFuncNames:
					# comment the current feature
					self.instanceLevelFunctions += "\n\n{0}".format( self.currentFeature )

					# surface extension version directive
					if self.isPlatformExtension: self.instanceLevelFunctions += "\n\t" + version_platform

					# set of global level function names, function pointers are ignored here are set in endFile method
					gloablLevelFuncNames = {"vkGetInstanceProcAddr", "vkEnumerateInstanceExtensionProperties", "vkEnumerateInstanceLayerProperties", "vkCreateInstance"}

					# build the commands
					for command in self.sections[ 'command' ]:
						name = self.functionTypeName[ command ]
						if name in self.instanceLevelFuncNames and name not in gloablLevelFuncNames:
							self.instanceLevelFunctions += "\n\t{1}{0} = cast( typeof( {0} )) vkGetInstanceProcAddr( instance, \"{0}\" );".format( name, extIndent )

					# surface extension version closing curly brace
					if self.isPlatformExtension:
						self.instanceLevelFunctions += "\n\t}"

				# create a string to load device level functions
				if inDeviceLevelFuncNames:
					# comment the current feature
					self.deviceLevelFunctions += "\n\n{0}".format( self.currentFeature )

					# surface extension version directive
					if self.isPlatformExtension:
						# add version_platform into the DispatchDevice struct
						self.dispatchTypeDefinition += "\n\t" + version_platform

						# need to change version platform due to INSTANCE_OR_DEVICE format element
						version_platform = "version( {0} ) {{{{".format( self.platformExtensions[ self.currentFeature[1:] ][ 0 ] )
						self.deviceLevelFunctions += "\n\t" + version_platform


					# build the commands
					for command in self.sections[ 'command' ]:
						name = self.functionTypeName[ command ]
						if name in self.deviceLevelFuncNames:
							self.deviceLevelFunctions += "\n\t{1}{0} = cast( typeof( {0} )) vkGet{{INSTANCE_OR_DEVICE}}ProcAddr( {{instance_or_device}}, \"{0}\" );".format( name, extIndent )

							# this function type definitions end up in the DispatchDevice struct
							self.dispatchTypeDefinition += "\n\t{1}PFN_{0} {0};".format( name, extIndent )

					# surface extension version closing curly brace
					if self.isPlatformExtension:
						self.deviceLevelFunctions += "\n\t}}"	# closing braces for formated device level functions
						self.dispatchTypeDefinition += "\n\t}"	# closing braces for unformated dispatch device struct


				# create a string for DispatchDevice convenience functions
				if inDispatchConvenienceFuncNames:
					# comment the current feature
					self.dispatchConvenienceFunctions += "\n\n{0}".format( self.currentFeature )

					# surface extension version directive
					if self.isPlatformExtension:

						# need to change version platform due to INSTANCE_OR_DEVICE format element
						version_platform = "version( {0} ) {{".format( self.platformExtensions[ self.currentFeature[1:] ][ 0 ] )
						self.dispatchConvenienceFunctions += "\n\t" + version_platform


					# build the commands
					for command in self.sections[ 'command' ]:
						name = self.functionTypeName[ command ]
						if name in self.dispatchConvenienceFuncNames:
							self.dispatchConvenienceFunctions +=  '\n' + self.dispatchConvenienceFuncNames[ name ].format( extIndent )

					# surface extension version closing curly brace
					if self.isPlatformExtension:
						self.dispatchConvenienceFunctions += "\n\t}"	# closing braces for formated device level functions


		# Finish processing in superclass
		OutputGenerator.endFeature( self )

	# Append a definition to the specified section
	def appendSection( self, section, text ):
		self.sections[ section ].append( text )

	def genType( self, typeinfo, name ):
		super().genType( typeinfo, name )
		if "requires" in typeinfo.elem.attrib:
			required = typeinfo.elem.attrib[ "requires" ]
			if required.endswith( ".h" ):
				return
			elif required == "vk_platform":
				return

		if "category" not in typeinfo.elem.attrib:
			#for k, v in typeinfo.elem.attrib.items():
			#	write( k, v, file = self.testsFile )
			return

		category = typeinfo.elem.attrib[ "category" ]

		if category == "handle":
			self.appendSection( "handle", "mixin( {0}!q{{{1}}} );".format( typeinfo.elem.find( "type" ).text, name ))

		elif category == "basetype":
			self.appendSection( "basetype", "alias {0} = {1};".format( name, typeinfo.elem.find( "type" ).text ))

		elif category == "bitmask":
			self.appendSection( "bitmask", "alias {0} = VkFlags;".format( name ))

		elif category == "funcpointer":
			returnType = re.match( re_funcptr, typeinfo.elem.text ).group( 1 )
			params = "".join( islice( typeinfo.elem.itertext(), 2, None ))[ 2: ]
			if params == "void);" or params == " void );" : params = ");"
			#else: params = ' '.join( ' '.join( line.strip() for line in params.splitlines()).split())
			else:
				concatParams = ""
				for line in params.splitlines():
					lineSplit = line.split()
					if len( lineSplit ) > 2:
						concatParams += ' ' + convertTypeConst( lineSplit[ 0 ] + ' ' + lineSplit[ 1 ] ) + ' ' + lineSplit[ 2 ]
					else:
						concatParams += ' ' + ' '.join( param for param in lineSplit )

				params = concatParams[ 2: ]

			self.appendSection( "funcpointer", "alias {0} = {1} function( {2}".format( name, returnType, params ))
			#write( params, file = self.testsFile )


		elif category == "struct" or category == "union":
			self.genStruct( typeinfo, name )

		elif category == 'define' and name == 'VK_HEADER_VERSION':
			for headerVersion in islice( typeinfo.elem.itertext(), 2, 3 ):	# get the version string from the one element list
				self.headerVersion = "enum VK_HEADER_VERSION  = {0};".format( headerVersion )

		else:
			pass

	def genStruct( self, typeinfo, name ):
		super().genStruct( typeinfo, name )
		category = typeinfo.elem.attrib[ "category" ]
		self.appendSection( "struct", "\n{2}{0} {1} {{".format( category, name, self.platformExtensionVersionIndent ))
		targetLen = 0
		memberTypeName = []

		for member in typeinfo.elem.findall( "member" ):
			memberType = convertTypeConst( getFullType( member, self.opaqueStruct ).strip())
			memberName = member.find( "name" ).text

			if memberName == "module":
				# don't use D identifiers
				memberName = "_module"

			if member.get( "values" ):
				memberName += " = " + member.get( "values" )
				#write( memberName, file = self.testsFile )

			# get the maximum string length of all member types
			memberType, memberName = convertTypeArray( memberType, memberName )
			memberTypeName.append( ( memberType, memberName ))
			targetLen = max( targetLen, len( memberType ))

		# loop second time and use maximum type string length to offset member names
		for type_name in memberTypeName:
			self.appendSection( "struct", "\t{0}  {1};".format( type_name[0].ljust( targetLen ), type_name[1] ))

		self.appendSection( "struct", "}" )


	def genGroup( self, groupinfo, groupName ):
		super().genGroup( groupinfo, groupName )

		groupElem = groupinfo.elem

		expandName = re.sub( r'([0-9a-z_])([A-Z0-9][^A-Z0-9]?)', r'\1_\2', groupName ).upper()

		expandPrefix = expandName
		expandSuffix = ''
		expandSuffixMatch = re.search( r'[A-Z][A-Z]+$', groupName )
		if expandSuffixMatch:
			expandSuffix = '_' + expandSuffixMatch.group()
			# Strip off the suffix from the prefix
			expandPrefix = expandName.rsplit( expandSuffix, 1 )[ 0 ]

		# group enums by their name
		body = "\nenum " + groupName + " {\n"

		# add grouped enums to global scope
		globalEnums = "\n\n// " + groupName + " global enums\n"

		isEnum = ( 'FLAG_BITS' not in expandPrefix )

		# Loop over the nested 'enum' tags. Keep track of the minimum and
		# maximum numeric values, if they can be determined; but only for
		# core API enumerants, not extension enumerants. This is inferred
		# by looking for 'extends' attributes.
		minName = None
		for elem in groupElem.findall( 'enum' ):
			# Convert the value to an integer and use that to track min/max.
			# Values of form -( number ) are accepted but nothing more complex.
			# Should catch exceptions here for more complex constructs. Not yet.
			( numVal, strVal ) = self.enumToValue( elem, True )
			name = elem.get( 'name' )

			# Extension enumerants are only included if they are requested
			# in addExtensions or match defaultExtensions.
			if ( elem.get( 'extname' ) is None or
				re.match( self.genOpts.addExtensions, elem.get( 'extname' )) is not None or
				self.genOpts.defaultExtensions == elem.get( 'supported' )):
				body += "\t" + name + " = " + strVal + ",\n"
				globalEnums += "enum {0} = {1}.{0};\n".format( name, groupName )

			if isEnum and elem.get( 'extends' ) is None:
				if minName is None:
					minName = maxName = name
					minValue = maxValue = numVal
				elif numVal < minValue:
					minName = name
					minValue = numVal
				elif numVal > maxValue:
					maxName = name
					maxValue = numVal
		# Generate min/max value tokens and a range-padding enum. Need some
		# additional padding to generate correct names...
		if isEnum:
			body += "\t" + expandPrefix + "_BEGIN_RANGE" + expandSuffix + " = " + minName + ",\n"
			body += "\t" + expandPrefix + "_END_RANGE"   + expandSuffix + " = " + maxName + ",\n"
			body += "\t" + expandPrefix + "_RANGE_SIZE"  + expandSuffix + " = ( " + maxName + " - " + minName + " + 1 ),\n"

			globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};\n".format( expandPrefix, "_BEGIN_RANGE", expandSuffix, groupName )
			globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};\n".format( expandPrefix, "_END_RANGE"  , expandSuffix, groupName )
			globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};\n".format( expandPrefix, "_RANGE_SIZE" , expandSuffix, groupName )

		body += "\t" + expandPrefix + "_MAX_ENUM" + expandSuffix + " = 0x7FFFFFFF\n}"
		globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};".format( expandPrefix, "_MAX_ENUM" , expandSuffix, groupName )

		if groupElem.get( 'type' ) == 'bitmask':
			self.appendSection( 'bitmask', body + globalEnums )
		else:
			self.appendSection( 'group', body + globalEnums )

	def genEnum( self, enuminfo, name ):
		super().genEnum( enuminfo, name )
		_,strVal = self.enumToValue( enuminfo.elem, False )
		if strVal == "VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT":
			strVal = "VkStructureType." + strVal
		strVal = re.sub( re_long_int, "\g<1>UL", strVal )
		self.appendSection( 'enum', "enum {0} = {1};".format( name, strVal ))

	def genCmd( self, cmdinfo, name ):
		#if name not in {"vkGetInstanceProcAddr", "vkEnumerateInstanceExtensionProperties", "vkEnumerateInstanceLayerProperties", "vkCreateInstance"}:
		super().genCmd( cmdinfo, name )
		proto = cmdinfo.elem.find( "proto" )
		returnType = convertTypeConst( getFullType( proto ).strip())
		#write( returnType, file = self.testsFile )

		params = cmdinfo.elem.findall( "param" )
		joinedParams = ", ".join( convertTypeConst( getFullType( param, self.opaqueStruct ).strip()) + " " + param.find( "name" ).text for param in params )
		funcTypeName = "\talias PFN_{0} = {1} function( {2} );".format( name, returnType, joinedParams )
		self.appendSection( 'command', funcTypeName )
		self.functionTypeName[ funcTypeName ] = name

		if name != "vkGetDeviceProcAddr" and getFullType( params[ 0 ] ) in { "VkDevice", "VkQueue", "VkCommandBuffer" }:
			self.deviceLevelFuncNames.add( name )

			doReturn = ""
			if returnType != "void":
				doReturn = "return "

			joinedArgs = ""
			if len( params[1:] ):
				joinedArgs = ", " + ", ".join( param.find( "name" ).text for param in params[1:] )
			joinedParams = ", ".join( convertTypeConst( getFullType( param, self.opaqueStruct ).strip()) + " " + param.find( "name" ).text for param in params[1:] )
			self.maxDispatchConvenienceFuncName = max( len( returnType ) + 2 + len( name ) + 2 + len( joinedParams ) + 2, self.maxDispatchConvenienceFuncName )

			# create convenience functions for DispatchDevice
			if getFullType( params[ 0 ] ) == "VkDevice":
				forwardFuncs = "\t{{0}}{0} {1}( {2} ) {{{{\n{{0}}\t\t{3}{4}( this.device{5} );\n{{0}}\t}}}}".format(
					returnType, name[2:], joinedParams, doReturn, name, joinedArgs ).replace( '(  )', '()' )
				self.dispatchConvenienceFuncNames[ name ] = forwardFuncs
				#write( forwardFuncs, file = self.testsFile )

			elif getFullType( params[ 0 ] ) == "VkCommandBuffer":
				forwardFuncs = "{{0}}\t{0} {1}( {2} ) {{{{\n{{0}}\t\t{3}{4}( this.commandBuffer{5} );\n{{0}}\t}}}}".format(
					returnType, name[2:], joinedParams, doReturn, name, joinedArgs ).replace( '(  )', '()' )
				self.dispatchConvenienceFuncNames[ name ] = forwardFuncs
				#write( forwardFuncs, file = self.testsFile )

			#else: #elif getFullType( params[ 0 ] ) == "VkQueue":
				#forwardFuncs = "\t{0} {1}( {2} ) {{ queue.{1}( {4} ); }}".format( returnType, name, joinedParams, joinedArgs ).replace( '(  )', '()' )
				#self.dispatchConvenienceFuncNames[ name ] = forwardFuncs
				#write( forwardFuncs, file = self.testsFile )

		else:
			self.instanceLevelFuncNames.add( name )


class DGeneratorOptions( GeneratorOptions ):
	def __init__( self, *args, **kwargs ):
		self.packagePrefix = kwargs.pop( "packagePrefix" )
		self.namePrefix = kwargs.pop( "namePrefix" )
		self.genFuncPointers = kwargs.pop( "genFuncPointers" )
		super().__init__( *args, **kwargs )

if __name__ == "__main__":
	import argparse

	vkxml = "vk.xml"
	parser = argparse.ArgumentParser()
	if len( sys.argv ) > 2 and not sys.argv[ 2 ].startswith( "--" ):
		parser.add_argument( "vulkandocs" )
		vkxml = sys.argv[ 1 ] + "/src/spec/vk.xml"

	parser.add_argument( "outfolder" )
	parser.add_argument( "--packagePrefix", default = "erupted" )
	parser.add_argument( "--namePrefix", default = "Erupted" )

	args = parser.parse_args()

	gen = DGenerator()
	reg = Registry()
	reg.loadElementTree( etree.parse( vkxml ))
	reg.setGenerator( gen )
	reg.apiGen(
		DGeneratorOptions(
		filename = args.outfolder,
		apiname = "vulkan",
		versions = ".*",
		emitversions = ".*",
		packagePrefix = args.packagePrefix,
		namePrefix = args.namePrefix,
		genFuncPointers  = True,
		#defaultExtensions = "defaultExtensions",
		addExtensions = r".*",
		#removeExtensions = None#r"VK_KHR_.*_surface$"
	))

# 146: Platform Extensions
# 171: Test File