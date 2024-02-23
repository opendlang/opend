dub test --compiler dmd -a x86 -f
dub test --compiler dmd -a x86_64 -f
dub test --compiler c:\d\dmd.2.102.0.windows\dmd2\windows\bin\dmd.exe -a x86_64 -f
dub test --compiler ldc2 -a x86 -f
dub test --compiler ldc2 -a x86_64 -f
dub test --compiler dmd -a x86 -b unittest-inst -f
dub test --compiler dmd -a x86_64 -b unittest-inst -f
dub test --compiler ldc2 -a x86 -b unittest-inst -f
dub test --compiler ldc2 -a x86_64 -b unittest-inst -f
dub test --compiler ldc2 -a x86 -b unittest-below-avx -f
dub test --compiler ldc2 -a x86_64 -b unittest-below-avx -f
dub test --compiler dmd -a x86 -b unittest-release -f
dub test --compiler dmd -a x86_64 -b unittest-release -f 
dub test --compiler ldc2 -a x86 -b unittest-release -f
dub test --compiler ldc2 -a x86_64 -b unittest-release -f
dub test --compiler dmd -a x86 -b unittest-release-inst -f
dub test --compiler dmd -a x86_64 -b unittest-release-inst -f
dub test --compiler ldc2 -a x86 -b unittest-release-inst -f
dub test --compiler ldc2 -a x86_64 -b unittest-release-inst -f