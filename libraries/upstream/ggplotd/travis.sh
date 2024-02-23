#!/bin/bash

function build_doc {
    #git clone -b libdparse https://github.com/BlackEdder/harbored-mod.git
    #git clone https://github.com/nemanja-boric-sociomantic/harbored-mod.git
    #cd harbored-mod
    #dub upgrade
    #dub build
    #cd ..
    #./harbored-mod/bin/hmod source/
    wget http://releases.defenestrate.eu/harbored-mod-0.2.0/hmod-x86-64.tar.gz
    tar xf hmod-x86-64.tar.gz
    ./hmod source/
}

set -e -o pipefail

dub test --compiler=${DC}
if [[ "$TRAVIS_OS_NAME" != "osx" ]]; then # gtkd broken on osx
    dub test -c ggplotd-gtk --compiler=${DC}
fi

if [[ $TRAVIS_BRANCH == 'master' ]] ; then
    if [ ! -z "$GH_TOKEN" ]; then
        git checkout master
        build_doc
        cd doc
        mkdir images
        cp ../*.{png,svg} images/
        git init
        git config user.name "Travis-CI"
        git config user.email "travis@nodemeatspace.com"
        git add .
        git commit -m "Deployed to Github Pages"
        #git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages > /dev/null 2>&1
        git push --force --quiet "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" master:gh-pages > /dev/null 2>&1
        #git push --force "https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}" HEAD:gh-pages
    fi
fi
