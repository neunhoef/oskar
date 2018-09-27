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
  echo "#################################"
  echo "Build Configuration"
  echo "- Enterprise     : $ENTERPRISEEDITION"
  echo "- Buildmode      : $BUILDMODE"
  echo "- Maintainer     : $MAINTAINER"
  echo "- ASAN:          : $ASAN"

  if test -z "$NO_RM_BUILD"
    echo "- Clear build    : On"
  else
    echo "- Clear build    : Off"
  end
  
  echo
  echo "Test Configuration:"
  echo "- Storage engine : $STORAGEENGINE"
  echo "- Test suite     : $TESTSUITE"
  echo
  echo "Internal Configuration:"
  echo "- Workdir        : $WORKDIR"
  echo "- Inner workdir  : $INNERWORKDIR"
  echo "- Parallelism    : $PARALLELISM"
  echo "- Verbose Build  : $VERBOSEBUILD"
  echo "- Verbose Oskar  : $VERBOSEOSKAR"
  echo "#################################"
  echo
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

function asanOn ; set -gx ASAN On ; end
function asanOff ; set -gx ASAN Off ; end
if test -z "$ASAN" ; asanOff
else ; set -gx ASAN $ASAN ; end

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

function verbose ; set -gx VERBOSEOSKAR On ; end
function silent ; set -gx VERBOSEOSKAR Off ; end
if test -z "$VERBOSEOSKAR" ; verbose
else ; set -gx VERBOSEOSKAR $VERBOSEOSKAR ; end

function verboseBuild ; set -gx VERBOSEBUILD On ; end
function silentBuild ; set -gx VERBOSEBUILD Off ; end
if test -z "$VERBOSEBUILD"; silentBuild
else ; set -gx VERBOSEBUILD $VERBOSEBUILD ; end

function keepBuild ; set -gx NO_RM_BUILD 1 ; end
function clearBuild ; set -gx NO_RM_BUILD ; end

# TODO FIXME
# main code between function definitions
# WORDIR IS pdw -  at least check if ./scripts and something
# else is available before proceeding
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

function oskar1Full
  showConfig
  set -x NOSTRIP 1
  buildStaticArangoDB -DUSE_FAILURE_TESTS=On -DDEBUG_SYNC_REPLICATION=On ; or return $status
  oskarFull
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
  set -l CMAKELIST "$WORKDIR/work/ArangoDB/CMakeLists.txt"
  set -l AV "set(ARANGODB_VERSION"
  set -l APR "set(ARANGODB_PACKAGE_REVISION"
  set -l SEDFIX 's/.*"\([0-9a-zA-Z]*\)".*$/\1/'

  set -xg ARANGODB_VERSION_MAJOR (grep "$AV""_MAJOR" $CMAKELIST | sed -e $SEDFIX)
  set -xg ARANGODB_VERSION_MINOR (grep "$AV""_MINOR" $CMAKELIST | sed -e $SEDFIX)

  set -xg ARANGODB_SNIPLETS "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR"

  # old version scheme (upto 3.3.x)
  if grep -q "$APR" $CMAKELIST
    set -xg ARANGODB_VERSION_PATCH (grep "$AV""_REVISION" $CMAKELIST | sed -e $SEDFIX)
    set -l  ARANGODB_PACKAGE_REVISION (grep "$APR" $CMAKELIST | sed -e $SEDFIX)

    set -xg ARANGODB_VERSION "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"

    set -xg ARANGODB_DEBIAN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
    set -xg ARANGODB_DEBIAN_REVISION "$ARANGODB_PACKAGE_REVISION"

    set -xg ARANGODB_RPM_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
    set -xg ARANGODB_RPM_REVISION "$ARANGODB_PACKAGE_REVISION"

    set -xg ARANGODB_DARWIN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
    set -xg ARANGODB_DARWIN_REVISION "$ARANGODB_PACKAGE_REVISION"

    set -xg ARANGODB_TGZ_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"

  # new version scheme (from 3.4.x)  
  else
    set -xg ARANGODB_VERSION_PATCH (grep "$AV""_PATCH" $CMAKELIST | grep -v unset | sed -e $SEDFIX)
    set -l  ARANGODB_VERSION_RELEASE_TYPE (grep "$AV""_RELEASE_TYPE" $CMAKELIST | grep -v unset | sed -e $SEDFIX)
    set -l  ARANGODB_VERSION_RELEASE_NUMBER (grep "$AV""_RELEASE_NUMBER" $CMAKELIST | grep -v unset | sed -e $SEDFIX)

    # stable release, devel or nightly
    if test "$ARANGODB_VERSION_RELEASE_TYPE" = ""
      set -xg ARANGODB_VERSION "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"

      set -xg ARANGODB_DARWIN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
      set -xg ARANGODB_DARWIN_REVISION ""

      set -xg ARANGODB_TGZ_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"

      # devel or nightly
      if test "$ARANGODB_VERSION_PATCH" = "devel" \
           -o "$ARANGODB_VERSION_PATCH" = "nightly"
        set -xg ARANGODB_DEBIAN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.0~~$ARANGODB_VERSION_PATCH"
        set -xg ARANGODB_DEBIAN_REVISION "1"

        if test "$ARANGODB_VERSION_PATCH" = "devel"
          set -xg ARANGODB_RPM_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.0"
          set -xg ARANGODB_RPM_REVISION "0.1"
        else if test "$ARANGODB_VERSION_PATCH" = "nightly"
          set -xg ARANGODB_RPM_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.0"
          set -xg ARANGODB_RPM_REVISION "0.2"
	end

      # stable release
      else
        set -xg ARANGODB_DEBIAN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
        set -xg ARANGODB_DEBIAN_REVISION "1"

        set -xg ARANGODB_RPM_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
        set -xg ARANGODB_RPM_REVISION "1.0"
      end

    # unstable release
    else if test "$ARANGODB_VERSION_RELEASE_TYPE" = "alpha" \
              -o "$ARANGODB_VERSION_RELEASE_TYPE" = "beta" \
              -o "$ARANGODB_VERSION_RELEASE_TYPE" = "milestone" \
              -o "$ARANGODB_VERSION_RELEASE_TYPE" = "preview" \
              -o "$ARANGODB_VERSION_RELEASE_TYPE" = "rc"
      if test "$ARANGODB_VERSION_RELEASE_NUMBER" = ""
        echo "ERROR: missing ARANGODB_VERSION_RELEASE_NUMBER for type $ARANGODB_VERSION_RELEASE_TYPE"
        return
      end

      if test "$ARANGODB_VERSION_RELEASE_TYPE" = "alpha"
        set N 100
      else if test "$ARANGODB_VERSION_RELEASE_TYPE" = "beta"
        set N 200
      else if test "$ARANGODB_VERSION_RELEASE_TYPE" = "milestone"
        set N 300
      else if test "$ARANGODB_VERSION_RELEASE_TYPE" = "preview"
        set N 400
      else if test "$ARANGODB_VERSION_RELEASE_TYPE" = "rc"
        set N 500
      end

      set -xg ARANGODB_VERSION "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH-$ARANGODB_VERSION_RELEASE_TYPE.$ARANGODB_VERSION_RELEASE_NUMBER"

      set -xg ARANGODB_DEBIAN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH~$ARANGODB_VERSION_RELEASE_TYPE.$ARANGODB_VERSION_RELEASE_NUMBER"
      set -xg ARANGODB_DEBIAN_REVISION "1"

      set -xg ARANGODB_RPM_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
      set -xg ARANGODB_RPM_REVISION "0."(expr $N + $ARANGODB_VERSION_RELEASE_NUMBER)".$ARANGODB_VERSION_RELEASE_TYPE$ARANGODB_VERSION_RELEASE_NUMBER"

      set -xg ARANGODB_DARWIN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
      set -xg ARANGODB_DARWIN_REVISION "$ARANGODB_VERSION_RELEASE_TYPE.$ARANGODB_VERSION_RELEASE_NUMBER"

      set -xg ARANGODB_TGZ_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH-$ARANGODB_VERSION_RELEASE_TYPE.$ARANGODB_VERSION_RELEASE_NUMBER"

    # hot-fix
    else
      if test "$ARANGODB_VERSION_RELEASE_NUMBER" != ""
        echo "ERROR: ARANGODB_VERSION_RELEASE_NUMBER ($ARANGODB_VERSION_RELEASE_NUMBER) must be empty for type $ARANGODB_VERSION_RELEASE_TYPE"
        return
      end

      set -xg ARANGODB_VERSION "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH-$ARANGODB_VERSION_RELEASE_TYPE"

      set -xg ARANGODB_DEBIAN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH.$ARANGODB_VERSION_RELEASE_TYPE"
      set -xg ARANGODB_DEBIAN_REVISION "1"

      set -xg ARANGODB_RPM_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH"
      set -xg ARANGODB_RPM_REVISION "1.$ARANGODB_VERSION_RELEASE_TYPE"

      set -xg ARANGODB_DARWIN_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH.$ARANGODB_VERSION_RELEASE_TYPE"
      set -xg ARANGODB_DARWIN_REVISION ""

      set -xg ARANGODB_TGZ_UPSTREAM "$ARANGODB_VERSION_MAJOR.$ARANGODB_VERSION_MINOR.$ARANGODB_VERSION_PATCH-$ARANGODB_VERSION_RELEASE_TYPE"
    end
  end

  echo "ArangoDB: $ARANGODB_VERSION"
  echo "Debian:   $ARANGODB_DEBIAN_UPSTREAM / $ARANGODB_DEBIAN_REVISION"
  echo "RPM:      $ARANGODB_RPM_UPSTREAM / $ARANGODB_RPM_REVISION"
  echo "DARWIN:   $ARANGODB_DARWIN_UPSTREAM / $ARANGODB_DARWIN_REVISION"
  echo "TGZ:      $ARANGODB_TGZ_UPSTREAM"
  echo "SNIPLETS: $ARANGODB_SNIPLETS"
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

  buildEnterprisePackage
  and buildCommunityPackage
end

function buildTarGzPackageHelper
  set -l os "$argv[1]"

  if test -z "$os"
    echo "need operating system as first argument"
    return 1
  end

  # This assumes that a static build has already happened
  # Must have set ARANGODB_TGZ_UPSTREAM
  # for example by running findArangoDBVersion.
  set -l v "$ARANGODB_TGZ_UPSTREAM"
  set -l name

  if test "$ENTERPRISEEDITION" = "On"
    set name arangodb3e
  else
    set name arangodb3
  end

  cd $WORKDIR
  and cd $WORKDIR/work/ArangoDB/build/install
  and rm -rf bin
  and cp -a $WORKDIR/binForTarGz bin
  and rm -f "bin/*~" "bin/*.bak"
  and mv bin/README .
  and strip usr/sbin/arangod usr/bin/{arangobench,arangodump,arangoexport,arangoimp,arangorestore,arangosh,arangovpack}
  and cd $WORKDIR/work/ArangoDB/build
  and mv install "$name-$v"
  or begin ; cd $WORKDIR ; return 1 ; end

  tar -c -z -v -f "$WORKDIR/work/$name-$os-$v.tar.gz" --exclude "etc" --exclude "var" "$name-$v"
  set s $status
  mv "$name-$v" install
  cd $WORKDIR
  return $s 
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
  for f in $WORKDIR/work/*.dmg ; echo "mv $f" ; mv $f $WORKSPACE ; end
  for f in $WORKDIR/work/*.rpm ; echo "mv $f" ; mv $f $WORKSPACE ; end
  for f in $WORKDIR/work/*.tar.gz ; echo "mv $f" ; mv $f $WORKSPACE ; end

  if test -f $WORKDIR/work/testfailures.txt
    if grep -q -v '^[ \t]*$' $WORKDIR/work/testfailures.txt
      echo "mv $WORKDIR/work/testfailures.txt" ; mv $WORKDIR/work/testfailures.txt $WORKSPACE
    end
  end
end

# Include the specifics for the platform
switch (uname)
  case Darwin ; source helper.mac.fish
  case Windows ; source helper.windows.fish
  case '*' ; source helper.linux.fish
end

showConfig
