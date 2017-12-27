#!/usr/bin/fish

function noteStartAndRepoState
  echo "Status of main repository:" >testsStarted
  echo >>testsStarted
  echo "git branch:" >> testsStarted
  git branch >> testsStarted
  echo "git describe:" >> testsStarted
  git describe >> testsStarted
  echo "git status:" >> testsStarted
  git status >> testsStarted
  echo "git diff:" >> testsStarted
  git diff >> testsStarted

  if test $ENTERPRISEEDITION = On
    echo "Status of enterprise repository:" >> testsStarted
    cd enterprise
    echo "git branch:" >> ../testsStarted
    git branch >> ../testsStarted
    echo "git describe:" >> ../testsStarted
    git describe >> ../testsStarted
    echo "git status:" >> ../testsStarted
    git status >> ../testsStarted
    echo "git diff:" >> ../testsStarted
    git diff >> ../testsStarted
    cd ..
  end
end

function launchSingleTests
  noteStartAndRepoState

  set -g portBase 10000

  function test1
    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE \
      --minPort $portBase --maxPort (math $portBase + 99) $argv \
      >"$t""$tt".log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 5
  end

  test1 shell_server ""
  test1 shell_client ""
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
end

function launchClusterTests
  noteStartAndRepoState

  set -g portBase 10000

  function test1
    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    scripts/unittest $t --cluster true --storageEngine $STORAGEENGINE \
      --minPort $portBase --maxPort (math $portBase + 99) $argv \
      >"$t""$tt".log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 5
  end

  function test3
    echo scripts/unittest $argv[1] --test $argv[2] \
      --storageEngine $STORAGEENGINE --cluster true \
      --minPort $portBase --maxPort (math $portBase + 99) \
      >$argv[1]_$argv[3].log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 5
  end

  test3 resilience js/server/tests/resilience/moving-shards-cluster.js move
  test3 resilience js/server/tests/resilience/resilience-synchronous-repl-cluster.js failover
  test1 shell_client ""
  test1 shell_server ""
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
end

function waitForProcesses
  set i $argv[1]
  while true
    # Check subprocesses:
    set pids (jobs -p)
    if test (count $pids) = 0
      return 1
    end

    echo (count $pids) jobs still running, remaining $i seconds...

    set i (math $i - 5)
    if test $i -lt 0
      return 0
    end

    sleep 5
  end
end

function waitOrKill
  if waitForProcesses $argv[1]
    kill (jobs -p)
    if waitForProcesses 15
      kill -9 (jobs -p)
    end
  end
end

function createReport
  set d (date -u +%F_%H.%M.%SZ)
  rm -f testsEnded
  touch testsEnded
  set -l result GOOD
  for f in *.log
    if ! tail -1 $f | grep Success > /dev/null
      set -l result BAD
      echo Bad result in $f
      echo Bad result in $f >> testsEnded
    end
  end
  echo $result >> testsEnded
  tar czf "testreport-$d.tar.gz" *.log testsStarted testsEnded core*
end

function cleanUp
  killall -9 arangod arangosh
  rm -rf testsStarted testsEnded *.log core*
end

cd /work/ArangoDB

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
end

cleanUp

