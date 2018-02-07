#!/usr/bin/fish
echo Hallo1
cd $INNERWORKDIR/ArangoDB
set -e -x LC_ALL
set -e -x LC_CTYPE
set -e -x LANG
set -e -x LANGUAGE
echo Hallo2

and rm -rf debian
and echo Hallo3
and cp -a $INNERWORKDIR/debian .
and echo Hallo4
and debian/rules binary

and echo Hallo5
set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
