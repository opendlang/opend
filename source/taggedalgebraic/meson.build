taggedalgebraic_src = [
	'package.d',
	'taggedalgebraic.d',
	'taggedunion.d',
	'visit.d',
]

# https://github.com/mesonbuild/meson/issues/6862
if build_machine.system() == 'darwin'
	taggedalgebraic_lib = library(
		'taggedalgebraic',
		taggedalgebraic_src,
		install: true,
		include_directories: include_directories('../'),
	)
else
	taggedalgebraic_lib = library(
		'taggedalgebraic',
		taggedalgebraic_src,
		install: true,
		include_directories: include_directories('../'),
		version: project_version,
	)
endif

pkgc = import('pkgconfig')

pkgc.generate(
	taggedalgebraic_lib,
	subdirs: 'd/taggedalgebraic',
)

install_headers(
	taggedalgebraic_src,
	subdir: 'd/taggedalgebraic/taggedalgebraic',
)

test_exe = executable(
	'taggedalgebraic_test',
	taggedalgebraic_src,
	include_directories: include_directories('../'),
	d_unittest: true,
	link_args: '-main',
)

test('test_taggedalgebraic', test_exe)
