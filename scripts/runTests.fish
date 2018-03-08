#!/usr/bin/env fish

set -g repoState ""
set -g repoStateEnterprise ""

if test -z "$PARALLELISM"
  set -g PARALLELISM 64
end

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

function resetLaunch
  noteStartAndRepoState
  set -g launchFactor $argv[1]
  set -g portBase 10000
  set -g launchCount 0
  echo Launching tests...
end

function launchSingleTests
  function test1
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end

    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    echo scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort (math $portBase + 99) $argv --skipNondeterministic true --skipTimeCritical true
    scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE \
      --minPort $portBase --maxPort (math $portBase + 99) $argv \
      --skipNondeterministic true --skipTimeCritical true >"$t""$tt".log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 1
  end

  switch $launchCount
    case 0 ; test1 shell_server ""
    case 1 ; test1 shell_client ""
    case 2 ; test1 recovery 0 --testBuckets 4/0
    case 3 ; test1 recovery 1 --testBuckets 4/1
    case 4 ; test1 recovery 2 --testBuckets 4/2
    case 5 ; test1 recovery 3 --testBuckets 4/3
    case 6 ; test1 replication_sync ""
    case 7 ; test1 replication_static ""
    case 8 ; test1 replication_ongoing ""
    case 9 ; test1 http_server ""
    case 10 ; test1 ssl_server ""
    case 11 ; test1 shell_server_aql 0 --testBuckets 5/0
    case 12 ; test1 shell_server_aql 1 --testBuckets 5/1
    case 13 ; test1 shell_server_aql 2 --testBuckets 5/2
    case 14 ; test1 shell_server_aql 3 --testBuckets 5/3
    case 15 ; test1 shell_server_aql 4 --testBuckets 5/4
    case 16 ; test1 dump ""
    case 17 ; test1 server_http ""
    case 18 ; test1 agency ""
    case 19 ; test1 shell_replication ""
    case 20 ; test1 http_replication ""
    case 21 ; test1 catch ""
    case '*' ; return 0
  end
  set -g launchCount (math $launchCount + 1)
  return 1
end

function launchClusterTests
  function test1
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end
    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    echo scripts/unittest $t --cluster true --storageEngine $STORAGEENGINE --minPort $portBase --maxPort (math $portBase + 99) $argv --skipNonDeterministic true --skipTimeCritical true
    scripts/unittest $t --cluster true --storageEngine $STORAGEENGINE \
      --minPort $portBase --maxPort (math $portBase + 99) $argv \
      --skipNonDeterministic true --skipTimeCritical true >"$t""$tt".log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 1
  end

  function test3
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end
    echo scripts/unittest $argv[1] --test $argv[3] --storageEngine $STORAGEENGINE --cluster true --minPort $portBase --maxPort (math $portBase + 99) --skipNonDeterministic true
    scripts/unittest $argv[1] --test $argv[3] \
      --storageEngine $STORAGEENGINE --cluster true \
      --minPort $portBase --maxPort (math $portBase + 99) \
      --skipNonDeterministic true >$argv[1]_$argv[2].log ^&1 &
    set -g portBase (math $portBase + 100)
    sleep 1
  end

  switch $launchCount
    case 0 ; test3 resilience move js/server/tests/resilience/moving-shards-cluster.js
    case 1 ; test3 resilience failover js/server/tests/resilience/resilience-synchronous-repl-cluster.js
    case 2 ; test1 shell_client ""
    case 3 ; test1 shell_server ""
    case 4 ; test1 http_server ""
    case 5 ; test1 ssl_server ""
    case 6 ; test3 resilience sharddist js/server/tests/resilience/shard-distribution-spec.js
    case 7 ; test1 shell_server_aql 0 --testBuckets 5/0
    case 8 ; test1 shell_server_aql 1 --testBuckets 5/1
    case 9 ; test1 shell_server_aql 2 --testBuckets 5/2
    case 10 ; test1 shell_server_aql 3 --testBuckets 5/3
    case 11 ; test1 shell_server_aql 4 --testBuckets 5/4
    case 12 ; test1 dump ""
    case 13 ; test1 server_http ""
    case 14 ; test1 agency ""
    case '*' ; return 0
  end
  set -g launchCount (math $launchCount + 1)
  return 1
end

function waitForProcesses
  set i $argv[1]
  set launcher $argv[2]
  while true
    # Launch if necessary:
    while test (math (count (jobs -p))"*$launchFactor") -lt "$PARALLELISM"
      if test -z "$launcher" ; break ; end
      if eval "$launcher" ; break ; end
    end
    # Check subprocesses:
    if test (count (jobs -p)) -eq 0
      return 1
    end

    echo -n (count (jobs -p)) jobs still running, remaining $i "seconds..."

    set i (math $i - 5)
    if test $i -lt 0
      return 0
    end

    sleep 5
  end
end

function waitOrKill
  set timeout $argv[1]
  set launcher $argv[2]
  echo Controlling subprocesses...
  if waitForProcesses $timeout $launcher
    kill (jobs -p)
    if waitForProcesses 30 ""
      kill -9 (jobs -p)
      waitForProcesses 15 ""   # give jobs some time to finish
    end
  end
  return 0
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
  set -l badtests
  for f in *.log
    if not tail -1 $f | grep Success > /dev/null
      set -g result BAD
      echo Bad result in $f
      echo Bad result in $f >> testProtocol.txt
      set badtests $badtests "Bad result in $f"
    end
  end
  echo $result >> testProtocol.txt
  pushd $INNERWORKDIR
  and begin
    tar czvf "$INNERWORKDIR/ArangoDB/innerlogs.tar.gz" tmp --exclude databases --exclude rocksdb --exclude journals
    popd
  end
  
  set cores core*
  set archives *.tar.gz
  set logs *.log
  set binary
  if test (count $cores) != 0
    set binary build/bin/arangod
  end
  echo tar czvf "$INNERWORKDIR/testreport-$d.tar.gz" $logs testProtocol.txt $cores $archives $binary
  tar czvf "$INNERWORKDIR/testreport-$d.tar.gz" $logs testProtocol.txt $cores $archives $binary
  echo rm -rf $cores $archives testProtocol.txt
  rm -rf $cores $archives testProtocol.txt
  log "$d $TESTSUITE $result M:$MAINTAINER $BUILDMODE E:$ENTERPRISEEDITION $STORAGEENGINE" $repoState $repoStateEnterprise $badtests ""
end

cd $INNERWORKDIR
rm -rf tmp
mkdir tmp
set -xg TMPDIR $INNERWORKDIR/tmp
cd $INNERWORKDIR/ArangoDB
for f in *.log ; rm -f $f ; end

switch $TESTSUITE
  case "cluster"
    resetLaunch 4
    waitOrKill 1800 launchClusterTests
    createReport
  case "single"
    resetLaunch 1
    waitOrKill 1800 launchSingleTests
    createReport
  case "resilience"
    resetLaunch 4
    waitOrKill 1800 launchResilienceTests
    createReport
  case "*"
    echo Unknown test suite $TESTSUITE
    set -g result BAD
end

if test $result = GOOD
  exit 0
else
  exit 1
end
