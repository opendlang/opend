/**
 *
 * Copyright: Copyright Digital Mars 2000 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Walter Bright, Sean Kelly, Martin Nowak
 * Source: $(DRUNTIMESRC rt/_sections.d)
 */

module rt.sections;

version (LDC)
    public import rt.sections_ldc;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (CRuntime_Glibc)
    public import rt.sections_elf_shared;
else version (CRuntime_Musl)
    public import rt.sections_elf_shared;
else version (FreeBSD)
    public import rt.sections_elf_shared;
else version (NetBSD)
    public import rt.sections_elf_shared;
else version (OpenBSD)
{
    /**
     * OpenBSD is missing support needed for elf_shared.
     * See the top of sections_solaris.d for more info.
     */

    public import rt.sections_solaris;
}
else version (DragonFlyBSD)
    public import rt.sections_elf_shared;
else version (Solaris)
    public import rt.sections_solaris;
else version (Darwin)
{
    version (LDC)
        public import rt.sections_elf_shared;
    else version (X86_64)
        public import rt.sections_osx_x86_64;
    else version (X86)
        public import rt.sections_osx_x86;
    else
        static assert(0, "unimplemented");
}
else version (CRuntime_DigitalMars)
    public import rt.sections_win32;
else version (CRuntime_Microsoft)
{
    version (LDC)
        public import rt.sections_elf_shared;
    else
        public import rt.sections_win64;
}
else version (CRuntime_Bionic)
    public import rt.sections_android;
else version (CRuntime_UClibc)
    public import rt.sections_elf_shared;
else version (FreeStanding)
{
    import core.internal.container.array;
    void initSections() nothrow @nogc {}
    void finiSections() nothrow @nogc {}
    Array!(void[])* initTLSRanges() nothrow @nogc { return null; }
    void finiTLSRanges(Array!(void[])*) nothrow @nogc {}
    void scanTLSRanges(Array!(void[])*, scope void delegate(void* pstart, void* pend) nothrow dg) nothrow {}

    //struct FuncTable {}
    struct SectionGroup {
    	static int opApply(int delegate(ref SectionGroup sg)) {
		return 0;
	}
    	static int opApplyReverse(int delegate(ref SectionGroup sg)) {
		return 0;
	}
	immutable(ModuleInfo*)[] modules;
	ModuleGroup moduleGroup;
	//immutable(FuncTable)[] ehTables;
	void[][] gcRanges;
    }
}
else
    static assert(0, "unimplemented");

import rt.deh, rt.minfo;

template isSectionGroup(T)
{
    enum isSectionGroup =
        is(typeof(T.init.modules) == immutable(ModuleInfo*)[]) &&
        is(typeof(T.init.moduleGroup) == ModuleGroup) &&
        (!is(typeof(T.init.ehTables)) || is(typeof(T.init.ehTables) == immutable(FuncTable)[])) &&
        is(typeof(T.init.gcRanges) == void[][]) &&
        is(typeof({ foreach (ref T; T) {}})) &&
        is(typeof({ foreach_reverse (ref T; T) {}}));
}
static assert(isSectionGroup!(SectionGroup));
static assert(is(typeof(&initSections) == void function() nothrow @nogc));
static assert(is(typeof(&finiSections) == void function() nothrow @nogc));
static assert(is(typeof(&initTLSRanges) RT == return) &&
              is(typeof(&initTLSRanges) == RT function() nothrow @nogc) &&
              is(typeof(&finiTLSRanges) == void function(RT) nothrow @nogc) &&
              is(typeof(&scanTLSRanges) == void function(RT, scope void delegate(void*, void*) nothrow) nothrow));

version (Shared)
{
    static assert(is(typeof(&pinLoadedLibraries) == void* function() nothrow @nogc));
    static assert(is(typeof(&unpinLoadedLibraries) == void function(void*) nothrow @nogc));
    static assert(is(typeof(&inheritLoadedLibraries) == void function(void*) nothrow @nogc));
    static assert(is(typeof(&cleanupLoadedLibraries) == void function() nothrow @nogc));
}

bool scanDataSegPrecisely() nothrow @nogc @system
{
    import rt.config;
    string opt = rt_configOption("scanDataSeg");
    switch (opt)
    {
        case "":
        case "conservative":
            return false;
        case "precise":
            return true;
        default:
            __gshared err = new Error("DRT invalid scanDataSeg option, must be 'precise' or 'conservative'");
            throw err;
    }
}
