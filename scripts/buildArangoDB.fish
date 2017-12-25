#!/usr/bin/fish
cd /ArangoDB
if test ! -d build
  mkdir build
end
cd build
cmake -DCMAKE_BUILD_TYPE=$BUILDTYPE \
      -DCMAKE_CXX_COMPILER=/usr/lib/ccache/g++ \
      -DCMAKE_C_COMPILER=/usr/lib/ccache/gcc \
      -DUSE_MAINTAINER_MODE=$MAINTAINER \
      -DCMAKE_BUILD_TYPE=$BUILDTYPE \
      -DUSE_ENTERPRISE=$ENTERPRISEEDITION \
      ..
make -j$PARALLELISM
