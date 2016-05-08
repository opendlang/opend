#!/usr/bin/env python3
"""
D Vulkan bindings generator, based off of and using the Vulkan-Docs code.

Place in Vulkan-Docs/src/spec/ and run to generate bindings.
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

PKG_HEADER = """
module PKGPREFIX;
public import PKGPREFIX.types;
public import PKGPREFIX.functions;
"""

TYPES_HEADER = """
module PKGPREFIX.types;

alias uint8_t = ubyte;
alias uint16_t = ushort;
alias uint32_t = uint;
alias uint64_t = ulong;
alias int8_t = byte;
alias int16_t = short;
alias int32_t = int;
alias int64_t = long;

@nogc pure nothrow {
	uint VK_MAKE_VERSION(uint major, uint minor, uint patch) {
		return (major << 22) | (minor << 12) | (patch);
	}
	uint VK_VERSION_MAJOR(uint ver) {
		return ver >> 22;
	}
	uint VK_VERSION_MINOR(uint ver) {
		return (ver >> 12) & 0x3ff;
	}
	uint VK_VERSION_PATCH(uint ver) {
		return ver & 0xfff;
	}
}

enum VK_NULL_HANDLE = 0;

enum VK_DEFINE_HANDLE(string name) = "struct "~name~"_handle; alias "~name~" = "~name~"_handle*;";

version(X86_64) {
	alias VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = VK_DEFINE_HANDLE!name;
} else {
	enum VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = "alias "~name~" = ulong;";
}
"""

DYNAMIC_HEADER = """
module PKGPREFIX.functions;

public import PKGPREFIX.types;

extern(System) @nogc nothrow {
"""

def getFullType(elem):
	typ = elem.find("type")
	typstr = (elem.text or "").lstrip() + typ.text.strip() + (typ.tail or "").rstrip()
	
	arrlen = elem.find("enum")
	if arrlen is not None:
		return "%s[%s]" % (typstr, arrlen.text)
	else:
		name = elem.find("name")
		return typstr + (name.tail or "")

def convertTypeConst(typ):
	"""
	Converts C const syntax to D const syntax
	"""
	doubleConstMatch = re.match(re_double_const, typ)
	if doubleConstMatch:
		return "const(%s*)*" % doubleConstMatch.group(1)
	else:
		singleConstMatch = re.match(re_single_const, typ)
		if singleConstMatch:
			return "const(%s)*" % singleConstMatch.group(1)
	return typ

def convertTypeArray(typ, name):
	arrMatch = re.match(re_array, name)
	if arrMatch:
		return "%s[%s]" % (typ, arrMatch.group(2)), arrMatch.group(1)
	else:
		return typ, name

class DGenerator(OutputGenerator):
	def __init__(self, errFile=sys.stderr, warnFile=sys.stderr, diagFile=sys.stderr):
		super().__init__(errFile, warnFile, diagFile)
		self.enumConstants = []
		self.deviceLevelFuncNames = []
		self.instanceLevelFuncNames = []

	def beginFile(self, genOpts):
		self.genOpts = genOpts
		try:
			os.mkdir(genOpts.filename)
		except FileExistsError:
			pass
		
		self.typesFile = open(path.join(genOpts.filename, "types.d"), "w", encoding="utf-8")
		self.dynamicFile = open(path.join(genOpts.filename, "functions.d"), "w", encoding="utf-8")
		
		with open(path.join(genOpts.filename, "package.d"), "w", encoding="utf-8") as pkgfile:
			print(PKG_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=pkgfile)
		
		print(TYPES_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=self.typesFile)
		print(DYNAMIC_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=self.dynamicFile)
	
	def endFile(self):
		print("}", file=self.dynamicFile)
		
		print("__gshared {", file=self.dynamicFile)
		for name in self.instanceLevelFuncNames:
			print("\tPFN_%s %s;" % (name, name), file=self.dynamicFile)

		for name in self.deviceLevelFuncNames:
			print("\tPFN_%s %s;" % (name, name), file=self.dynamicFile)
		print("""}

struct NAMEPREFIXLoader {
	@disable this();
	@disable this(this);

	/// if not using version "with-derelict-loader" this function must be called first
	/// otherwise call DVulkanDerelict.load()
	/// both methods yield basic functions to retrieve information about the implementation and
	/// function vkCreateInstance
	static void loadGlobalLevelFunctions(typeof(vkGetInstanceProcAddr) getProcAddr) {
		vkGetInstanceProcAddr = getProcAddr;
		vkEnumerateInstanceExtensionProperties = cast(typeof(vkEnumerateInstanceExtensionProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceExtensionProperties");
		vkEnumerateInstanceLayerProperties = cast(typeof(vkEnumerateInstanceLayerProperties)) vkGetInstanceProcAddr(null, "vkEnumerateInstanceLayerProperties");
		vkCreateInstance = cast(typeof(vkCreateInstance)) vkGetInstanceProcAddr(null, "vkCreateInstance");
	}

	/// with a valid VkInstancecall this function to retrieve additional VkInstance, VkPhysicalDevice, ... related functions
	static void loadInstanceLevelFunctions(VkInstance instance) {
		assert(vkGetInstanceProcAddr !is null, "Must call NAMEPREFIXLoader.loadGlobalLevelFunctions before NAMEPREFIXLoader.loadInstanceLevelFunctions");
""".replace("NAMEPREFIX", self.genOpts.nameprefix), file=self.dynamicFile)

		for name in {"vkGetInstanceProcAddr", "vkEnumerateInstanceExtensionProperties", "vkEnumerateInstanceLayerProperties", "vkCreateInstance"}:
			self.instanceLevelFuncNames.remove(name)

		for name in self.instanceLevelFuncNames:
			print("\t\t{0} = cast(typeof({0})) vkGetInstanceProcAddr(instance, \"{0}\");".format(name),
				  file=self.dynamicFile)

		print("""   }

	/// with a valid VkInstance call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
	/// the functions call indirectly through the VkInstance and will be internally dispatched by the implementation
	static void loadDeviceLevelFunctions(VkInstance instance) {
		assert(vkGetInstanceProcAddr !is null, "Must call NAMEPREFIXLoader.loadInstanceLevelFunctions before NAMEPREFIXLoader.loadDeviceLevelFunctions");
""".replace("NAMEPREFIX", self.genOpts.nameprefix), file=self.dynamicFile)
		
		for name in self.deviceLevelFuncNames:
			print("\t\t{0} = cast(typeof({0})) vkGetInstanceProcAddr(instance, \"{0}\");".format(name), file=self.dynamicFile)
		
		print("""   }

	/// with a valid VkDevice call this function to retrieve VkDevice, VkQueue and VkCommandBuffer related functions
	/// the functions call directly VkDevice and related resources and must be retrieved once per logical VkDevice
	static void loadDeviceLevelFunctions(VkDevice device) {
		assert(vkGetDeviceProcAddr !is null, "Must call NAMEPREFIXLoader.loadInstanceLevelFunctions before NAMEPREFIXLoader.loadDeviceLevelFunctions");
""", file=self.dynamicFile)
		
		for name in self.deviceLevelFuncNames:
			print("\t\t{0} = cast(typeof({0})) vkGetDeviceProcAddr(device, \"{0}\");".format(name), file=self.dynamicFile)
		
		
		print("""   }
}

version(NAMEPREFIXLoadFromDerelict) {
	import derelict.util.loader;
	import derelict.util.system;
	
	private {
		version(Windows)
			enum libNames = "vulkan-1.dll";
		else
			static assert(0,"Need to implement Vulkan libNames for this operating system.");
	}
	
	class NAMEPREFIXDerelictLoader : SharedLibLoader {
		this() {
			super(libNames);
		}
		
		protected override void loadSymbols() {
			typeof(vkGetInstanceProcAddr) getProcAddr;
			bindFunc(cast(void**)&getProcAddr, "vkGetInstanceProcAddr");
			NAMEPREFIXLoader.loadGlobalLevelFunctions(getProcAddr);
		}
	}
	
	__gshared NAMEPREFIXDerelictLoader NAMEPREFIXDerelict;

	shared static this() {
		NAMEPREFIXDerelict = new NAMEPREFIXDerelictLoader();
	}
}

""".replace("NAMEPREFIX", self.genOpts.nameprefix), file=self.dynamicFile)
		
		print("version(NAMEPREFIXGlobalEnums) {".replace("NAMEPREFIX", self.genOpts.nameprefix), file=self.typesFile)
		for enumName, enumField in self.enumConstants:
			print("\tenum %s = %s.%s;" % (enumField, enumName, enumField), file=self.typesFile)
		print("}", file=self.typesFile)
		
		self.typesFile.close()
		self.dynamicFile.close()
	
	def beginFeature(self, interface, emit):
		super().beginFeature(interface, emit)
	def endFeature(self):
		super().endFeature()
	
	def genType(self, typeinfo, name):
		super().genType(typeinfo, name)
		if "requires" in typeinfo.elem.attrib:
			required = typeinfo.elem.attrib["requires"]
			if required.endswith(".h"):
				return
			elif required == "vk_platform":
				return
		typ = typeinfo.elem.attrib["category"]
		if typ == "handle":
			print("mixin(%s!q{%s});" % (typeinfo.elem.find("type").text, name), file=self.typesFile)
		elif typ == "basetype":
			print("alias %s = %s;" % (name, typeinfo.elem.find("type").text), file=self.typesFile)
		elif typ == "bitmask":
			print("alias %s = VkFlags;" % name, file=self.typesFile)
		elif typ == "funcpointer":
			returnType = re.match(re_funcptr, typeinfo.elem.text).group(1)
			params = "".join(islice(typeinfo.elem.itertext(), 2, None))[2:]
			if params == "void);":
				params = ");"
			print("alias %s = %s function(%s" % (name, returnType, params), file=self.typesFile)
		elif typ == "struct" or typ == "union":
			self.genStruct(typeinfo, name)
		else:
			pass
		
	def genStruct(self, typeinfo, name):
		super().genStruct(typeinfo, name)
		category = typeinfo.elem.attrib["category"]
		print("%s %s {" % (category, name), file=self.typesFile)
		for member in typeinfo.elem.findall("member"):
			memberType = convertTypeConst(getFullType(member).strip())
			memberName = member.find("name").text
			if memberName == "module":
				# don't use D identifiers
				memberName = "_module"
			
			memberType, memberName = convertTypeArray(memberType, memberName)
			if memberName == "sType" and memberType == "VkStructureType":
				enumname = re.sub(re_camel_case, "\g<1>_\g<2>", name[2:]).upper()
				print("\tVkStructureType sType = VkStructureType.VK_STRUCTURE_TYPE_"+enumname+";", file=self.typesFile)
			else:
				print("\t%s %s;" % (memberType, memberName), file=self.typesFile)
		print("}", file=self.typesFile)
	
	def genGroup(self, groupinfo, name):
		super().genGroup(groupinfo, name)
		print("enum %s {" % name, file=self.typesFile)
		
		expand = "expand" in groupinfo.elem.attrib
		
		minName = None
		maxName = None
		minValue = float("+inf")
		maxValue = float("-inf")
		for elem in groupinfo.elem.findall("enum"):
			(numval, strval) = self.enumToValue(elem, True)
			fieldName = elem.get("name")
			print("\t%s = %s," % (fieldName, strval), file=self.typesFile)
			self.enumConstants.append((name, fieldName))
			
			if expand:
				if numval < minValue:
					minName = fieldName
					minValue = numval
				if numval > maxValue:
					maxName = fieldName
					maxValue = numval
		
		if expand:
			prefix = groupinfo.elem.attrib["expand"]
			print("\t%s_BEGIN_RANGE = %s," % (prefix, minName), file=self.typesFile)
			print("\t%s_END_RANGE = %s," % (prefix, maxName), file=self.typesFile)
			print("\t%s_RANGE_SIZE = (%s - %s + 1)," % (prefix, maxName, minName), file=self.typesFile)
			print("\t%s_MAX_ENUM = 0x7FFFFFFF," % prefix, file=self.typesFile)
			self.enumConstants.append((name, prefix+"_BEGIN_RANGE"))
			self.enumConstants.append((name, prefix+"_END_RANGE"))
			self.enumConstants.append((name, prefix+"_RANGE_SIZE"))
			self.enumConstants.append((name, prefix+"_MAX_ENUM"))
		print("}", file=self.typesFile)
	
	def genEnum(self, enuminfo, name):
		super().genEnum(enuminfo, name)
		_,strVal = self.enumToValue(enuminfo.elem, False)
		if strVal == "VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT":
			strVal = "VkStructureType."+strVal
		strVal = re.sub(re_long_int, "\g<1>UL", strVal)
		print("enum %s = %s;" % (name, strVal), file=self.typesFile)
		
	def genCmd(self, cmd, name):
		super().genCmd(cmd, name)
		
		proto = cmd.elem.find("proto")
		returnType = convertTypeConst(getFullType(proto).strip())
		params = ",".join(convertTypeConst(getFullType(param).strip())+" "+param.find("name").text for param in cmd.elem.findall("param"))
		print("\talias PFN_%s = %s function(%s);" % (name, returnType, params), file=self.dynamicFile)

		"""
		print("\talias PFN_%s = %s function(%s);" % (name, returnType, params))
		params = cmd.elem.findall("param")
		print(name)
		for param in params:
			print("  " + getFullType(param))
		"""

		params = cmd.elem.findall("param")
		if name != "vkGetDeviceProcAddr" and getFullType(params[0]) in {"VkDevice", "VkQueue", "VkCommandBuffer"}:
			self.deviceLevelFuncNames.append(name)

		else:
			self.instanceLevelFuncNames.append(name)




class DGeneratorOptions(GeneratorOptions):
	def __init__(self, *args, **kwargs):
		self.pkgprefix = kwargs.pop("pkgprefix")
		self.nameprefix = kwargs.pop("nameprefix")
		super().__init__(*args, **kwargs)

if __name__ == "__main__":
	import argparse

	vkxml = "vk.xml"
	parser = argparse.ArgumentParser()
	if len(sys.argv) > 2 and not sys.argv[2].startswith("--"):
		parser.add_argument("vulkandocs")
		vkxml = sys.argv[1] + "/src/spec/vk.xml"

	parser.add_argument("outfolder")
	parser.add_argument("--pkgprefix", default="dvulkan")
	parser.add_argument("--nameprefix", default="DVulkan")
	
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
		pkgprefix=args.pkgprefix,
		nameprefix=args.nameprefix,
		#defaultExtensions="defaultExtensions",
		addExtensions=r".*",
		removeExtensions = r"VK_KHR_.*_surface$",
	))
	
