project('mir-optim', 'd', 'c', version : '1.0.0', license: 'BSL-1.0')

cblas_d_dep = dependency('cblas-d', fallback : ['cblas', 'cblas_dep'])
lapack_d_dep = dependency('lapack-d', fallback : ['lapack', 'lapack_dep'])
mir_algorithm_dep = dependency('mir-algorithm', fallback : ['mir-algorithm', 'mir_algorithm_dep'])
mir_blas_dep = dependency('mir-blas', fallback : ['mir-blas', 'mir_blas_dep'])
mir_core_dep = dependency('mir-core', fallback : ['mir-core', 'mir_core_dep'])
mir_lapack_dep = dependency('mir-lapack', fallback : ['mir-lapack', 'mir_lapack_dep'])
mir_random_dep = dependency('mir-random', fallback : ['mir-random', 'mir_random_dep'])

required_deps = [
    cblas_d_dep,
    lapack_d_dep,
    mir_algorithm_dep,
    mir_blas_dep,
    mir_core_dep,
    mir_lapack_dep,
    mir_random_dep,
]

if target_machine.system() == 'linux'
    mir_linux_kernel_dep = dependency('mir-linux-kernel', fallback : ['mir-linux-kernel', 'mir_linux_kernel_dep'])
    required_deps = [required_deps, mir_linux_kernel_dep]
endif

mir_optim_dir = include_directories('source/', 'include/')

mir_optim_src = [
    'source/mir/optim/least_squares.d',
]

mir_optim_lib = library(meson.project_name(),
    mir_optim_src,
    include_directories: mir_optim_dir,
    install: true,
    version: meson.project_version(),
    dependencies: required_deps,
)

mir_optim_dep = declare_dependency(
    link_with: [mir_optim_lib],
    include_directories: mir_optim_dir,
    dependencies: required_deps,
)

install_subdir('include/',
    strip_directory :true,
    install_dir: 'include/',
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(mir_optim_lib,
    description: 'Optimisation Framework',
    subdirs: 'd/' + meson.project_name(),
)

if get_option('with_test')

    mir_optim_test_exe = executable(meson.project_name() + '-test',
        mir_optim_src,
        include_directories: mir_optim_dir,
        d_unittest: true,
        d_module_versions: ['mir_test'],
        link_args: '-main',
        dependencies: required_deps,
    )

    test(meson.project_name() + '-test', mir_optim_test_exe)

endif
