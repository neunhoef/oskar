function lockDirectory
  # Now grab the lock ourselves:
  set -l pid (echo %self)
  if test ! -f LOCK.$pid
    echo $pid > LOCK.$pid
    while true
      # Remove a stale lock if it is found:
      if set -l pidfound (cat LOCK ^/dev/null)
        if not ps ax -o pid | grep $pidfound > /dev/null
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

function single ; set -g TESTSUITE single ; end
function cluster ; set -g TESTSUITE cluster ; end
function resilience ; set -g TESTSUITE resilience ; end
if test -z "$TESTSUITE" ; set -g TESTSUITE cluster ; end

function maintainerOn ; set -g MAINTAINER On ; end
function maintainerOff ; set -g MAINTAINER Off ; end
if test -z "$MAINTAINER" ; set -g MAINTAINER On ; end

function debugMode ; set -g BUILDMODE Debug ; end
function releaseMode ; set -g BUILDMODE RelWithDebInfo ; end
if test -z "$BUILDMODE" ; set -g BUILDMODE RelWithDebInfo ; end

function community ; set -g ENTERPRISEEDITION Off ; end
function enterprise ; set -g ENTERPRISEEDITION On ; end
if test -z "$ENTERPRISEEDITION" ; set -g ENTERPRISEEDITION On ; end

function mmfiles ; set -g STORAGEENGINE mmfiles ; end
function rocksdb ; set -g STORAGEENGINE rocksdb ; end
if test -z "$STORAGEENGINE" ; set -g STORAGEENGINE rocksdb ; end

function parallelism ; set -g PARALLELISM $argv[1] ; end
if test -z "$PARALLELISM" ; set -g PARALLELISM 64 ; end

function verbose ; set -g VERBOSEOSKAR On ; end
function silent ; set -g VERBOSEOSKAR Off ; end

set -g WORKDIR (pwd)
if test ! -d work ; mkdir work ; end
set -g VERBOSEOSKAR Off

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
  rm -f test.log
end

function oskar1
  showConfig
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  oskar
end

function oskar2
  showConfig
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster
end

function oskar4
  showConfig
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
  set -l v VERSION
  if test (count $argv) = 0
    findArangoDBVersion ; or return 1
    set v $ARANGODB_FULL_VERSION 
  else
    set v "$argv[1]"
  end
  maintainerOff
  releaseMode

  enterprise
  buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
  and downloadStarter
  and downloadSyncer
  and buildPackage $v

  if test $status != 0
    echo Building enterprise release failed, stopping.
    return 1
  end

  community
  buildStaticArangoDB _DTARGET_ARCHITECTURE=nehalem
  and downloadStarter
  and buildPackage $v

  if test $status != 0
    echo Building community release failed.
    return 1
  end
end

function moveResultsToWorkspace
  # Used in jenkins test
  echo Moving reports and logs to $WORKSPACE ...
  for f in work/testreport* ; mv $f $WORKSPACE ; end
  for f in work/*.deb ; mv $f $WORKSPACE ; end
  if test -f work/test.log ; mv work/test.log $WORKSPACE ; end
end

# Include the specifics for the platform
switch (uname)
  case Darwin ; source helper.mac.fish
  case '*' ; source helper.linux.fish
end

showConfig
