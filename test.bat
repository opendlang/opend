dub test --compiler dmd -a x86
dub test --compiler dmd -a x86_64
dub test --compiler ldc2 -a x86
dub test --compiler ldc2 -a x86_64
dub test --compiler ldc2 -a x86 -b unittest-inst
dub test --compiler ldc2 -a x86_64 -b unittest-inst
dub test --compiler dmd -a x86 -b unittest-release
dub test --compiler dmd -a x86_64 -b unittest-release 
dub test --compiler ldc2 -a x86 -b unittest-release 
dub test --compiler ldc2 -a x86_64 -b unittest-release 
dub test --compiler ldc2 -a x86 -b unittest-release-inst
dub test --compiler ldc2 -a x86_64 -b unittest-release-inst