rm -rf dist/
rm -rf build/
pyinstaller main.spec
cp README.md /home/oracle/oraclelocalcheck/dist
cd dist/ && tar -czvf oraclelocalcheck.tar.gz main README.md
rm -rf /home/oracle/oraclelocalcheck/build/
mv /home/oracle/oraclelocalcheck/dist/oraclelocalcheck.tar.gz /home/oracle
rm -rf /home/oracle/main
mv /home/oracle/oraclelocalcheck/dist/main /home/oracle
rm -rf /home/oracle/oraclelocalcheck/dist/
