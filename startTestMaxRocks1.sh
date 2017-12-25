#!/bin/bash
cd ~/ArangoDB
echo "Single server test result overview" > botschaft.txt
echo "==================================" >> botschaft.txt
echo -n "Tests started:" >> botschaft.txt
date >> botschaft.txt
rm -f *.log
git pull
cd build
make -j64
cd ..

echo Starting tests...
touch testsStarted
echo Starting shell_server
scripts/unittest shell_server --storageEngine rocksdb --cluster false > shell_server.log 2>&1 &
sleep 20
echo Starting shell_client
scripts/unittest shell_client --storageEngine rocksdb --cluster false > shell_client.log 2>&1 &
sleep 20
echo Starting http_server
scripts/unittest http_server --storageEngine rocksdb --cluster false > http_server.log 2>&1 &
sleep 20
echo Starting ssl_server
scripts/unittest ssl_server --storageEngine rocksdb --cluster false > ssl_server.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 4/0
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster false --testBuckets 4/0 > shell_server_aql_bucket0.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 4/1
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster false --testBuckets 4/1 > shell_server_aql_bucket1.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 4/2
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster false --testBuckets 4/2 > shell_server_aql_bucket2.log 2>&1 &
sleep 20
echo Starting shell_server_aql bucket 4/3
scripts/unittest shell_server_aql --storageEngine rocksdb --cluster false --testBuckets 4/3 > shell_server_aql_bucket3.log 2>&1 &
sleep 30
echo Starting dump
scripts/unittest dump --storageEngine rocksdb --cluster false > dump.log 2>&1 &
sleep 30
echo Starting server_http
scripts/unittest server_http --storageEngine rocksdb --cluster false > server_http.log 2>&1 &
sleep 30
echo Starting agency
scripts/unittest agency --storageEngine rocksdb > agency.log 2>&1 &

wait

echo -n "Tests finished: " >> botschaft.txt
date >> botschaft.txt
tail -n 3 *.log >>botschaft.txt
#mutt -s "Single server test results are in" < botschaft.txt max@arangodb.com -a shell_server_aql_bucket0.log -a shell_server_aql_bucket1.log -a shell_server_aql_bucket2.log -a shell_server_aql_bucket3.log -a shell_server.log shell_client.log http_server.log ssl_server.log dump.log -a server_http.log -a agency.log
echo Ready.

