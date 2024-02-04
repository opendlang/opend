project('mir-core', 'd', version : '1.1.1', license: 'Apache-2.0')

description = 'Mir Core - Base software building blocks and conventions'

subprojects = []

has_cpp_headers = false

dc = meson.get_compiler('d')

sources_list = [
    'mir/algebraic',
    'mir/bitmanip',
    'mir/bitop',
    'mir/checkedint',
    'mir/complex/math',
    'mir/complex/package',
    'mir/conv',
    'mir/enums',
    'mir/exception',
    'mir/functional',
    'mir/internal/memory',
    'mir/internal/meta',
    'mir/internal/utility',
    'mir/math/common',
    'mir/math/constant',
    'mir/math/ieee',
    'mir/math/package',
    'mir/primitives',
    'mir/qualifier',
    'mir/reflection',
    'mir/string_table',
    'mir/utility',
]

sources = []
foreach s : sources_list
    sources += 'source/' + s + '.d'
endforeach

if dc.get_id() == 'gcc'
    add_project_arguments([
        '-fpreview=dip1008',
    ], language: 'd')
else
    add_project_arguments([
        '-preview=dip1008',
        '-lowmem',
    ], language: 'd')
endif

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

test_versions = ['mir_core_test']

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

mir_core_dep = this_dep
mir_core_lib = this_lib

test_subdirs = []
