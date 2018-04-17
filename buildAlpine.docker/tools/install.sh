#!/bin/sh

# Install some packages:
apk update
apk add groff g++ bison flex make cmake ccache python libldap git linux-vanilla-dev linux-headers vim boost-dev ctags man gdb fish openssh db-dev libexecinfo-dev libexecinfo file libltdl zlib-dev

# Compile openssl1.1 library:
cd /tmp
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
tar xzvf openssl-1.1.0h.tar.gz
cd openssl-1.1.0h
./config --prefix=/usr no-async
make build_libs
make install_dev
cd /tmp
rm -rf openssl-1.1.0h.tar.gz openssl-1.1.0h

# Compile openldap library:
cd /tmp
wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.46.tgz
tar xzvf openldap-2.4.46.tgz
cd openldap-2.4.46
cp -a /tools/config.* ./build
./configure --prefix=/usr --enable-static
make depend && make -j64
make install
cd /tmp
rm -rf openldap-2.4.46.tgz openldap-2.4.46

# Make some warnings go away:
echo "#include <poll.h>" > /usr/include/sys/poll.h
