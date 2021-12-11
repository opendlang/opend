echo $ARCH
if [ "$ARCH" = "AARCH64" ]
then
  dub test --arch=aarch64 --build=unittest
else
  # We only upload coverage data on x86/x86_64
  dub test --arch=$ARCH --build=unittest-cov
fi
