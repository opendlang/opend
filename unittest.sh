for file in `ls *.d`;
do
    echo $file;
    dmd $@ -unittest -run $file;
done
