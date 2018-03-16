#!/bin/sh

# Install some packages:
apk update
apk add groff g++ bison flex make cmake ccache python libldap openssl-dev git linux-vanilla-dev linux-headers vim boost-dev ctags man gdb fish openssh db-dev libexecinfo-dev libexecinfo

# Compile openldap library:
cd /tmp
wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.45.tgz
tar xzvf openldap-2.4.45.tgz
cd openldap-2.4.45
cp -a /tools/config.* .
./configure --prefix=/usr --enable-static
make depend && make -j64
make install
cd /tmp
rm -rf openldap-2.4.45.tgz openldap-2.4.45

# Make some warnings go away:
echo "#include <poll.h>" > /usr/include/sys/poll.h
