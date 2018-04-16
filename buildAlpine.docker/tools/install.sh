#!/bin/sh

# Install some packages:
apk update
apk add groff g++ bison flex make cmake ccache python libldap openssl-dev git linux-vanilla-dev linux-headers vim boost-dev ctags man gdb fish openssh db-dev libexecinfo-dev libexecinfo

# Compile openldap library:
export OPENLDAP_VERSION=2.4.46
cd /tmp
wget ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-$OPENLDAP_VERSION.tgz
tar xzvf openldap-$OPENLDAP_VERSION.tgz
cd openldap-$OPENLDAP_VERSION
cp -a /tools/config.* ./build
./configure --prefix=/usr --enable-static
make depend && make -j64
make install
cd /tmp
rm -rf openldap-$OPENLDAP_VERSION.tgz openldap-$OPENLDAP_VERSION

# Make some warnings go away:
echo "#include <poll.h>" > /usr/include/sys/poll.h
