#!/bin/sh
mkdir -p /root/SPECS
mkdir -p /root/RPMS
mkdir -p /root/SRPMS
mkdir -p /root/SOURCES
mkdir -p /root/BUILD
cd $INNERWORKDIR
cp arangodb3.spec /root/SPECS
cp arangodb3.initd arangodb3.service arangodb3.logrotate $INNERWORKDIR/ArangoDB/build/install/usr/share/arangodb3
rpmbuild -bb /root/SPECS/arangodb3.spec
echo Sleeping
sleep 60
