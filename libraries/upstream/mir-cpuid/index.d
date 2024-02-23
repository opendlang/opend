Ddoc

$(H1 CPU Identification)

$(P The following table is a quick reference guide for which cpuid modules to
use for a given category of functionality.)

$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(LEADINGROW High Level API)
    $(TR
        $(TDNW $(LINK2 cpuid_unified.html, cpuid.unified))
        $(TD High level abstraction on top of all architectures)
    )
    $(TR
        $(TDNW $(LINK2 cpuid_x86_any.html, cpuid.x86_any))
        $(TD Common information for all x86 and x86_64 vendors)
    )
    $(LEADINGROW Low Level API)
    $(TR
        $(TDNW $(LINK2 cpuid_intel.html, cpuid.intel))
        $(TD Intel 64 and IA-32 CPUID information)
    )
    $(TR
        $(TDNW $(LINK2 cpuid_amd.html, cpuid.amd))
        $(TD AMD CPUID information)
    )
    $(LEADINGROW Auxiliary)
    $(TR
        $(TDNW $(LINK2 cpuid_common.html, cpuid.common))
        $(TD Auxiliary data types and functions)
    )
)

Macros:
        TITLE=CPUID
        DDOC_BLANKLINE=
        _=
