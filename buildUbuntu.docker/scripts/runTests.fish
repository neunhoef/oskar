#!/usr/bin/fish

set -g repoState ""
set -g repoStateEnterprise ""

function getRepoState
  set -g repoState (git status -b -s | grep -v "^[?]")
  if test $ENTERPRISEEDITION = On 
    cd enterprise
    set -g repoStateEnterprise (git status -b -s | grep -v "^[?]")
    cd ..
  else
    set -g repoStateEnterprise ""
  end
end

function noteStartAndRepoState
  getRepoState
  rm -f testProtocol.txt
  set -l d (date -u +%F_%H.%M.%SZ)
  echo $d >> testProtocol.txt
  echo "========== Status of main repository:" >> testProtocol.txt
  echo "========== Status of main repository:"
  for l in $repoState ; echo "  $l" >> testProtocol.txt ; echo "  $l" ; end
  if test $ENTERPRISEEDITION = On
    echo "Status of enterprise repository:" >> testProtocol.txt
    echo "Status of enterprise repository:"
    for l in $repoStateEnterprise
      echo "  $l" >> testProtocol.txt ; echo "  $l"
    end
  end
end

function launchSingleTests
  noteStartAndRepoState
  echo Launching tests...

  set -g portBase 10000

  function test1
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end

    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE \
      --minPort $portBase --maxPort (math $portBase + 99) $argv \
      --skipNonDeterministic true >"$t""$tt".log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 5
  end

  test1 shell_server ""
  test1 shell_client ""
  test1 recovery 0 --testBuckets 4/0
  test1 recovery 1 --testBuckets 4/1
  test1 recovery 2 --testBuckets 4/2
  test1 recovery 3 --testBuckets 4/3
  test1 replication_sync ""
  test1 replication_static ""
  test1 replication_ongoing ""
  test1 http_server ""
  test1 ssl_server ""
  test1 shell_server_aql 0 --testBuckets 5/0
  test1 shell_server_aql 1 --testBuckets 5/1
  test1 shell_server_aql 2 --testBuckets 5/2
  test1 shell_server_aql 3 --testBuckets 5/3
  test1 shell_server_aql 4 --testBuckets 5/4
  test1 dump ""
  test1 server_http ""
  test1 agency ""
  test1 shell_replication ""
  test1 http_replication ""
  test1 catch ""
end

function launchClusterTests
  noteStartAndRepoState
  echo Launching tests...

  set -g portBase 10000

  function test1
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end
    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    scripts/unittest $t --cluster true --storageEngine $STORAGEENGINE \
      --minPort $portBase --maxPort (math $portBase + 99) $argv \
      --skipNonDeterministic true >"$t""$tt".log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 5
  end

  function test3
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end
    scripts/unittest $argv[1] --test $argv[3] \
      --storageEngine $STORAGEENGINE --cluster true \
      --minPort $portBase --maxPort (math $portBase + 99) \
      --skipNonDeterministic true >$argv[1]_$argv[2].log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 5
  end

  test3 resilience move js/server/tests/resilience/moving-shards-cluster.js
  test3 resilience failover js/server/tests/resilience/resilience-synchronous-repl-cluster.js
  test1 shell_client ""
  test1 shell_server ""
  test1 http_server ""
  test1 ssl_server ""
  test3 resilience sharddist js/server/tests/resilience/shard-distribution-spec.js
  test1 shell_server_aql 0 --testBuckets 5/0
  test1 shell_server_aql 1 --testBuckets 5/1
  test1 shell_server_aql 2 --testBuckets 5/2
  test1 shell_server_aql 3 --testBuckets 5/3
  test1 shell_server_aql 4 --testBuckets 5/4
  test1 dump ""
  test1 server_http ""
  test1 agency ""
end

function waitForProcesses
  set i $argv[1]
  while true
    # Check subprocesses:
    set pids (jobs -p)
    if test (count $pids) -eq 0
      echo
      return 1
    end

    echo -n (count $pids) jobs still running, remaining $i "seconds..."\r

    set i (math $i - 5)
    if test $i -lt 0
      echo
      return 0
    end

    sleep 5
  end
end

function waitOrKill
  echo Waiting for processes to terminate...
  if waitForProcesses $argv[1]
    kill (jobs -p)
    if waitForProcesses 15
      kill -9 (jobs -p)
    end
  end
end

function log
  for l in $argv
    echo $l
    echo $l >> $INNERWORKDIR/test.log
  end
end

function createReport
  set d (date -u +%F_%H.%M.%SZ)
  echo $d >> testProtocol.txt
  echo
  set -g result GOOD
  for f in *.log
    if not tail -1 $f | grep Success > /dev/null
      set -g result BAD
      echo Bad result in $f
      echo Bad result in $f >> testProtocol.txt
    end
  end
  echo $result >> testProtocol.txt
  set -l cores core*
  tar czf "$INNERWORKDIR/testreport-$d.tar.gz" *.log testProtocol.txt $cores
  log "$d $TESTSUITE $result M:$MAINTAINER $BUILDMODE E:$ENTERPRISEEDITION $STORAGEENGINE" "" $repoState $repoStateEnterprise ""
end

function cleanUp
  killall -9 arangod arangosh ^/dev/null
  set -l cores core*
  rm -rf testProtocol.txt *.log $cores
end

cd $INNERWORKDIR/ArangoDB

switch $TESTSUITE
  case "cluster"
    launchClusterTests
    waitOrKill 900
    createReport
  case "single"
    launchSingleTests
    waitOrKill 900
    createReport
  case "resilience"
    launchResilienceTests
    waitOrKill 900
    createReport
  case "*"
    echo Unknown test suite $TESTSUITE
    set -g result BAD
end

cleanUp

chown -R $UID:$GID $INNERWORKDIR

if test $result == GOOD
  exit 0
else
  exit 1
end
