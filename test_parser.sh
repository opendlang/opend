dub build --compiler=ldc2
if [ -d JSONTestSuite ]; then
	echo "JSONTestSuite already exist"
else
	git clone https://github.com/nst/JSONTestSuite
fi
cp run_tests.py JSONTestSuite/run_tests.py
cd JSONTestSuite
python3 run_tests.py
