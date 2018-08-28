#!/usr/bin/env fish

set -g repoState ""
set -g repoStateEnterprise ""

if test -z "$PARALLELISM"
  set -g PARALLELISM 64
end

function getRepoState
  set -g repoState (git rev-parse HEAD) (git status -b -s | grep -v "^[?]")
  if test $ENTERPRISEEDITION = On 
    cd enterprise
    set -g repoStateEnterprise (git rev-parse HEAD) (git status -b -s | grep -v "^[?]")
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
  function jslint
    if test $VERBOSEOSKAR = On ; echo Launching jslint $argv ; end
    echo utils/jslint.sh
    utils/jslint.sh > $TMPDIR/jslint.log &
  end

  function test1
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end

    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    if grep $t UnitTests/OskarTestSuitesBlackList
      echo Test suite $t skipped by UnitTests/OskarTestSuitesBlackList
    else
      echo scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort (math $portBase + 99) $argv --skipNondeterministic true --skipTimeCritical true --testOutput $TMPDIR/"$t""$tt".out --writeXmlReport false
      scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE \
        --minPort $portBase --maxPort (math $portBase + 99) $argv \
        --skipNondeterministic true --skipTimeCritical true \
        --testOutput $TMPDIR/"$t""$tt".out --writeXmlReport false \
        >"$t""$tt".log ^&1 &
      set -g portBase (math $portBase + 100)
      sleep 1
    end
  end

  function test1MoreLogs
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end

    set -l t $argv[1]
    set -l tt $argv[2]
    set -e argv[1..2]
    if grep $t UnitTests/OskarTestSuitesBlackList
      echo Test suite $t skipped by UnitTests/OskarTestSuitesBlackList
    else
      echo scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE --minPort $portBase --maxPort (math $portBase + 99) $argv --skipNondeterministic true --skipTimeCritical true --testOutput $TMPDIR/"$t""$tt".out --writeXmlReport false --extraArgs:log.level replication=trace
      scripts/unittest $t --cluster false --storageEngine $STORAGEENGINE \
        --minPort $portBase --maxPort (math $portBase + 99) $argv \
        --skipNondeterministic true --skipTimeCritical true \
        --testOutput $TMPDIR/"$t""$tt".out --writeXmlReport false \
        --extraArgs:log.level replication=trace \
        >"$t""$tt".log ^&1 &
      set -g portBase (math $portBase + 100)
      sleep 1
    end
  end

  switch $launchCount
    case 0 ; test1 shell_server ""
    case 1 ; test1 shell_client ""
    case 2 ; test1 recovery 0 --testBuckets 4/0
    case 3 ; test1 recovery 1 --testBuckets 4/1
    case 4 ; test1 recovery 2 --testBuckets 4/2
    case 5 ; test1 recovery 3 --testBuckets 4/3
    case 6 ; test1MoreLogs replication_sync ""
    case 7 ; test1MoreLogs replication_static ""
    case 8 ; test1MoreLogs replication_ongoing ""
    case 9 ; test1 http_server ""
    case 10 ; test1 ssl_server ""
    case 11 ; test1 shell_server_aql 0 --testBuckets 5/0
    case 12 ; test1 shell_server_aql 1 --testBuckets 5/1
    case 13 ; test1 shell_server_aql 2 --testBuckets 5/2
    case 14 ; test1 shell_server_aql 3 --testBuckets 5/3
    case 15 ; test1 shell_server_aql 4 --testBuckets 5/4
    case 16 ; test1 shell_client_aql ""
    case 17 ; test1 dump ""
    case 18 ; test1 server_http ""
    case 19 ; test1 agency ""
    case 20 ; test1 shell_replication ""
    case 21 ; test1 http_replication ""
    case 22 ; test1 catch ""
    case 23 ; test1 authentication ""
    case 24 ; test1 dump_authentication ""
    case 25 ; test1 version ""
    case 26 ; test1 endpoints "" --skipEndpointsIpv6 true
    case 27 ; test1 arangobench  ""
    case 28 ; test1 arangosh ""
    case 29 ; test1 audit ""
    case 30 ; test1 auditlog ""
    case 31 ; test1 authentication_server ""
    case 32 ; test1 authentication_parameters ""
    case 33 ; test1 BackupNoAuthSysTests ""
    case 34 ; test1 BackupNoAuthNoSysTests ""
    case 35 ; test1 BackupAuthSysTests ""
    case 36 ; test1 BackupAuthNoSysTests ""
    case 37 ; test1 boost ""
    case 38 ; test1 config ""
    case 39 ; test1 dfdb ""
    case 40 ; test1 dump_encrypted "" 
    case 41 ; test1 export ""
    case 42 ; test1 importing ""
    case 43 ; test1 load_balancing ""
    case 44 ; test1 load_balancing_auth ""
    case 45 ; test1 queryCacheAuthorization ""
    case 46 ; test1 readOnly ""
    case 47 ; test1 replication_aql ""
    case 48 ; test1 replication_fuzz ""
    case 49 ; test1 replication_random ""
    case 50 ; test1 resilience ""
    case 51 ; test1 client_resilience ""
    case 52 ; test1 cluster_sync ""
    case 53 ; test1 active_failover ""
    case 54 ; test1 upgrade ""
    case 55 ; test1 foxx_manager ""
    case 56 ; test1 ldap ""
    case 57 ; test1 ldaprole ""
    case 58 ; test1 ldapsearch ""
    case 59 ; test1 ldaprolesimple ""
    case 60 ; test1 ldapsearchsimple ""
    case 61 ; jslint
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
    if grep $t UnitTests/OskarTestSuitesBlackList
      echo Test suite $t skipped by UnitTests/OskarTestSuitesBlackList
    else
      echo scripts/unittest $t --cluster true --storageEngine $STORAGEENGINE --minPort $portBase --maxPort (math $portBase + 99) $argv --skipNondeterministic true --skipTimeCritical true --testOutput $TMPDIR/"$t""$tt".out --writeXmlReport false
      scripts/unittest $t --cluster true --storageEngine $STORAGEENGINE \
        --minPort $portBase --maxPort (math $portBase + 99) $argv \
        --skipNondeterministic true --skipTimeCritical true \
        --testOutput $TMPDIR/"$t""$tt".out --writeXmlReport false \
        >"$t""$tt".log ^&1 &
      set -g portBase (math $portBase + 100)
      sleep 1
    end
  end

  function test3
    if test $VERBOSEOSKAR = On ; echo Launching $argv ; end
    if grep $argv[1] UnitTests/OskarTestSuitesBlackList
      echo Test suite $t skipped by UnitTests/OskarTestSuitesBlackList
    else
      echo scripts/unittest $argv[1] --test $argv[3] --storageEngine $STORAGEENGINE --cluster true --minPort $portBase --maxPort (math $portBase + 99) --skipNondeterministic true --testOutput "$TMPDIR/$argv[1]_$argv[2].out" --writeXmlReport false
      scripts/unittest $argv[1] --test $argv[3] \
        --storageEngine $STORAGEENGINE --cluster true \
        --minPort $portBase --maxPort (math $portBase + 99) \
        --skipNondeterministic true \
        --testOutput "$TMPDIR/$argv[1]_$argv[2].out" --writeXmlReport false \
        >$argv[1]_$argv[2].log ^&1 &
      set -g portBase (math $portBase + 100)
      sleep 1
    end
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
    case 12 ; test1 shell_client_aql ""
    case 13 ; test1 dump ""
    case 14 ; test1 dump_authentication ""
    case 15 ; test1 server_http ""
    case 16 ; test1 agency ""
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

    echo (date) (count (jobs -p)) jobs still running, remaining $i "seconds..."

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
      waitForProcesses 60 ""   # give jobs some time to finish
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
  pushd $INNERWORKDIR/tmp
  for d in *.out
    echo Looking at directory $d
    if test -f "$d/UNITTEST_RESULT_EXECUTIVE_SUMMARY.json"
      if not grep true "$d/UNITTEST_RESULT_EXECUTIVE_SUMMARY.json"
        set -g result BAD
        set f (basename -s out $d)log
        echo Bad result in $f
        echo Bad result in $f >> testProtocol.txt
        set badtests $badtests "Bad result in $f"
      end
    end
  end

  if test -e "jslint.log"
   # this is the jslint output
    if grep ERROR "jslint.log"
      set -g result BAD
      echo Bad result in jslint
      echo Bad result in jslint >> testProtocol.txt
      set badtests $badtests "Bad result in jslint"
    end
  end
 
  popd
  echo $result >> testProtocol.txt
  pushd $INNERWORKDIR
  and begin
    echo tar czvf "$INNERWORKDIR/ArangoDB/innerlogs.tar.gz" --exclude databases --exclude rocksdb --exclude journals tmp
    tar czvf "$INNERWORKDIR/ArangoDB/innerlogs.tar.gz" --exclude databases --exclude rocksdb --exclude journals tmp
    popd
  end
  
  set cores core*
  set archives *.tar.gz
  set logs *.log
  if test (count $cores) != 0
    set binaries build/bin/arangod build/bin/arangodbtests
    echo tar czvf "$INNERWORKDIR/crashreport-$d.tar.gz" $cores $binaries
    tar czvf "$INNERWORKDIR/crashreport-$d.tar.gz" $cores $binaries
  end
  echo tar czvf "$INNERWORKDIR/testreport-$d.tar.gz" $logs testProtocol.txt $archives
  tar czvf "$INNERWORKDIR/testreport-$d.tar.gz" $logs testProtocol.txt $archives

  echo rm -rf $cores $archives testProtocol.txt
  rm -rf $cores $archives testProtocol.txt

  # And finally collect the testfailures.txt:
  rm -rf $INNERWORKDIR/testfailures.txt
  touch $INNERWORKDIR/testfailures.txt
  for f in "$INNERWORKDIR"/tmp/*.out/testfailures.txt
    cat $f >> $INNERWORKDIR/testfailures.txt
  end
  if grep "unclean shutdown" "$INNERWORKDIR/testfailures.txt"
    set -g result BAD
  end
  log "$d $TESTSUITE $result M:$MAINTAINER $BUILDMODE E:$ENTERPRISEEDITION $STORAGEENGINE" $repoState $repoStateEnterprise $badtests ""

end

cd $INNERWORKDIR
rm -rf tmp
mkdir tmp
set -xg TMPDIR $INNERWORKDIR/tmp
cd $INNERWORKDIR/ArangoDB
for f in *.log ; rm -f $f ; end

# Switch off jemalloc background threads for the tests since this seems
# to overload our systems and is not needed.
set -x MALLOC_CONF background_thread:false

switch $TESTSUITE
  case "cluster"
    resetLaunch 4
    waitOrKill 1800 launchClusterTests
    createReport
  case "single"
    resetLaunch 1
    waitOrKill 3600 launchSingleTests
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
