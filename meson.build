project('lapack', 'd', version : '0.0.4', license: 'BSL-1.0')

lapack_dir = include_directories('source/')

lapack_dep = declare_dependency(
    include_directories: lapack_dir,
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(
    name: meson.project_name() + '-d',
    description: 'LAPACK header for Dlang.',
    subdirs: 'd/' + meson.project_name(),
    version: meson.project_version(),
)
