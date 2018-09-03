#!/usr/bin/env fish
set TS (which ts; and echo -- -s [\\%.T]; or echo /usr/bin/env cat)

cd $INNERWORKDIR
mkdir -p .ccache.mac
set -x CCACHE_DIR $INNERWORKDIR/.ccache.mac
if test "$CCACHEBINPATH" = ""
  set -xg CCACHEBINPATH /usr/lib/ccache
end
ccache -M 100G
#ccache -o log_file=$INNERWORKDIR/.ccache.mac.log
ccache -o cache_dir_levels=1
cd $INNERWORKDIR/ArangoDB

echo "Starting build at "(date)" on "(hostname)
test -f $INNERWORKDIR/.ccache.mac.log 
and mv $INNERWORKDIR/.ccache.mac.log $INNERWORKDIR/.ccache.mac.log.old
ccache --zero-stats

rm -rf build
mkdir -p build
cd build

echo cmake $argv -DCMAKE_BUILD_TYPE=$BUILDMODE -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/g++ -DCMAKE_C_COMPILER=$CCACHEBINPATH/gcc -DUSE_MAINTAINER_MODE=$MAINTAINER -DUSE_ENTERPRISE=$ENTERPRISEEDITION -DUSE_JEMALLOC=Off -DCMAKE_SKIP_RPATH=On -DOPENSSL_USE_STATIC_LIBS=On ..

echo cmake output in $INNERWORKDIR/cmakeArangoDB.log

cmake $argv \
      -DCMAKE_BUILD_TYPE=$BUILDMODE \
      -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/g++ \
      -DCMAKE_C_COMPILER=$CCACHEBINPATH/gcc \
      -DUSE_MAINTAINER_MODE=$MAINTAINER \
      -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
      -DUSE_JEMALLOC=Off \
      -DCMAKE_SKIP_RPATH=On \
      -DOPENSSL_USE_STATIC_LIBS=On \
      .. ^&1 | eval $TS > $INNERWORKDIR/cmakeArangoDB.log
and echo "Finished cmake at "(date)", now starting build"
and echo Running make, output in $INNERWORKDIR/buildArangoDB.log
and nice make -j$PARALLELISM ^&1 | eval $TS > $INNERWORKDIR/buildArangoDB.log
and echo "Finished at "(date)
and ccache --show-stats
