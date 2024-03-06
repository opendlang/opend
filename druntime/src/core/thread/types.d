/**
 * This module provides types and constants used in thread package.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly, Walter Bright, Alex Rønne Petersen, Martin Nowak
 * Source:    $(DRUNTIMESRC core/thread/osthread.d)
 */

module core.thread.types;

import rt.sys.config;

mixin("public import " ~ osThreadImport ~ " : ThreadID;");

struct ll_ThreadData
{
    ThreadID tid;
    version (Windows)
        void delegate() nothrow cbDllUnload;
}

version (GNU)
{
    version (GNU_StackGrowsDown)
        enum isStackGrowingDown = true;
    else
        enum isStackGrowingDown = false;
}
else version (LDC)
{
    // The only LLVM targets as of LLVM 16 with stack growing *upwards* are
    // apparently NVPTX and AMDGPU, both without druntime support.
    // Note that there's an analogous `version = StackGrowsDown` in
    // core.thread.fiber.
    enum isStackGrowingDown = true;
}
else
{
    version (X86) enum isStackGrowingDown = true;
    else version (X86_64) enum isStackGrowingDown = true;
    else static assert(0, "It is undefined how the stack grows on this architecture.");
}

alias callWithStackShellDg = void delegate(void* sp) nothrow;
