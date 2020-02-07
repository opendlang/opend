project('mir-integral', 'd', 'c', version : '1.0.0', license: 'BSL-1.0')

cblas_d_dep = dependency('cblas-d', fallback : ['cblas', 'cblas_dep'])
lapack_d_dep = dependency('lapack-d', fallback : ['lapack', 'lapack_dep'])
mir_lapack_dep = dependency('mir-lapack', fallback : ['mir-lapack', 'mir_lapack_dep'])
mir_algorithm_dep = dependency('mir-algorithm', fallback : ['mir-algorithm', 'mir_algorithm_dep'])
mir_blas_dep = dependency('mir-blas', fallback : ['mir-blas', 'mir_blas_dep'])

required_deps = [
    cblas_d_dep,
    lapack_d_dep,
    mir_algorithm_dep,
    mir_blas_dep,
    mir_lapack_dep,
]

mir_integral_dir = include_directories('source/')

mir_integral_src = [
    'source/mir/quadrature.d',
]

mir_integral_lib = library(meson.project_name(),
    mir_integral_src,
    include_directories: mir_integral_dir,
    install: true,
    version: meson.project_version(),
    dependencies: required_deps,
)

mir_integral_dep = declare_dependency(
    link_with: [mir_integral_lib],
    include_directories: mir_integral_dir,
    dependencies: required_deps,
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(mir_integral_lib,
    description: 'Integration Routines',
    subdirs: 'd/' + meson.project_name(),
)

if get_option('with_test')

    mir_lapack_test_exe = executable(meson.project_name() + '-test',
        mir_integral_src,
        include_directories: mir_integral_dir,
        d_unittest: true,
        d_module_versions: ['mir_test'],
        link_args: '-main',
        dependencies: required_deps,
    )

    test(meson.project_name() + '-test', mir_lapack_test_exe)

endif
