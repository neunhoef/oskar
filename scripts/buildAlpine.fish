#!/usr/bin/env fish
if test "$PARALLELISM" = ""
    set -xg PARALLELISM 64
end

cd $INNERWORKDIR
mkdir -p .ccache.alpine
set -x CCACHE_DIR $INNERWORKDIR/.ccache.alpine
if test "$CCACHEBINPATH" = ""
  set -xg CCACHEBINPATH /usr/lib/ccache/bin
end
ccache -M 30G

cd $INNERWORKDIR/ArangoDB
if test -z "$NO_RM_BUILD"
    rm -rf build
    mkdir -p build
end
cd build

echo cmake $argv -DCMAKE_BUILD_TYPE=$BUILDMODE -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/g++ -DCMAKE_C_COMPILER=$CCACHEBINPATH/gcc -DUSE_MAINTAINER_MODE=$MAINTAINER -DUSE_ENTERPRISE=$ENTERPRISEEDITION -DUSE_JEMALLOC=Off -DCMAKE_INSTALL_PREFIX=/ -DSTATIC_EXECUTABLES=On ..

echo cmake output in work/cmakeAlpine.log

cmake $argv \
      -DCMAKE_BUILD_TYPE=$BUILDMODE \
      -DCMAKE_CXX_COMPILER=$CCACHEBINPATH/g++ \
      -DCMAKE_C_COMPILER=$CCACHEBINPATH/gcc \
      -DUSE_MAINTAINER_MODE=$MAINTAINER \
      -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
      -DUSE_JEMALLOC=Off \
      -DCMAKE_INSTALL_PREFIX=/ \
      -DSTATIC_EXECUTABLES=On \
      .. > $INNERWORKDIR/cmakeAlpine.log ^&1

or exit $status

mkdir install
set -x DESTDIR (pwd)/install
echo Running make for static build, output in work/buildAlpine.log
nice make -j$PARALLELISM install > ../../buildAlpine.log ^&1
and cd install
and if test -z "$NOSTRIP"
  echo Stripping executables...
  strip usr/sbin/arangod usr/bin/arangoimp usr/bin/arangosh usr/bin/arangovpack usr/bin/arangoexport usr/bin/arangobench usr/bin/arangodump usr/bin/arangorestore
end
