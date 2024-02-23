project('mir-random', 'd', version : '2.2.9', license: 'BSL-1.0')

description = 'Mir Random - Advanced Random Number Generators'

subprojects = ['mir-core']

if target_machine.system() == 'linux'
    subprojects += 'mir-linux-kernel'
endif

if get_option('extended')
    subprojects += 'mir-algorithm'
endif

has_cpp_headers = false

sources_list = [
    'mir/random/engine/linear_congruential',
    'mir/random/engine/mersenne_twister',
    'mir/random/engine/package',
    'mir/random/engine/pcg',
    'mir/random/engine/splitmix',
    'mir/random/engine/xorshift',
    'mir/random/engine/xoshiro',
    'mir/random/ndvariable',
    'mir/random/package',
    'mir/random/variable',
]

if get_option('extended')
    sources_list += [
        'mir/random/algorithm',
        'mir/random/flex/internal/area',
        'mir/random/flex/internal/calc',
        'mir/random/flex/internal/transformations',
        'mir/random/flex/internal/types',
        'mir/random/flex/package',
    ]
endif

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

test_versions = ['mir_random_test']

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

mir_random_dep = this_dep
mir_random_lib = this_lib

test_subdirs = []
