project('mir-random', 'd', version : '2.2.0', license: 'BSL-1.0')

mir_core_dep = dependency('mir-core', fallback : ['mir-core', 'mir_core_dep'])

required_deps = [mir_core_dep]

if target_machine.system() == 'linux'
    mir_linux_kernel_dep = dependency('mir-linux-kernel', fallback : ['mir-linux-kernel', 'mir_linux_kernel_dep'])
    required_deps = [required_deps, mir_linux_kernel_dep]
endif

mir_random_dir = include_directories('source/')

mir_random_src = [
    'source/mir/random/engine/linear_congruential.d',
    'source/mir/random/engine/mersenne_twister.d',
    'source/mir/random/engine/package.d',
    'source/mir/random/engine/pcg.d',
    'source/mir/random/engine/splitmix.d',
    'source/mir/random/engine/xorshift.d',
    'source/mir/random/engine/xoshiro.d',
    'source/mir/random/ndvariable.d',
    'source/mir/random/package.d',
    'source/mir/random/variable.d',
]

if get_option('extended')
    mir_algorithm_dep = dependency('mir-algorithm', fallback : ['mir-algorithm', 'mir_algorithm_dep'])
    required_deps = [required_deps, mir_algorithm_dep]
    mir_random_src = [
        mir_random_src,
        'source/mir/random/algorithm.d',
        'source/mir/random/flex/internal/area.d',
        'source/mir/random/flex/internal/calc.d',
        'source/mir/random/flex/internal/transformations.d',
        'source/mir/random/flex/internal/types.d',
        'source/mir/random/flex/package.d',
    ]
endif

mir_random_lib = library(meson.project_name(),
    mir_random_src,
    include_directories: mir_random_dir,
    install: true,
    version: meson.project_version(),
    dependencies: required_deps,
)

mir_random_dep = declare_dependency(
    link_with: [mir_random_lib],
    include_directories: mir_random_dir,
    dependencies: required_deps,
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(mir_random_lib,
    description: 'ndslice API for random.',
    subdirs: 'd/' + meson.project_name(),
)

if get_option('with_test')

    mir_random_test_exe = executable(meson.project_name() + '-test',
        mir_random_src,
        include_directories: mir_random_dir,
        d_unittest: true,
        d_module_versions: ['mir_random_test'],
        link_args: '-main',
        dependencies: required_deps,
    )

    test(meson.project_name() + '-test', mir_random_test_exe)

endif
