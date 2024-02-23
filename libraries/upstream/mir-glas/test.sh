ARCH=x86_64
BLAS=3.7.0
CPUID=0.5.3
dub build --arch=$ARCH --build-mode=singleFile --force --config=static --parallel --build=target-native --compiler=ldmd2
ar -x libmir-glas.a
dub fetch mir-cpuid --version=$CPUID --cache=local
cd mir-cpuid-$CPUID/mir-cpuid
dub build --arch=$ARCH --build-mode=singleFile --build=release-nobounds --force --parallel --compiler=ldmd2
ar -x libmir-cpuid.a
cd ../../
cp mir-cpuid-$CPUID/mir-cpuid/libmir-cpuid.a libmir-cpuid.a
curl -Os http://www.netlib.org/blas/blas-"$BLAS".tgz
tar zxf blas-"$BLAS".tgz
cd BLAS-$BLAS
make -j
ar cr libblas_mix.a \
	sgemv.o sgbmv.o \
	ssymv.o ssbmv.o sspmv.o strmv.o stbmv.o stpmv.o strsv.o stbsv.o stpsv.o sger.o ssyr.o sspr.o ssyr2.o sspr2.o ssyrk.o \
	ssyr2k.o strmm.o strsm.o \
	dgemv.o dgbmv.o dsymv.o dsbmv.o dspmv.o dtrmv.o dtbmv.o dtpmv.o dtrsv.o dtbsv.o dtpsv.o dger.o dsyr.o dspr.o \
	dsyr2.o dspr2.o dsyrk.o dsyr2k.o dtrmm.o dtrsm.o scabs1.o \
	cgemv.o cgbmv.o chemv.o chbmv.o chpmv.o ctrmv.o ctbmv.o ctpmv.o ctrsv.o ctbsv.o \
	ctpsv.o cgerc.o cgeru.o cher.o chpr.o cher2.o chpr2.o csyrk.o csyr2k.o ctrmm.o ctrsm.o cherk.o cher2k.o dcabs1.o \
	zgemv.o zgbmv.o zhemv.o zhbmv.o \
	zhpmv.o ztrmv.o ztbmv.o ztpmv.o ztrsv.o ztbsv.o ztpsv.o zgerc.o zgeru.o zher.o zhpr.o zher2.o zhpr2.o zsyrk.o zsyr2k.o \
	ztrmm.o ztrsm.o zherk.o zher2k.o lsame.o xerbla_array.o \
	../*.o ../mir-cpuid-$CPUID/mir-cpuid/*.o 
ranlib libblas_mix.a
cd ..
curl -Os http://www.netlib.org/blas/blast-forum/cblas.tgz
tar zxf cblas.tgz
cd CBLAS
rm -f Makefile.in
ln -s Makefile.LINUX Makefile.in
realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}
BL=`eval realpath ../BLAS-"$BLAS"/libblas_mix.a`
echo $BL
make -j BLLIB=$BL alllib
make -j BLLIB=$BL alltst
make -j runtst 
cat testing/*.out
cd ..
rm *.tgz
rm -rf BLAS-$BLAS
rm -rf CBLAS
rm -rf mir-cpuid-$CPUID
rm -f *.o

# cd examples

# echo "D examples ..."

# dub -v --root=gemm
# rm -rf gemm/.dub
# dub -v --root=hemm
# rm -rf hemm/.dub

# echo "C examples ..."

# cd gemm
# gcc -std=c99 -I../../include -c gemm_example.c -o gemm_example.o
# gcc gemm_example.o -L../../ -lmir-glas -lmir-cpuid -o gemm_example
# ./gemm_example
# rm -f gemm_example
# cd ..

# cd hemm
# gcc -std=c99 -I../../include -c gemm_example.c -o gemm_example.o
# gcc gemm_example.o -L../../ -lmir-glas -lmir-cpuid -o gemm_example
# ./hemm_example
# rm -f hemm_example
# cd ..

# cd ..
