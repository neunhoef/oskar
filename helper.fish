function lockDirectory
  # Now grab the lock ourselves:
  set -l pid (echo %self)
  if test ! -f LOCK.$pid
    echo $pid > LOCK.$pid
    while true
      # Remove a stale lock if it is found:
      if set -l pidfound (cat LOCK ^/dev/null)
        if not ps ax -o pid | grep '^ *'"$pidfound"'$' > /dev/null
          rm LOCK LOCK.$pidfound
          echo Have removed stale lock.
        end
      end
      if ln LOCK.$pid LOCK ^/dev/null
        break
      end
      echo -n Directory is locked, waiting...
      date
      sleep 15
    end
  end
end

function unlockDirectory
  set -l pid (echo %self)
  if test -f LOCK.$pid
    rm -rf LOCK LOCK.$pid
  end
end

function showConfig
  echo "Workdir           : $WORKDIR"
  echo "Inner workdir     : $INNERWORKDIR"
  echo "Maintainer        : $MAINTAINER"
  echo "Buildmode         : $BUILDMODE"
  echo "Parallelism       : $PARALLELISM"
  echo "Enterpriseedition : $ENTERPRISEEDITION"
  echo "Storage engine    : $STORAGEENGINE"
  echo "Test suite        : $TESTSUITE"
  echo "Verbose           : $VERBOSEOSKAR"
end

function single ; set -gx TESTSUITE single ; end
function cluster ; set -gx TESTSUITE cluster ; end
function resilience ; set -gx TESTSUITE resilience ; end
if test -z "$TESTSUITE" ; cluster
else ; set -gx TESTSUITE $TESTSUITE ; end

function maintainerOn ; set -gx MAINTAINER On ; end
function maintainerOff ; set -gx MAINTAINER Off ; end
if test -z "$MAINTAINER" ; maintainerOn
else ; set -gx MAINTAINER $MAINTAINER ; end

function debugMode ; set -gx BUILDMODE Debug ; end
function releaseMode ; set -gx BUILDMODE RelWithDebInfo ; end
if test -z "$BUILDMODE" ; releaseMode
else ; set -gx BUILDMODE $BUILDMODE ; end

function community ; set -gx ENTERPRISEEDITION Off ; end
function enterprise ; set -gx ENTERPRISEEDITION On ; end
if test -z "$ENTERPRISEEDITION" ; enterprise
else ; set -gx ENTERPRISEEDITION $ENTERPRISEEDITION ; end

function mmfiles ; set -gx STORAGEENGINE mmfiles ; end
function rocksdb ; set -gx STORAGEENGINE rocksdb ; end
if test -z "$STORAGEENGINE" ; rocksdb
else ; set -gx STORAGEENGINE $STORAGEENGINE ; end

function parallelism ; set -gx PARALLELISM $argv[1] ; end
if test -z "$PARALLELISM" ; parallelism 64
else ; set -gx PARALLELISM $PARALLELISM ; end

function verbose ; set -gx VERBOSEOSKAR On ; end
function silent ; set -gx VERBOSEOSKAR Off ; end
if test -z "$VERBOSEOSKAR" ; verbose
else ; set -gx VERBOSEOSKAR $VERBOSEOSKAR ; end

set -gx WORKDIR (pwd)
if test ! -d work ; mkdir work ; end

function checkoutIfNeeded
  if test ! -d $WORKDIR/ArangoDB
    if test "$ENTERPRISEEDITION" = "On"
      checkoutEnterprise
    else
      checkoutArangoDB
    end
  end
end

function clearResults
  cd $WORKDIR/work
  for f in testreport* ; rm -f $f ; end
  rm -f test.log buildArangoDB.log cmakeArangoDB.log
end

function oskar1
  showConfig
  set -x NOSTRIP 1
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  oskar
end

function oskar2
  showConfig
  set -x NOSTRIP 1
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster
end

function oskar4
  showConfig
  set -x NOSTRIP 1
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  rocksdb
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  mmfiles
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster ; rocksdb
end

function oskar8
  showConfig
  enterprise
  set -x NOSTRIP 1
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  rocksdb
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  mmfiles
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  community
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  rocksdb
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  mmfiles
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster ; rocksdb
end

function showLog
  less +G work/test.log
end

function findArangoDBVersion
  set -xg ARANGODB_VERSION_MAJOR (grep "set(ARANGODB_VERSION_MAJOR" $WORKDIR/work/ArangoDB/CMakeLists.txt | sed -e 's/.*"\([0-9a-zA-Z]*\)".*$/\1/')
  and set -xg ARANGODB_VERSION_MINOR (grep "set(ARANGODB_VERSION_MINOR" $WORKDIR/work/ArangoDB/CMakeLists.txt | sed -e 's/.*"\([0-9a-zA-Z]*\)".*$/\1/')
  and set -xg ARANGODB_VERSION_REVISION (grep "set(ARANGODB_VERSION_REVISION" $WORKDIR/work/ArangoDB/CMakeLists.txt | sed -e 's/.*"\([0-9a-zA-Z]*\)".*$/\1/')
  and set -xg ARANGODB_PACKAGE_REVISION (grep "set(ARANGODB_PACKAGE_REVISION" $WORKDIR/work/ArangoDB/CMakeLists.txt | sed -e 's/.*"\([0-9a-zA-Z]*\)".*$/\1/')
  and set -xg ARANGODB_VERSION "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_REVISION"
  and set -xg ARANGODB_FULL_VERSION "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_REVISION-$ARANGODB_PACKAGE_REVISION"
  and echo $ARANGODB_FULL_VERSION
end

function makeRelease
  if test "$DOWNLOAD_SYNC_USER" = ""
    echo "Need to set environment variable DOWNLOAD_SYNC_USER."
    return 1
  end
  if test (count $argv) -lt 2
    findArangoDBVersion ; or return 1
  else
    set -xg ARANGODB_VERSION "$argv[1]"
    set -xg ARANGODB_PACKAGE_REVISION "$argv[2]"
    set -xg ARANGODB_FULL_VERSION "$argv[1]-$argv[2]"
  end
  maintainerOff
  releaseMode

  enterprise
  set -x NOSTRIP dont
  buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
  and downloadStarter
  and downloadSyncer
  and buildPackage

  if test $status != 0
    echo Building enterprise release failed, stopping.
    return 1
  end

  community
  buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
  and downloadStarter
  and buildPackage

  if test $status != 0
    echo Building community release failed.
    return 1
  end
end

function moveResultsToWorkspace
  # Used in jenkins test
  echo Moving reports and logs to $WORKSPACE ...
  if test -f $WORKDIR/work/test.log
    if head -1 $WORKDIR/work/test.log | grep BAD > /dev/null
      for f in $WORKDIR/work/testreport* ; echo "mv $f" ; mv $f $WORKSPACE ; end
    else
      for f in $WORKDIR/work/testreport* ; echo "rm $f" ; rm $f ; end
    end
    mv $WORKDIR/work/test.log $WORKSPACE
  end
  for x in buildArangoDB.log cmakeArangoDB.log
    if test -f "$WORKDIR/work/$x" ; mv $WORKDIR/work/$x $WORKSPACE ; end
  end

  for f in $WORKDIR/work/*.deb ; echo "mv $f" ; mv $f $WORKSPACE ; end
  for f in $WORKDIR/work/*.rpm ; echo "mv $f" ; mv $f $WORKSPACE ; end
  for f in $WORKDIR/work/*.tar.gz ; echo "mv $f" ; mv $f $WORKSPACE ; end
  if test -f $WORKDIR/work/testfailures.txt
    echo "mv $WORKDIR/work/testfailures.txt" ; mv $WORKDIR/work/testfailures.txt $WORKSPACE
  end
end

# Include the specifics for the platform
switch (uname)
  case Darwin ; source helper.mac.fish
  case Windows ; source helper.windows.fish
  case '*' ; source helper.linux.fish
end

showConfig
