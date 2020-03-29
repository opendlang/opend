mir_gesv_example_exe = executable(meson.project_name() + '-example',
    ['source/app.d'],
    include_directories: directories,
    dependencies: this_dep,
)

test(meson.project_name() + '-example', mir_gesv_example_exe)
