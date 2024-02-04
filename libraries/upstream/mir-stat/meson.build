project('mir-stat', 'd', version : '0.3.1', license: 'Apache-2.0')

description = 'Dlang Statistical Package'

subprojects = [
    'cblas-d',
    'lapack-d',
    'mir-algorithm',
    'mir-blas',
    'mir-core',
    'mir-lapack',
    'mir-random',
]

if target_machine.system() == 'linux'
    subprojects += 'mir-linux-kernel'
endif

has_cpp_headers = false

sources_list = [
    'mir/math/internal/fp_powi',
    'mir/math/internal/powi',
    'mir/math/internal/log_beta',
    'mir/math/internal/log_binomial',
    'mir/math/internal/xlogy',
    'mir/stat/descriptive/multivariate',
    'mir/stat/descriptive/univariate',
    'mir/stat/descriptive/weighted',
    'mir/stat/descriptive/aliases',
    'mir/stat/descriptive/package',
    'mir/stat/constant',
    'mir/stat/inference',
    'mir/stat/transform',
    'mir/stat/package',
    'mir/stat/distribution/bernoulli',
    'mir/stat/distribution/beta',
    'mir/stat/distribution/beta_proportion',
    'mir/stat/distribution/binomial',
    'mir/stat/distribution/categorical',
    'mir/stat/distribution/cauchy',
    'mir/stat/distribution/chi2',
    'mir/stat/distribution/cornish_fisher',
    'mir/stat/distribution/exponential',
    'mir/stat/distribution/f',
    'mir/stat/distribution/gamma',
    'mir/stat/distribution/generalized_pareto',
    'mir/stat/distribution/geometric',
    'mir/stat/distribution/gev',
    'mir/stat/distribution/hypergeometric',
    'mir/stat/distribution/laplace',
    'mir/stat/distribution/log_normal',
    'mir/stat/distribution/logistic',
    'mir/stat/distribution/negative_binomial',
    'mir/stat/distribution/normal',
    'mir/stat/distribution/pareto',
    'mir/stat/distribution/poisson',
    'mir/stat/distribution/rayleigh',
    'mir/stat/distribution/students_t',
    'mir/stat/distribution/uniform',
    'mir/stat/distribution/uniform_discrete',
    'mir/stat/distribution/weibull',
    'mir/stat/distribution/cdf',
    'mir/stat/distribution/invcdf',
    'mir/stat/distribution/pdf',
    'mir/stat/distribution/package',
]

sources = []
foreach s : sources_list
    sources += 'source/' + s + '.d'
endforeach

add_project_arguments([
    '-preview=dip1008',
    '-lowmem',
], language: 'd')

required_deps = []

foreach p : subprojects 
    required_deps += dependency(p, fallback : [p, 'this_dep'])
endforeach

directories = ['source']

if has_cpp_headers
    directories += 'include'
endif

directories = include_directories(directories)

this_lib = library(meson.project_name(),
    sources,
    include_directories: directories,
    install: true,
    version: meson.project_version(),
    dependencies: required_deps,
)

this_dep = declare_dependency(
    link_with: [this_lib],
    include_directories: directories,
    dependencies: required_deps,
)

test_versions = ['mir_stat_test']

if has_cpp_headers
    install_subdir('include/',
        strip_directory :true,
        install_dir: 'include/',
    )
endif

install_subdir('source/',
    strip_directory : true,
    install_dir: 'include/d/' + meson.project_name(),
)

import('pkgconfig').generate(this_lib,
    description: description,
    subdirs: 'd/' + meson.project_name(),
)

test_subdirs = []
