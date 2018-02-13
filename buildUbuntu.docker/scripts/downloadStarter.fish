#!/usr/bin/fish

set -l STARTER_REV

if test "$argv[1]" = ""
  if test -f $INNERWORKDIR/ArangoDB/STARTER_REV
    set STARTER_REV (cat $INNERWORKDIR/ArangoDB/STARTER_REV)
  else
    eval "set "(grep STARTER_REV $INNERWORKDIR/ArangoDB/VERSIONS)
  end
else
  set STARTER_REV "$argv[1]"
end
echo Using STARTER_REV "$STARTER_REV"

curl -s -L -o "$INNERWORKDIR/ArangoDB/build/install/usr/bin/arangodb" "https://github.com/arangodb-helper/arangodb/releases/download/$STARTER_REV/arangodb-linux-amd64"

and chmod 755 "$INNERWORKDIR/ArangoDB/build/install/usr/bin/arangodb"

set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
