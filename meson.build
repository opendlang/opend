project('mir-ion', 'd', version : '0.0.0', license: 'BSL-1.0')

description = 'Mir Ion - Ion/Json Serialization library'

subprojects = ['mir-core', 'mir-algorithm', 'mir-cpuid']

if (target_machine.cpu_family() == 'x86' or target_machine.cpu_family() == 'x86_64')
    subprojects += 'mir-cpuid'
endif

has_cpp_headers = false

sources_list = [
    'mir/ion/conv',
    'mir/ion/deser/text/readers',
    'mir/ion/deser/text/skippers',
    'mir/ion/deser/text/tokenizer',
    'mir/ion/deser/text/tokens',
    'mir/ion/deser/json',
    'mir/ion/deser/low_level',
    'mir/ion/deser/package',
    'mir/ion/exception',
    'mir/ion/internal/data_holder',
    'mir/ion/internal/simd',
    'mir/ion/internal/stage1',
    'mir/ion/internal/stage2',
    'mir/ion/internal/stage3',
    'mir/ion/internal/stage4_s',
    'mir/ion/lob',
    'mir/ion/ser/json',
    'mir/ion/ser/package',
    'mir/ion/symbol_table',
    'mir/ion/tape',
    'mir/timestamp',
    'mir/ion/type_code',
    'mir/ion/value',
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

test_versions = ['mir_ion_test']

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

if get_option('with_test_explicit')

    test_exe = executable(meson.project_name() + '-test',
        sources,
        include_directories: directories,
        d_unittest: true,
        d_module_versions: test_versions,
        link_args: '-main',
        dependencies: required_deps,
    )

    test(meson.project_name() + '-test', test_exe)

    foreach dir : test_subdirs
        subdir(dir)
    endforeach
endif
