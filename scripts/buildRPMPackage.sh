#!/bin/sh
mkdir -p /root/{SPECS,RPMS,SRPMS,SOURCES,BUILD}
cd $INNERWORKDIR
cp $INNERWORKDIR/arangodb3.spec /root/SPECS
rpmbuild -bb /root/SPECS/arangodb3.spec
echo Sleeping
sleep 60
