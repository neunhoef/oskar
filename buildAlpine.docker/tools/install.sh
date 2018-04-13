#!/bin/sh

# Install some packages:
apk update
apk add groff g++ bison flex make cmake ccache python libldap openssl-dev git linux-vanilla-dev linux-headers vim boost-dev ctags man gdb fish openssh db-dev libexecinfo-dev libexecinfo

# Compile openldap library:
cd /tmp
wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.45.tgz
tar xzvf openldap-2.4.45.tgz
cd openldap-2.4.45
cp -a /tools/config.* ./build
./configure --prefix=/usr --enable-static
make depend && make -j64
make install
cd /tmp
rm -rf openldap-2.4.45.tgz openldap-2.4.45

# Compile openssl1.1 library:
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
tar xzvf openssl-1.1.0h.tar.gz
cd openssl-1.1.0h
./config
make
make test
make install
cd /tmp
rm -rf openssl-1.1.0h.tar.gz openssl-1.1.0h

# Make some warnings go away:
echo "#include <poll.h>" > /usr/include/sys/poll.h
