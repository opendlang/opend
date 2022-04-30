dub test --compiler dmd -a x86 -f
dub test --compiler dmd -a x86_64 -f
dub test --compiler ldc2 -a x86 -f
dub test --compiler ldc2 -a x86_64 -f
dub test --compiler dmd -a x86 -b unittest-inst -f
dub test --compiler dmd -a x86_64 -b unittest-inst -f
dub test --compiler ldc2 -a x86 -b unittest-inst -f
dub test --compiler ldc2 -a x86_64 -b unittest-inst -f
dub test --compiler dmd -a x86 -b unittest-release -f
dub test --compiler dmd -a x86_64 -b unittest-release -f 
dub test --compiler ldc2 -a x86 -b unittest-release -f
dub test --compiler ldc2 -a x86_64 -b unittest-release -f
dub test --compiler dmd -a x86 -b unittest-release-inst -f
dub test --compiler dmd -a x86_64 -b unittest-release-inst -f
dub test --compiler ldc2 -a x86 -b unittest-release-inst -f
dub test --compiler ldc2 -a x86_64 -b unittest-release-inst -f