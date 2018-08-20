#!/usr/bin/env fish

set -l LOCALWORKDIR $argv[1]
set -l DBOUT "$LOCALWORKDIR/dbserver.csv"
rm -rf DBOUT
set -l COUT "$LOCALWORKDIR/coordinator.csv"
rm -rf COUT
set -l pPid (ps ax | grep arango | grep PRIMARY | head -1 | awk '{print $1}')
set -l cPid (ps ax | grep arango | grep COORDINATOR | head -1 | awk '{print $1}')

while true
  ps -p $pPid -o "%cpu,%mem" --no-header >> DBOUT
  ps -p $cPid -o "%cpu,%mem" --no-header >> COUT
  sleep 5
end

