#!/bin/sh

# Set links for GCC
GCC=7

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC 10 \
	--slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-$GCC \
	--slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-$GCC \
	--slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-$GCC

update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GCC 10

update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30
update-alternatives --set cc /usr/bin/gcc

update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
update-alternatives --set c++ /usr/bin/g++

# Compile openssl1.1 library:
export OPENSSLVERSION=1.1.0h
cd /tmp
curl -O https://www.openssl.org/source/openssl-$OPENSSLVERSION.tar.gz
tar xzvf openssl-$OPENSSLVERSION.tar.gz
cd openssl-$OPENSSLVERSION
./config --prefix=/usr no-async
make
make test
make install
cd /tmp
rm -rf openssl-$OPENSSLVERSION.tar.gz openssl-$OPENSSLVERSION

# Compile openldap library:
export OPENLDAPVERSION=2.4.46
cd /tmp
curl -O ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-$OPENLDAPVERSION.tgz
tar xzvf openldap-$OPENLDAPVERSION.tgz
cd openldap-$OPENLDAPVERSION
cp -a /tools/config.* ./build
./configure --prefix=/usr --enable-static
make depend && make -j64
make install
cd /tmp
rm -rf openldap-$OPENLDAPVERSION.tgz openldap-$OPENLDAPVERSION

# clean up any strange cores
rm -rf /core.*
