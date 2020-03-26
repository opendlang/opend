taggedalgebraic_src = [
	'taggedalgebraic.d',
	'taggedunion.d',
	'visit.d',
]

taggedalgebraic_lib = library(
	'taggedalgebraic',
	taggedalgebraic_src,
	version: project_version,
	install: true,
	include_directories: include_directories('../')
)

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
