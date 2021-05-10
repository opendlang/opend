echo $ARCH
if [ "$ARCH" = "AARCH64" ]
then
  dub test --arch=aarch64 --build=unittest
else
  dub test --arch=$ARCH --build=unittest
fi
