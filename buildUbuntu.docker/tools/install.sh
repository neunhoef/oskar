#!/bin/sh

# Compile openssl1.1 library:
cd /tmp
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
