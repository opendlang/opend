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

if len(sys.argv) > 2 and not sys.argv[2].startswith( "--" ):
	sys.path.append(sys.argv[1] + "/src/spec/")

try:
	from reg import *
	from generator import OutputGenerator, GeneratorOptions, write
except ImportError as e:
	print("Could not import Vulkan generator; please ensure that the first argument points to Vulkan-Docs directory", file=sys.stderr)
	print("-----", file=sys.stderr)
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

@nogc pure nothrow:
uint VK_MAKE_VERSION(uint major, uint minor, uint patch) {{
	return (major << 22) | (minor << 12) | (patch);
}}
uint VK_VERSION_MAJOR(uint ver) {{
	return ver >> 22;
}}
uint VK_VERSION_MINOR(uint ver) {{
	return (ver >> 12) & 0x3ff;
}}
uint VK_VERSION_PATCH(uint ver) {{
	return ver & 0xfff;
}}

// Version of corresponding c header file
{HEADER_VERSION}

enum VK_NULL_HANDLE = null;

enum VK_DEFINE_HANDLE(string name) = "struct "~name~"_handle; alias "~name~" = "~name~"_handle*;";

version(X86_64) {{
	alias VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = VK_DEFINE_HANDLE!name;
}} else {{
	enum VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = "alias "~name~" = ulong;";
}}\
"""

FUNCTIONS_HEADER = """\
module {PACKAGE_PREFIX}.functions;

public import {PACKAGE_PREFIX}.types;

extern(System) @nogc nothrow {{\
"""

def getFullType(elem, opaqueStruct = None):
	typ = elem.find("type")
	typstr = (elem.text or "").lstrip() + typ.text.strip() + (typ.tail or "").rstrip()

	# catch opaque structs
	if typstr.startswith('struct'):
		typstr = typstr.lstrip('struct ')
		if isinstance(opaqueStruct, set):
			opaqueStruct.add(typstr.rstrip('*'))
	
	arrlen = elem.find("enum")
	if arrlen is not None:
		return "{0}[{1}]".format(typstr, arrlen.text)
	else:
		name = elem.find("name")
		return typstr + (name.tail or "")

def convertTypeConst(typ):
	"""
	Converts C const syntax to D const syntax
	"""
	doubleConstMatch = re.match(re_double_const, typ)
	if doubleConstMatch:
		return "const({0}*)*".format(doubleConstMatch.group(1))
	else:
		singleConstMatch = re.match(re_single_const, typ)
		if singleConstMatch:
			return "const({0})*".format(singleConstMatch.group(1))
	return typ

def convertTypeArray(typ, name):
	arrMatch = re.match(re_array, name)
	if arrMatch:
		return "{0}[{1}]".format(typ, arrMatch.group(2)), arrMatch.group(1)
	else:
		return typ, name

class DGenerator(OutputGenerator):
	# This is an ordered list of sections in the header file.
	TYPE_SECTIONS = ['include', 'define', 'basetype', 'handle', 'enum', 'group', 'bitmask', 'funcpointer', 'struct']
	ALL_SECTIONS = TYPE_SECTIONS + ['commandPointer', 'command']
	def __init__(self, errFile=sys.stderr, warnFile=sys.stderr, diagFile=sys.stderr):
		super().__init__(errFile, warnFile, diagFile)
		self.headerVersion = ""
		self.typesFileContent = ""
		self.instanceLevelFuncNames = set()
		self.instanceLevelFunctions = ""
		self.deviceLevelFuncNames = set()
		self.deviceLevelFunctions = ""
		self.sections = dict([(section, []) for section in self.ALL_SECTIONS])
		self.functionTypeName = dict()
		self.functionTypeDefinition = ""
		self.dispatchTypeDefinition = ""
		self.opaqueStruct = set()
		self.surfaceExtensions = {
			"// VK_KHR_android_surface" : ["VK_USE_PLATFORM_ANDROID_KHR",	"public import android.native_window;\n"],
			"// VK_KHR_mir_surface"     : ["VK_USE_PLATFORM_MIR_KHR",		"public import mir_toolkit.client_types;\n"],
			"// VK_KHR_wayland_surface" : ["VK_USE_PLATFORM_WAYLAND_KHR",	"public import wayland_client;\n"],
			"// VK_KHR_win32_surface"   : ["VK_USE_PLATFORM_WIN32_KHR",		"public import core.sys.windows.windows;\n"],
			"// VK_KHR_xlib_surface"    : ["VK_USE_PLATFORM_XLIB_KHR",		"public import X11.Xlib;\n"],
			"// VK_KHR_xcb_surface"	    : ["VK_USE_PLATFORM_XCB_KHR",		"public import xcb.xcb;\n"],
		}

	def beginFile(self, genOpts):
		self.genOpts = genOpts
		try:
			os.mkdir(genOpts.filename)
		except FileExistsError:
			pass
		
		self.typesFile = open(path.join(genOpts.filename, "types.d"), "w", encoding="utf-8")
		self.funcsFile = open(path.join(genOpts.filename, "functions.d"), "w", encoding="utf-8")

		#self.testsFile = open(path.join(genOpts.filename, "test.txt"), "w", encoding="utf-8")
		
		with open(path.join(genOpts.filename, "package.d"), "w", encoding="utf-8") as packageFile:
			write(PACKAGE_HEADER.format(PACKAGE_PREFIX = genOpts.packagePrefix), file=packageFile)
		
		write(FUNCTIONS_HEADER.format(PACKAGE_PREFIX = genOpts.packagePrefix), file=self.funcsFile)
	
	def endFile(self):
		# write types.d file
		write(TYPES_HEADER.format(PACKAGE_PREFIX = self.genOpts.packagePrefix, HEADER_VERSION = self.headerVersion) + self.typesFileContent, file=self.typesFile)

		# write functions.d file
		write("}}\n\n__gshared {{{GLOBAL_FUNCTION_DEFINITIONS}\n}}\n".format(GLOBAL_FUNCTION_DEFINITIONS = self.functionTypeDefinition), file=self.funcsFile)
		write("""\
/// if not using version "with-derelict-loader" this function must be called first
/// sets vkCreateInstance function pointer and acquires basic functions to retrieve information about the implementation
void loadGlobalLevelFunctions(typeof(vkGetInstanceProcAddr) getProcAddr) {
	vkGetInstanceProcAddr = getProcAddr;
	vkEnumerateInstanceExtensionProperties = cast(typeof(vkEnumerateInstanceExtensionProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceExtensionProperties");
	vkEnumerateInstanceLayerProperties = cast(typeof(vkEnumerateInstanceLayerProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceLayerProperties");
	vkCreateInstance = cast(typeof(vkCreateInstance)) vkGetInstanceProcAddr(null, "vkCreateInstance");
}

/// with a valid VkInstance call this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
void loadInstanceLevelFunctions(VkInstance instance) {
	assert(vkGetInstanceProcAddr !is null, "Must call loadGlobalLevelFunctions before loadInstanceLevelFunctions");\
"""
		+ self.instanceLevelFunctions
		+ """\
}

/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
void loadDeviceLevelFunctions(VkInstance instance) {
	assert(vkGetInstanceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions");\
"""
		+ self.deviceLevelFunctions.format(INSTANCE_OR_DEVICE = "Instance", instance_or_device = "instance")
		+ """\
}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
/// the functions call directly VkDevice and related resources and can be retrieved for one and only one VkDevice
/// otherwise a call to with to VkDevices would overwrite the __gshared functions of another previously called VkDevice
/// use createGroupedDeviceLevelFunctions bellow if usage of multiple VkDevices is required
void loadDeviceLevelFunctions(VkDevice device) {
	assert(vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions");\
"""
		+ self.deviceLevelFunctions.format(INSTANCE_OR_DEVICE = "Device", instance_or_device = "device")
		+ """\
}

/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions grouped in a DispatchDevice struct
/// the functions call directly VkDevice and related resources and can be retrieved for any VkDevice
DispatchDevice createDispatchDeviceLevelFunctions(VkDevice device) {
	assert(vkGetDeviceProcAddr !is null, "Must call loadInstanceLevelFunctions before loadDeviceLevelFunctions");
	
	DispatchDevice dispatchDevice;
	with(dispatchDevice) {\
"""
		+ self.deviceLevelFunctions.format(INSTANCE_OR_DEVICE = "Device", instance_or_device = "device").replace('\t\t', '\t\t\t')
		+ """\
	}}

	return dispatchDevice;
}}


// struct to group per device deviceLevelFunctions into a custom namespace
private struct DispatchDevice {{{DISPATCH_FUNCTION_DEFINITIONS}
}}

// Derelict loader to acquire entry point vkGetInstanceProcAddr
version({NAME_PREFIX}FromDerelict) {{
	import derelict.util.loader;
	import derelict.util.system;
	
	private {{
		version(Windows)
			enum libNames = "vulkan-1.dll";

		else version(Posix)
			enum libNames = "libvulkan.so";

		else
			static assert(0,"Need to implement Vulkan libNames for this operating system.");
	}}
	
	class Derelict{NAME_PREFIX}Loader : SharedLibLoader {{
		this() {{
			super(libNames);
		}}
		
		protected override void loadSymbols() {{
			typeof(vkGetInstanceProcAddr) getProcAddr;
			bindFunc(cast(void**)&getProcAddr, "vkGetInstanceProcAddr");
			loadGlobalLevelFunctions(getProcAddr);
		}}
	}}
	
	__gshared Derelict{NAME_PREFIX}Loader Derelict{NAME_PREFIX};

	shared static this() {{
		Derelict{NAME_PREFIX} = new Derelict{NAME_PREFIX}Loader();
	}}
}}

""".format(NAME_PREFIX = self.genOpts.namePrefix, DISPATCH_FUNCTION_DEFINITIONS = self.dispatchTypeDefinition), file=self.funcsFile)

		self.typesFile.close()
		self.funcsFile.close()

	def beginFeature(self, interface, emit):
		OutputGenerator.beginFeature(self, interface, emit)
		self.currentFeature = "// {0}".format(interface.attrib['name'])
		self.sections = dict([(section, []) for section in self.ALL_SECTIONS])
		self.opaqueStruct.clear()
		self.surfaceExtensionVersionIndent = ""
		self.isSurfaceExtension = self.currentFeature in self.surfaceExtensions
		if self.isSurfaceExtension:
			self.surfaceExtensionVersionIndent = "\t"

	def endFeature(self):
		if self.emit:
			# first write all types into types.d

			# special treat for platform surface extension which get wraped into a version block
			extIndent = self.surfaceExtensionVersionIndent
			self.typesFileContent += "\n{0}\n".format(self.currentFeature)
			surfaceVersion = ""
			if self.isSurfaceExtension:
				surfaceVersion = "version({0}) {{".format(self.surfaceExtensions[self.currentFeature][0])
				self.typesFileContent += "{0}\n\t{1}\n".format(surfaceVersion, self.surfaceExtensions[self.currentFeature][1])
			
			isFirstSectionInFeature = True		# for output file formating
			for section in self.TYPE_SECTIONS:
				# write contents of type section
				contents = self.sections[section]
				if contents:
					# check if opaque structs were registered and write tem into types file	
					if section == 'struct':
						if self.opaqueStruct:
							for opaque in self.opaqueStruct:
								self.typesFileContent += "{1}struct {0};\n".format(opaque, extIndent)
							self.typesFileContent += '\n'

					elif not isFirstSectionInFeature:
						self.typesFileContent += '\n'

					# for output file formating
					isFirstSectionInFeature = False

					# write the rest of the contents, eg. enums, structs, etc. into types file
					for content in self.sections[section]:
						self.typesFileContent += "{1}{0}\n".format(content, extIndent)

			if self.isSurfaceExtension:
				self.typesFileContent += "}\n"

			# currently the commandPointer token is not used
			if self.genOpts.genFuncPointers and self.sections['commandPointer']:
				if self.isSurfaceExtension: write(surfaceVersion, file=self.funcsFile)
				write(extIndent + ('\n' + extIndent).join(self.sections['commandPointer']), file=self.funcsFile)
				if self.isSurfaceExtension: write("}", file=self.funcsFile)
				write('', file=self.funcsFile)

			# write function aliases into functions.d and build strings for later injection
			if self.sections['command']:
				# update indention of currentFeature for functions.d content
				self.currentFeature = "\t" + self.currentFeature;

				# write the aliases to function types
				write("\n{0}".format(self.currentFeature), file=self.funcsFile)
				if self.isSurfaceExtension: write("\t" + surfaceVersion, file=self.funcsFile)
				write(extIndent + ('\n' + extIndent).join(self.sections['command']), file=self.funcsFile)
				if self.isSurfaceExtension: write("\t}", file=self.funcsFile)

				# capture if function is a instance or device level function
				inInstanceLevelFuncNames = False
				inDeviceLevelFuncNames = False

				# comment the current feature
				self.functionTypeDefinition += "\n\n{0}".format(self.currentFeature)

				# surface extension version directive
				if self.isSurfaceExtension: self.functionTypeDefinition += "\n\t" + surfaceVersion

				# create string of functionTypes functionVars
				for command in self.sections['command']:
					name = self.functionTypeName[command]
					self.functionTypeDefinition += "\n\t{1}PFN_{0} {0};".format(name, extIndent)

					# query if the current function is in instance or deviceLevelFuncNames for the next step
					if not inInstanceLevelFuncNames and name in self.instanceLevelFuncNames:
						inInstanceLevelFuncNames = True

					if not inDeviceLevelFuncNames and name in self.deviceLevelFuncNames:
						inDeviceLevelFuncNames = True

				# surface extension version closing curly brace
				if self.isSurfaceExtension: self.functionTypeDefinition += "\n\t}"

				# create a strings to load instance level functions
				if inInstanceLevelFuncNames:
					# comment the current feature
					self.instanceLevelFunctions += "\n\n{0}".format(self.currentFeature)

					# surface extension version directive
					if self.isSurfaceExtension: self.instanceLevelFunctions += "\n\t" + surfaceVersion
					
					# set of global level function names, function pointers are ignored here are set in endFile method
					gloablLevelFuncNames = {"vkGetInstanceProcAddr", "vkEnumerateInstanceExtensionProperties", "vkEnumerateInstanceLayerProperties", "vkCreateInstance"}

					# build the commands
					for command in self.sections['command']:
						name = self.functionTypeName[command]
						if name in self.instanceLevelFuncNames and name not in gloablLevelFuncNames:
							self.instanceLevelFunctions += "\n\t{1}{0} = cast(typeof({0})) vkGetInstanceProcAddr(instance, \"{0}\");".format(name, extIndent)

					# surface extension version closing curly brace
					if self.isSurfaceExtension: self.instanceLevelFunctions += "\n\t}"

				# create a strings to load device level functions
				if inDeviceLevelFuncNames:
					# comment the current feature
					self.deviceLevelFunctions += "\n\n{0}".format(self.currentFeature)

					# surface extension version directive
					if self.isSurfaceExtension: self.deviceLevelFunctions += "\n\t" + surfaceVersion

					# build the commands
					for command in self.sections['command']:
						name = self.functionTypeName[command]
						if name in self.deviceLevelFuncNames:
							self.deviceLevelFunctions += "\n\t{1}{0} = cast(typeof({0})) vkGet{{INSTANCE_OR_DEVICE}}ProcAddr({{instance_or_device}}, \"{0}\");".format(name, extIndent)

							# this function type definitions end up in the DispatchDevice struct
							self.dispatchTypeDefinition += "\n\t{1}PFN_{0} {0};".format(name, extIndent)
					
					# surface extension version closing curly brace
					if self.isSurfaceExtension: self.deviceLevelFunctions += "\n\t}"	

		# Finish processing in superclass
		OutputGenerator.endFeature(self)

	# Append a definition to the specified section
	def appendSection(self, section, text):
		self.sections[section].append(text)

	def genType(self, typeinfo, name):
		super().genType(typeinfo, name)
		if "requires" in typeinfo.elem.attrib:
			required = typeinfo.elem.attrib["requires"]
			if required.endswith(".h"):
				return
			elif required == "vk_platform":
				return

		category = typeinfo.elem.attrib["category"]

		if category == "handle":
			self.appendSection("handle", "mixin({0}!q{{{1}}});".format(typeinfo.elem.find("type").text, name))
			
		elif category == "basetype":
			self.appendSection("basetype", "alias {0} = {1};".format(name, typeinfo.elem.find("type").text))
			
		elif category == "bitmask":
			self.appendSection("bitmask", "alias {0} = VkFlags;".format(name))
			
		elif category == "funcpointer":
			returnType = re.match(re_funcptr, typeinfo.elem.text).group(1)
			params = "".join(islice(typeinfo.elem.itertext(), 2, None))[2:]
			if params == "void);" : params = ");"
			else: params = ' '.join(' '.join(line.strip() for line in params.splitlines()).split())
			self.appendSection("funcpointer", "alias {0} = {1} function({2}".format(name, returnType, params))
			
		elif category == "struct" or category == "union":
			self.genStruct(typeinfo, name)

		elif category == 'define' and name == 'VK_HEADER_VERSION':
			for headerVersion in islice(typeinfo.elem.itertext(), 2, 3):	# get the version string from the one element list
				self.headerVersion = "enum VK_HEADER_VERSION ={0};".format(headerVersion)

		else:
			pass
		
	def genStruct(self, typeinfo, name):
		super().genStruct(typeinfo, name)
		category = typeinfo.elem.attrib["category"]
		self.appendSection("struct", "\n{2}{0} {1} {{".format(category, name, self.surfaceExtensionVersionIndent))
		targetLen = 0
		memberTypeName = []

		for member in typeinfo.elem.findall("member"):
			memberType = convertTypeConst(getFullType(member, self.opaqueStruct).strip())
			memberName = member.find("name").text
			if memberName == "module":
				# don't use D identifiers
				memberName = "_module"
			
			# get tha maximum string length of all member types
			memberType, memberName = convertTypeArray(memberType, memberName)
			memberTypeName.append((memberType, memberName))
			targetLen = max(targetLen, len(memberType))

		# loop second time and use maximum type string length to offset member names
		isVkWin32SurfaceCreateInfoKHR = name == "VkWin32SurfaceCreateInfoKHR" # get this query out of the loop bellow
		for type_name in memberTypeName:
			memberType = type_name[0]
			memberName = type_name[1]
			if memberName == "sType" and memberType == "VkStructureType":
				if isVkWin32SurfaceCreateInfoKHR:	# the name transformation bellow does not work for this struct
					structType = "\t{0} sType = VkStructureType.VK_STRUCTURE_TYPE_{1};".format("VkStructureType".ljust(targetLen+1), "WIN32_SURFACE_CREATE_INFO_KHR")
					self.appendSection("struct", structType)
				else:
					enumName = re.sub(re_camel_case, "\g<1>_\g<2>", name[2:]).upper()
					structType = "\t{0}  sType = VkStructureType.VK_STRUCTURE_TYPE_{1};".format("VkStructureType".ljust(targetLen), enumName)
					self.appendSection("struct", structType)
				#write(name + " : " + enumName, file=self.testsFile)
			else:
				self.appendSection("struct", "\t{0}  {1};".format(memberType.ljust(targetLen), memberName))

		self.appendSection("struct", "}")

	
	def genGroup(self, groupinfo, groupName):
		super().genGroup(groupinfo, groupName)

		groupElem = groupinfo.elem

		expandName = re.sub(r'([0-9a-z_])([A-Z0-9][^A-Z0-9]?)', r'\1_\2', groupName).upper()

		expandPrefix = expandName
		expandSuffix = ''
		expandSuffixMatch = re.search(r'[A-Z][A-Z]+$', groupName)
		if expandSuffixMatch:
			expandSuffix = '_' + expandSuffixMatch.group()
			# Strip off the suffix from the prefix
			expandPrefix = expandName.rsplit(expandSuffix, 1)[0]

		# group enums by their name
		body = "\nenum " + groupName + " {\n"

		# add grouped enums to global scope
		globalEnums = "\n\n// " + groupName + " global enums\n"

		isEnum = ('FLAG_BITS' not in expandPrefix)

		# Loop over the nested 'enum' tags. Keep track of the minimum and
		# maximum numeric values, if they can be determined; but only for
		# core API enumerants, not extension enumerants. This is inferred
		# by looking for 'extends' attributes.
		minName = None
		for elem in groupElem.findall('enum'):
			# Convert the value to an integer and use that to track min/max.
			# Values of form -(number) are accepted but nothing more complex.
			# Should catch exceptions here for more complex constructs. Not yet.
			(numVal, strVal) = self.enumToValue(elem, True)
			name = elem.get('name')

			# Extension enumerants are only included if they are requested
			# in addExtensions or match defaultExtensions.
			if (elem.get('extname') is None or
				re.match(self.genOpts.addExtensions, elem.get('extname')) is not None or
				self.genOpts.defaultExtensions == elem.get('supported')):
				body += "\t" + name + " = " + strVal + ",\n"
				globalEnums += "enum {0} = {1}.{0};\n".format(name, groupName)

			if isEnum and elem.get('extends') is None:
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
			body += "\t" + expandPrefix + "_RANGE_SIZE"  + expandSuffix + " = (" + maxName + " - " + minName + " + 1),\n"

			globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};\n".format(expandPrefix, "_BEGIN_RANGE", expandSuffix, groupName)
			globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};\n".format(expandPrefix, "_END_RANGE"  , expandSuffix, groupName)
			globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};\n".format(expandPrefix, "_RANGE_SIZE" , expandSuffix, groupName)

		body += "\t" + expandPrefix + "_MAX_ENUM" + expandSuffix + " = 0x7FFFFFFF\n}"
		globalEnums += "enum {0}{1}{2} = {3}.{0}{1}{2};".format(expandPrefix, "_MAX_ENUM" , expandSuffix, groupName)

		if groupElem.get('type') == 'bitmask':
			self.appendSection('bitmask', body + globalEnums)
		else:
			self.appendSection('group', body + globalEnums)

	def genEnum(self, enuminfo, name):
		super().genEnum(enuminfo, name)
		_,strVal = self.enumToValue(enuminfo.elem, False)
		if strVal == "VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT":
			strVal = "VkStructureType." + strVal
		strVal = re.sub(re_long_int, "\g<1>UL", strVal)
		self.appendSection('enum', "enum {0} = {1};".format(name, strVal))
		
	def genCmd(self, cmdinfo, name):
		#if name not in {"vkGetInstanceProcAddr", "vkEnumerateInstanceExtensionProperties", "vkEnumerateInstanceLayerProperties", "vkCreateInstance"}:
		super().genCmd(cmdinfo, name)
		proto = cmdinfo.elem.find("proto")
		returnType = convertTypeConst(getFullType(proto).strip())
		params = ", ".join(convertTypeConst(getFullType(param, self.opaqueStruct).strip()) + " " + param.find("name").text for param in cmdinfo.elem.findall("param"))
		funTypeName = "\talias PFN_{0} = {1} function({2});".format(name, returnType, params)
		self.appendSection('command', funTypeName)
		self.functionTypeName[funTypeName] = name

		params = cmdinfo.elem.findall("param")
		if name != "vkGetDeviceProcAddr" and getFullType(params[0]) in {"VkDevice", "VkQueue", "VkCommandBuffer"}:
			self.deviceLevelFuncNames.add(name)

		else:
			self.instanceLevelFuncNames.add(name)


class DGeneratorOptions(GeneratorOptions):
	def __init__(self, *args, **kwargs):
		self.packagePrefix = kwargs.pop("packagePrefix")
		self.namePrefix = kwargs.pop("namePrefix")
		self.genFuncPointers = kwargs.pop("genFuncPointers")
		super().__init__(*args, **kwargs)

if __name__ == "__main__":
	import argparse

	vkxml = "vk.xml"
	parser = argparse.ArgumentParser()
	if len(sys.argv) > 2 and not sys.argv[2].startswith("--"):
		parser.add_argument("vulkandocs")
		vkxml = sys.argv[1] + "/src/spec/vk.xml"

	parser.add_argument("outfolder")
	parser.add_argument("--packagePrefix", default="erupted")
	parser.add_argument("--namePrefix", default="Erupted")
	
	args = parser.parse_args()
	
	gen = DGenerator()
	reg = Registry()
	reg.loadElementTree(etree.parse(vkxml))
	reg.setGenerator(gen)
	reg.apiGen(
		DGeneratorOptions(
		filename=args.outfolder,
		apiname="vulkan",
		versions=".*",
		emitversions=".*",
		packagePrefix=args.packagePrefix,
		namePrefix=args.namePrefix,
		genFuncPointers  = True,
		#defaultExtensions="defaultExtensions",
		addExtensions=r".*",
		#removeExtensions = None#r"VK_KHR_.*_surface$"
	))
	
