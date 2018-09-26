project('mir-cpuid', 'd', version : '0.5.4', license: 'BSL-1.0')

mir_cpuid_dir = include_directories('source/')

mir_cpuid_src = [
    'source/cpuid/amd.d',
    'source/cpuid/common.d',
    'source/cpuid/intel.d',
    'source/cpuid/unified.d',
    'source/cpuid/x86_any.d',
]

mir_cpuid_lib = library(meson.project_name(),
    mir_cpuid_src,
    include_directories: mir_cpuid_dir,
    install: true,
    version: meson.project_version(),
)

mir_cpuid_dep = declare_dependency(
    link_with: [mir_cpuid_lib],
    include_directories: mir_cpuid_dir,
)

mir_cpuid_test_exe = executable(meson.project_name() + '-test',
    mir_cpuid_src,
    include_directories: mir_cpuid_dir,
    d_unittest: true,
    d_module_versions: ['mir_test'],
    link_args: '-main',
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(
    name: meson.project_name(),
    description: 'Mir CPUID - BetterC CPU Identification Routines.',
    subdirs: 'd/' + meson.project_name(),
    libraries: [mir_cpuid_lib],
    version: meson.project_version(),
)

test(meson.project_name() + '-test', mir_cpuid_test_exe)
