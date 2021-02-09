echo $ARCH
if [ "$ARCH" = "AARCH64" ]
then
  dub test --arch=aarch64 --build=unittest
else
  dub test --arch=$ARCH --build=unittest
  # if [ \( "$DC" = "ldc2" \) -o \( "$DC" = "ldmd2" \) ]
  # then
  #     cd benchmarks/sajson ; dub --build=release-nobounds --compiler=ldmd2 ; cd ../..
  # fi
fi
