project('lapack', 'd', version : '0.4.1', license: 'BSL-1.0')

description = 'LAPACK header'

subprojects = ['mir-core']

sources_list = [
    'lapack/lapack'
    'lapack/package'
]

sources = []
foreach s : sources_list
    sources += 'source/' + s + '.d'
endforeach

required_deps = []

foreach p : subprojects 
    required_deps += dependency(p, fallback : [p, 'this_dep'])
endforeach

directories = ['source']

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

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

test_versions = []

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(this_lib,
    description: description,
    subdirs: 'd/' + meson.project_name(),
)

lapack_dep = this_dep
