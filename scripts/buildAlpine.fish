#!/usr/bin/env fish
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
      -DCMAKE_INSTALL_PREFIX=/ \
      -DSTATIC_EXECUTABLES=On \
      ..
set -l s $status
if test $status != 0
  chown -R $UID:$GID $INNERWORKDIR
  exit $s
end

mkdir install
set -x DESTDIR (pwd)/install
nice make -j$PARALLELISM install
and cd install
and if test -z "$NOSTRIP"
  strip usr/sbin/arangod usr/bin/arangoimp usr/bin/arangosh usr/bin/arangovpack usr/bin/arangoexport usr/bin/arangobench usr/bin/arangodump usr/bin/arangorestore
end

set -l s $status
cd $INNERWORKDIR/ArangoDB/build
chown -R $UID:$GID $INNERWORKDIR
exit $s

