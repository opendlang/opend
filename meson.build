project('mir-cpuid', 'd', version: '1.2.3', license: 'BSL-1.0')

description = 'Mir CPUID - CPU Information'

subprojects = ['mir-core']

has_cpp_headers = false

sources_list = [
    'cpuid/amd',
    'cpuid/common',
    'cpuid/intel',
    'cpuid/unified',
    'cpuid/x86_any',
]

sources = []
foreach s : sources_list
    sources += 'source/' + s + '.d'
endforeach

add_project_arguments([
    '-preview=dip1008',
    '-lowmem',
], language: 'd')

required_deps = []

foreach p : subprojects 
    required_deps += dependency(p, fallback : [p, p.underscorify() + '_dep'])
endforeach

directories = ['source']

if has_cpp_headers
    directories += 'include'
endif

directories = include_directories(directories)

this_lib = library(meson.project_name(),
    sources,
    include_directories: directories,
    install: true,
    version: meson.project_version(),
    dependencies: required_deps,
)

this_dep = declare_dependency(
    link_with: [this_lib],
    include_directories: directories,
    dependencies: required_deps,
)

test_versions = []

if has_cpp_headers
    install_subdir('include/',
        strip_directory :true,
        install_dir: 'include/',
    )
endif

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(this_lib,
    description: description,
    subdirs: 'd/' + meson.project_name(),
)

mir_cpuid_dep = this_dep
mir_cpuid_lib = this_lib

test_subdirs = []
