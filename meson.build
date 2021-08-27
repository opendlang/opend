project('lapack', 'd', version : '0.4.1', license: 'BSL-1.0')

description = 'LAPACK header'

subprojects = ['mir-core']

sources_list = [
]

required_deps = []

foreach p : subprojects 
    required_deps += dependency(p, fallback : [p, 'this_dep'])
endforeach

directories = ['source']

directories = include_directories(directories)

this_dep = declare_dependency(
    include_directories: directories,
    dependencies: required_deps,
)

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

lapack_dep = this_dep
