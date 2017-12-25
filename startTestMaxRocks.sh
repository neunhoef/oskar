#!/bin/bash
cd /home/neunhoef/ArangoDB
echo "Test result overview" > botschaft.txt
echo "====================" >> botschaft.txt
echo -n "Tests started:" >> botschaft.txt
date >> botschaft.txt
rm -f *.log
git pull
if [ ! -d build ] ; then
  mkdir build
  cd build
  cmake -C ~/.cmake_gcc_O3 ..
else
  cd build
fi
make -j64
cd ..

echo Starting tests...
touch testsStarted
echo Starting resilienceFail
scripts/unittest resilience --storageEngine rocksdb --test js/server/tests/resilience/resilience-synchronous-repl-cluster.js > resilienceFail.log 2>&1 &
sleep 20
echo Starting shell_client
scripts/unittest shell_client --storageEngine rocksdb --cluster true > shell_client.log 2>&1 &
sleep 20
echo Starting shell_server
scripts/unittest shell_server --storageEngine rocksdb --cluster true > shell_server.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 5/1
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster true --testBuckets 5/1 > shell_server_aql_bucket1.log 2>&1 &
sleep 20
echo Starting http_server
scripts/unittest http_server --skipTimeCritical true --storageEngine rocksdb --cluster true > http_server.log 2>&1 &
sleep 20
echo Starting ssl_server
scripts/unittest ssl_server --skipTimeCritical true --storageEngine rocksdb --cluster true > ssl_server.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 5/0
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster true --testBuckets 5/0 > shell_server_aql_bucket0.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 5/2
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster true --testBuckets 5/2 > shell_server_aql_bucket2.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 5/3
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster true --testBuckets 5/3 > shell_server_aql_bucket3.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 5/4
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster true --testBuckets 5/4 > shell_server_aql_bucket4.log 2>&1 &
sleep 20
echo Starting resilienceMove
scripts/unittest resilience --storageEngine rocksdb --test js/server/tests/resilience/moving-shards-cluster.js > resilienceMove.log 2>&1 &
sleep 20
echo Starting dump
scripts/unittest dump --storageEngine rocksdb --cluster true > dump.log 2>&1 &
sleep 20
echo Starting server_http
scripts/unittest server_http --storageEngine rocksdb --cluster true > server_http.log 2>&1 &
sleep 20
echo Starting agency
scripts/unittest agency --storageEngine rocksdb > agency.log 2>&1 &

wait

echo -n "Tests finished: " >> botschaft.txt
date >> botschaft.txt
tail -n 3 *.log >>botschaft.txt
#mutt -s "Test results are in" < botschaft.txt max@arangodb.com -a shell_server_aql_bucket0.log -a shell_server_aql_bucket1.log -a shell_server_aql_bucket2.log -a shell_server_aql_bucket3.log -a shell_server.log shell_client.log http_server.log ssl_server.log dump.log -a server_http.log -a agency.log -a resilienceMove.log -a resilienceFail.log
echo Ready.

