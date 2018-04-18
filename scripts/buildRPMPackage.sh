#!/bin/sh
mkdir -p /root/SPECS
cd $INNERWORKDIR
cp arangodb3.spec /root/SPECS
cp arangodb3.initd arangodb3.service arangodb3.logrotate $INNERWORKDIR/ArangoDB/build/install/usr/share/arangodb3
rpmbuild -bb /root/SPECS/arangodb3.spec
cp /root/rpmbuild/RPMS/*/*.rpm $INNERWORKDIR
chown -R $UID.$GID $INNERWORKDIR
echo Sleeping
sleep 180
