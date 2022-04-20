project('mir-stat', 'd', version : '0.0.10', license: 'BSL-1.0')

description = 'Dlang Statistical Package'

subprojects = ['mir-core', 'mir-algorithm']

has_cpp_headers = false

sources_list = [
    'mir/math/internal/powi',
    'mir/stat/descriptive',
    'mir/stat/package',
    'mir/stat/transform',
    'mir/stat/distribution/package',
    'mir/stat/distribution/cdf',
    'mir/stat/distribution/pdf',
    'mir/stat/distribution/invcdf',
    'mir/stat/distribution/normal',
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

test_versions = ['mir_stat_test']

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

test_subdirs = []
