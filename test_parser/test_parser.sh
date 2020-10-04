dub build --compiler=ldc2
if [ -d JSONTestSuite ]; then
	echo "JSONTestSuite already exist"
else
	git clone https://github.com/nst/JSONTestSuite
fi
cp run_asdf_tests.py JSONTestSuite/run_asdf_tests.py
cd JSONTestSuite
python3 run_asdf_tests.py
