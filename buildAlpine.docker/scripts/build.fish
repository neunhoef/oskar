#!/usr/bin/fish
date > /tmp/usedstamp
if test $PARALLELISM = ""
    set -x PARALLELISM 64
end

cd $INNERWORKDIR
mkdir -p .ccache.alpine
set -x CCACHE_DIR $INNERWORKDIR/.ccache.alpine
ccache -M 30G

cd $INNERWORKDIR/ArangoDB
rm -rf build
mkdir -p build
cd build

cmake $argv \
      -DCMAKE_BUILD_TYPE=$BUILDTYPE \
      -DCMAKE_CXX_COMPILER=/usr/lib/ccache/bin/g++ \
      -DCMAKE_C_COMPILER=/usr/lib/ccache/bin/gcc \
      -DUSE_MAINTAINER_MODE=$MAINTAINER \
      -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
      -DUSE_JEMALLOC=Off \
      -DSTATIC_EXECUTABLES=On \
      ..
nice make -j$PARALLELISM
mkdir install
set -x DESTDIR (pwd)/install
make install
cd install
tar czvf ../install.tar.gz *
cd $INNERWORKDIR/ArangoDB/build
rm -rf install
chown -R $UID:$GID $INNERWORKDIR
