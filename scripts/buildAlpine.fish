#!/usr/bin/env fish
if test "$PARALLELISM" = ""
    set -xg PARALLELISM 64
end
echo "Using parallelism $PARALLELISM"

cd $INNERWORKDIR
mkdir -p .ccache.alpine
set -x CCACHE_DIR $INNERWORKDIR/.ccache.alpine
if test "$CCACHEBINPATH" = ""
  set -xg CCACHEBINPATH /usr/lib/ccache/bin
end
ccache -M 30G

cd $INNERWORKDIR/ArangoDB
if test -z "$NO_RM_BUILD"
  echo "Cleaning build directory"
  rm -rf build
end
mkdir -p build
cd build

set -g FULLARGS $argv \
 -DCMAKE_BUILD_TYPE=$BUILDMODE \
 -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/g++ \
 -DCMAKE_CXX_FLAGS=-fno-stack-protector \
 -DCMAKE_C_COMPILER=$CCACHEBINPATH/gcc \
 -DCMAKE_C_FLAGS=-fno-stack-protector \
 -DCMAKE_EXE_LINKER_FLAGS=-Wl,--build-id \
 -DCMAKE_INSTALL_PREFIX=/ \
 -DSTATIC_EXECUTABLES=On \
 -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
 -DUSE_JEMALLOC=On \
 -DUSE_MAINTAINER_MODE=$MAINTAINER \

if test "$ASAN" = "On"
  echo "ASAN is not support in this environment"
end

echo cmake $FULLARGS ..
echo cmake output in $INNERWORKDIR/cmakeArangoDB.log

cmake $FULLARGS .. > $INNERWORKDIR/cmakeArangoDB.log ^&1
or exit $status

set -g MAKEFLAGS -j$PARALLELISM 
if test "$VERBOSEBUILD" = "On"
  echo "Building verbosely"
  set -g MAKEFLAGS $MAKEFLAGS V=1 VERBOSE=1 Verbose=1
end

rm -rf install
and mkdir install

set -x DESTDIR (pwd)/install
echo Running make $MAKEFLAGS for static build, output in work/buildArangoDB.log
nice make $MAKEFLAGS install > $INNERWORKDIR/buildArangoDB.log ^&1
and cd install
and if test -z "$NOSTRIP"
  echo Stripping executables...
  strip usr/sbin/arangod usr/bin/arangoimp usr/bin/arangosh usr/bin/arangovpack usr/bin/arangoexport usr/bin/arangobench usr/bin/arangodump usr/bin/arangorestore
end
