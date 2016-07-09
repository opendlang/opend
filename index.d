Ddoc

$(P CPU Identification subroutines )

$(P The following table is a quick reference guide for which cpuid modules to
use for a given category of functionality.)

$(BOOKTABLE ,
    $(TR
        $(TH Modules)
        $(TH Description)
    )
    $(LEADINGROW Sparse)
    $(TR
        $(TDNW $(LINK2 cpuid_amd.html, cpuid.amd))
        $(TD AMD CPUID Specification)
    )
    $(TR
        $(TDNW $(LINK2 cpuid_intel.html, cpuid.intel))
        $(TD Intel 64 and IA-32 CPUID Information)
    )
    $(TR
        $(TDNW $(LINK2 cpuid_x86_any.html, cpuid.x86_any))
        $(TD Common information for all x86 and x86_64 vendors)
    )
)

Macros:
        TITLE=CPUID
        DDOC_BLANKLINE=
        _=
