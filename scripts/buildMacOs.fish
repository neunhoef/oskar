#!/usr/bin/env fish
set TS (which ts; and echo -- -s [\\%.T]; or echo /bin/cat)

if test "$PARALLELISM" = ""
    set -xg PARALLELISM 64
end
echo "Using parallelism $PARALLELISM"

cd $INNERWORKDIR
mkdir -p .ccache.mac
set -x CCACHE_DIR $INNERWORKDIR/.ccache.mac
if test "$CCACHEBINPATH" = ""
  set -xg CCACHEBINPATH /usr/lib/ccache
end
ccache -M 100G
#ccache -o log_file=$INNERWORKDIR/.ccache.log
ccache -o cache_dir_levels=1
cd $INNERWORKDIR/ArangoDB

if test -z "$NO_RM_BUILD"
  echo "Cleaning build directory"
  rm -rf build
end

echo "Starting build at "(date)" on "(hostname)
test -f $INNERWORKDIR/.ccache.mac.log 
or mv $INNERWORKDIR/.ccache.log $INNERWORKDIR/.ccache.mac.log.old
ccache --zero-stats

rm -rf build
mkdir -p build
cd build

echo "Starting build at "(date)" on "(hostname)
rm -f $INNERWORKDIR/.ccache.log
ccache --zero-stats

set -g FULLARGS $argv \
      -DCMAKE_BUILD_TYPE=$BUILDMODE \
      -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/g++ \
      -DCMAKE_C_COMPILER=$CCACHEBINPATH/gcc \
      -DUSE_MAINTAINER_MODE=$MAINTAINER \
      -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
      -DUSE_JEMALLOC=Off \
      -DCMAKE_SKIP_RPATH=On \
      -DPACKAGING=Bundle \
      -DPACKAGE_TARGET_DIR=$INNERWORKDIR \
      -DOPENSSL_USE_STATIC_LIBS=On

if test "$ASAN" = "On"
  echo "ASAN is not support in this environment"
end

echo cmake $FULLARGS ..
echo cmake output in $INNERWORKDIR/cmakeArangoDB.log

cmake $FULLARGS .. ^&1 | eval $TS > $INNERWORKDIR/cmakeArangoDB.log
or exit $status

echo "Finished cmake at "(date)", now starting build"

set -g MAKEFLAGS -j$PARALLELISM 
if test "$VERBOSEBUILD" = "On"
  echo "Building verbosely"
  set -g MAKEFLAGS $MAKEFLAGS V=1 VERBOSE=1 Verbose=1
end

and echo Running make, output in $INNERWORKDIR/buildArangoDB.log
and nice make -j$MAKEFALGS ^&1 | eval $TS > $INNERWORKDIR/buildArangoDB.log

echo "Finished at "(date)
ccache --show-stats
