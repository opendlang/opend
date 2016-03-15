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

try:
	from reg import *
	from generator import OutputGenerator, GeneratorOptions, write
except ImportError as e:
	print("Could not import Vulkan generator; ensure that this file is in Vulkan-Docs/src/spec", file=sys.stderr)
	print("-----", file=sys.stderr)
	raise

PKG_HEADER = """
module PKGPREFIX;
public import PKGPREFIX.types;
version(NAMEPREFIXStatic)
	public import PKGPREFIX.statfun;
else
	public import PKGPREFIX.dynload;
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

enum VK_NULL_HANDLE = 0;

enum VK_DEFINE_HANDLE(string name) = "struct "~name~"_handle; alias "~name~" = "~name~"_handle*;";

version(X86_64) {
	alias VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = VK_DEFINE_HANDLE!name;
} else {
	enum VK_DEFINE_NON_DISPATCHABLE_HANDLE(string name) = "alias "~name~" = ulong;";
}
"""

STATIC_HEADER = """
module PKGPREFIX.statfun;
public import PKGPREFIX.types;

version(NAMEPREFIXStatic):
public import PKGPREFIX.types;

extern(System) @nogc nothrow {
"""

DYNAMIC_HEADER = """
module PKGPREFIX.dynload;

version(NAMEPREFIXVulkanStatic) {}
else { version = NAMEPREFIXDynamic; }

version(NAMEPREFIXDynamic):

public import PKGPREFIX.types;
import derelict.util.loader;
import derelict.util.system;

private {
	version(Windows)
		enum libNames = "vulkan-1.dll";
	else version(Mac)
		enum libNames = "";
	else version(Posix)
		enum libNames = "";
	else
		static assert(0,"Need to implement Vulkan libNames for this operating system.");
}

extern(System) @nogc nothrow {
"""

def getFullType(elem):
	typ = elem.find("type")
	typstr = (elem.text or "").lstrip() + \
		typ.text.strip() + (typ.tail or "").rstrip()
	
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
	
	def beginFile(self, genOpts):
		self.genOpts = genOpts
		try:
			os.mkdir(genOpts.filename)
		except FileExistsError:
			pass
		
		self.typesFile = open(path.join(genOpts.filename, "types.d"), "w", encoding="utf-8")
		self.dynamicFile = open(path.join(genOpts.filename, "dynload.d"), "w", encoding="utf-8")
		self.staticFile = open(path.join(genOpts.filename, "statfun.d"), "w", encoding="utf-8")
		
		with open(path.join(genOpts.filename, "package.d"), "w", encoding="utf-8") as pkgfile:
			print(PKG_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=pkgfile)
		
		print(TYPES_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=self.typesFile)
		print(STATIC_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=self.staticFile)
		print(DYNAMIC_HEADER.replace("PKGPREFIX", genOpts.pkgprefix).replace("NAMEPREFIX", genOpts.nameprefix), file=self.dynamicFile)
		self.funcNames = []
	
	def endFile(self):
		print("}", file=self.staticFile)
		print("}", file=self.dynamicFile)
		
		print("__gshared {", file=self.dynamicFile)
		for name in self.funcNames:
			print("\tPFN_%s %s;" % (name, name), file=self.dynamicFile)
		print("""}

class NAMEPREFIXLoader : SharedLibLoader {
	public this() {
		super(libNames);
	}
	
	protected override void loadSymbols() {
""".replace("NAMEPREFIX", self.genOpts.nameprefix), file=self.dynamicFile)
		for name in self.funcNames:
			print("\t\tbindFunc(cast(void**)&%s,\"%s\");" % (name, name), file=self.dynamicFile)
		print("""	}
}

__gshared NAMEPREFIXLoader NAMEPREFIX;

shared static this() {
	NAMEPREFIX = new NAMEPREFIXLoader();
}
""".replace("NAMEPREFIX", self.genOpts.nameprefix), file=self.dynamicFile)
		
		
		self.typesFile.close()
		self.dynamicFile.close()
		self.staticFile.close()
	
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
			name = elem.get("name")
			print("\t%s = %s," % (name, strval), file=self.typesFile)
			
			if expand:
				if numval < minValue:
					minName = name
					minValue = numval
				if numval > maxValue:
					maxName = name
					maxValue = numval
		
		if expand:
			prefix = groupinfo.elem.attrib["expand"]
			print("\t%s_BEGIN_RANGE = %s," % (prefix, minName), file=self.typesFile)
			print("\t%s_END_RANGE = %s," % (prefix, maxName), file=self.typesFile)
			print("\t%s_RANGE_SIZE = (%s - %s + 1)," % (prefix, maxName, minName), file=self.typesFile)
			print("\t%s_MAX_ENUM = 0x7FFFFFFF," % prefix, file=self.typesFile)
		print("}", file=self.typesFile)
	
	def genEnum(self, enuminfo, name):
		super().genEnum(enuminfo, name)
		(numVal,strVal) = self.enumToValue(enuminfo.elem, False)
		print("enum %s = %s;" % (name, strVal.replace("ULL", "UL")), file=self.typesFile)
		
	def genCmd(self, cmd, name):
		super().genCmd(cmd, name)
		
		proto = cmd.elem.find("proto")
		returnType = convertTypeConst(getFullType(proto).strip())
		params = ",".join(convertTypeConst(getFullType(param).strip())+" "+param.find("name").text for param in cmd.elem.findall("param"))
		print("\t%s %s(%s);" % (returnType, name, params), file=self.staticFile)
		print("\talias PFN_%s = %s function(%s);" % (name, returnType, params), file=self.dynamicFile)
		self.funcNames.append(name)

class DGeneratorOptions(GeneratorOptions):
	def __init__(self, *args, **kwargs):
		self.pkgprefix = kwargs.pop("pkgprefix")
		self.nameprefix = kwargs.pop("nameprefix")
		super().__init__(*args, **kwargs)

if __name__ == "__main__":
	import argparse
	
	parser = argparse.ArgumentParser()
	parser.add_argument("outfolder")
	parser.add_argument("--pkgprefix", default="dvulkan")
	parser.add_argument("--nameprefix", default="DVulkan")
	
	args = parser.parse_args()
	
	gen = DGenerator()
	reg = Registry()
	reg.loadElementTree(etree.parse("vk.xml"))
	reg.setGenerator(gen)
	reg.apiGen(DGeneratorOptions(
		filename=args.outfolder,
		apiname="vulkan",
		versions=".*",
		emitversions=".*",
		pkgprefix=args.pkgprefix,
		nameprefix=args.nameprefix,
	))
	
