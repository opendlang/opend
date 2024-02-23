project('mir-lapack', 'd', 'c', version: '1.2.5', license: 'BSL-1.0')

description = 'Mir LAPACK - ndslice wrapper for LAPACK'

cc = meson.get_compiler('c')
lapack_deps = []
if not cc.find_library('openblas', required : false).found()
    lapack_deps = [cc.find_library('lapack')]
endif

subprojects = ['cblas-d', 'lapack-d', 'mir-core', 'mir-algorithm', 'mir-blas']

has_cpp_headers = false

sources_list = [
    'mir/lapack',
]

sources = []
foreach s : sources_list
    sources += 'source/' + s + '.d'
endforeach

add_project_arguments([
    '-preview=dip1008',
    '-lowmem',
], language: 'd')

required_deps = lapack_deps

foreach p : subprojects 
    required_deps += dependency(p, fallback : [p, 'this_dep'])
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

mir_lapack_dep = this_dep
mir_lapack_lib = this_lib

test_subdirs = ['examples/gesv']
