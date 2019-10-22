project('mir-core', 'd', version : '1.0.2', license: 'BSL-1.0')

# Basics option to follow FHS rules
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
sysconfdir = join_paths(prefix, get_option('sysconfdir'))
includedir = join_paths(prefix, get_option('includedir'))
datadir = join_paths(prefix, get_option('datadir'))
libexecdir = join_paths(prefix, get_option('libexecdir'))

# semver
version = meson.project_version().split('.')
major_version = version[0].to_int()
minor_version = version[1].to_int()
micro_version = version[2].to_int()

# base
dc = meson.get_compiler('d')

# Compiler and linker flags
common_dflags = []
common_ldflags = []

if host_machine.system() == 'linux'
  common_ldflags += [ '-Wl,-z,relro', '-Wl,-z,now' ]
endif


# Source files
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

lib_type = get_option('default_library')
if lib_type == 'shared' 
    mir_core_soname = 'lib@0@.so.@1@'.format(meson.project_name(), major_version)
    common_ldflags += ['-shared']

    if dc.get_id() == 'llvm'
        common_ldflags += [ '-soname', mir_core_soname ]
    endif

endif

mir_core_lib = library(meson.project_name(),
    mir_core_src,
    include_directories: mir_core_dir,
    link_args : common_ldflags,
    install: true,
    version: meson.project_version(),
)

mir_core_dep = declare_dependency(
    link_with: [mir_core_lib],
    include_directories: mir_core_dir,
)

# Compat variables for pkgconfig
pkg = import('pkgconfig')
pkg.generate(mir_core_lib,
    description: 'Mir Core - Base software building blocks and conventions.',
    subdirs: 'd/' + meson.project_name(),
    url: 'https://github.com/libmir/mir-core'
)


install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
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

