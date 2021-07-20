rm -rf dist/
rm -rf build/
pyinstaller main.spec
cp README.md /home/oracle/dbtool/dist
cd dist/ && tar -czvf dbtool.tar.gz main README.md
rm -rf /home/oracle/dbtool/build/
mv /home/oracle/dbtool/dist/dbtool.tar.gz /home/oracle
rm -rf /home/oracle/main
mv /home/oracle/dbtool/dist/main /home/oracle
rm -rf /home/oracle/dbtool/dist/
