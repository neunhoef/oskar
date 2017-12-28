#!/usr/bin/fish
cd /work/ArangoDB
if test ! -d build
  mkdir build
end
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
nice make -j$PARALLELISM
