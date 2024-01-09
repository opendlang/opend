This is the OpenD Programming Language compiler, originally based on Walter Bright's D Programming Language.

This repo contains a Digital Mars based compiler, a LLVM based compiler, the unified runtime, and portions of the standard library.

See:
https://docs.github.com/en/get-started/using-git/about-git-subtree-merges

ldc and phobos are both subtrees from upstream.

##  Quick start

```
mkdir opend_workspace

git clone git@github.com:opendlang/opend.git
cd opend && make && cd ..
// build Phobos
cd phobos && make && cd ../..

ln -s opend/phobos
alias odmd=opend/generated/linux/release/64/dmd

echo "import std.stdio; void main() { writeln(\"Hello OpenD!\");}" > hello_opend.d
odmd hello_open.d
./hello_opend
```
