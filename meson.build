project('mir-core', 'd', version : '0.1.0', license: 'BSL-1.0')

mir_core_dir = include_directories('source/')

mir_core_src = [
    'source/mir/bitmanip.d',
    'source/mir/bitop.d',
    'source/mir/checkedint.d',
    'source/mir/conv.d',
    'source/mir/functional.d',
    'source/mir/internal/memory.d',
    'source/mir/internal/utility.d',
    'source/mir/math/common.d',
    'source/mir/math/constant.d',
    'source/mir/math/ieee.d',
    'source/mir/math/package.d',
    'source/mir/primitives.d',
    'source/mir/qualifier.d',
    'source/mir/utility.d',
]

mir_core_lib = library(meson.project_name(),
    mir_core_src,
    include_directories: mir_core_dir,
    install: true,
    version: meson.project_version(),
)

mir_core_dep = declare_dependency(
    link_with: [mir_core_lib],
    include_directories: mir_core_dir,
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(
    name: meson.project_name(),
    description: 'Mir Core - Base software building blocks and conventions.',
    subdirs: 'd/' + meson.project_name(),
    libraries: [mir_core_lib],
    version: meson.project_version(),
)

if get_option('with_test')

    mir_core_test_exe = executable(meson.project_name() + '-test',
        mir_core_src,
        include_directories: mir_core_dir,
        d_unittest: true,
        d_module_versions: ['mir_test'],
        link_args: '-main',
    )

    test(meson.project_name() + '-test', mir_core_test_exe)

endif
