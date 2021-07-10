echo $ARCH
if [ "$ARCH" = "AARCH64" ]
then
  dub test --arch=aarch64 --build=unittest
  dub build --arch=aarch64 -c bloomberg
else
  dub test --arch=$ARCH --build=unittest
  dub build --arch=$ARCH -c bloomberg
fi
