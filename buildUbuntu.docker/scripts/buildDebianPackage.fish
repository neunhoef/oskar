#!/usr/bin/fish
cd $INNERWORKDIR/ArangoDB

and rm -rf debian
and cp -a $INNERWORKDIR/debian .
and debian/rules binary

set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
