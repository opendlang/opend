project('mir-lapack', 'd', 'c', version : '1.0.0', license: 'BSL-1.0')

cblas_d_dep = dependency('cblas-d', fallback : ['cblas', 'cblas_dep'])
lapack_d_dep = dependency('lapack-d', fallback : ['lapack', 'lapack_dep'])
mir_algorithm_dep = dependency('mir-algorithm', fallback : ['mir-algorithm', 'mir_algorithm_dep'])
mir_blas_dep = dependency('mir-blas', fallback : ['mir-blas', 'mir_blas_dep'])

cc = meson.get_compiler('c')
lapack_deps = []
if not cc.find_library('openblas', required : false).found()
    lapack_deps = [cc.find_library('lapack')]
endif

required_deps = [
    cblas_d_dep,
    lapack_d_dep,
    lapack_deps,
    mir_algorithm_dep,
    mir_blas_dep,
]

mir_lapack_dir = include_directories('source/')

mir_lapack_src = [
    'source/mir/lapack.d',
]

mir_lapack_lib = library(meson.project_name(),
    mir_lapack_src,
    include_directories: mir_lapack_dir,
    install: true,
    version: meson.project_version(),
    dependencies: required_deps,
)

mir_lapack_dep = declare_dependency(
    link_with: [mir_lapack_lib],
    include_directories: mir_lapack_dir,
    dependencies: required_deps,
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(mir_lapack_lib,
    description: 'ndslice API for LAPACK',
    subdirs: 'd/' + meson.project_name(),
)

if get_option('with_test')

    mir_lapack_test_exe = executable(meson.project_name() + '-test',
        mir_lapack_src,
        include_directories: mir_lapack_dir,
        d_unittest: true,
        d_module_versions: ['mir_test'],
        link_args: '-main',
        dependencies: required_deps,
    )

    test(meson.project_name() + '-test', mir_lapack_test_exe)

endif
