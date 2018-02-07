#!/usr/bin/fish
cd $INNERWORKDIR/ArangoDB
set -e -x LC_ALL
set -e -x LC_CTYPE
set -e -x LANG
set -e -x LANGUAGE

and rm -rf debian
and cp -a $INNERWORKDIR/debian .
and debian/rules binary

set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
