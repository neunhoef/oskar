#!/usr/bin/env fish
cd $INNERWORKDIR
mkdir -p .ccache.ubuntu
set -x CCACHE_DIR $INNERWORKDIR/.ccache.ubuntu
ccache -M 30G

cd $INNERWORKDIR/ArangoDB

rm -rf
rm -rf build
mkdir -p build
cd build

cmake -DCMAKE_BUILD_TYPE=$BUILDTYPE \
      -DCMAKE_CXX_COMPILER=/usr/lib/ccache/g++ \
      -DCMAKE_C_COMPILER=/usr/lib/ccache/gcc \
      -DUSE_MAINTAINER_MODE=$MAINTAINER \
      -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
      -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=gold \
      -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=gold \
      -DUSE_JEMALLOC=On \
      ..
and nice make -j$PARALLELISM

set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
