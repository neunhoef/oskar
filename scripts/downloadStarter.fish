#!/usr/bin/env fish

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
if test "$STARTER_REV" = latest
  set -l meta (curl -s -L "https://api.github.com/repos/arangodb-helper/arangodb/releases/latest")
  or begin ; echo "Finding download asset failed for latest" ; exit 1 ; end
  set STARTER_REV (echo $meta | jq -r ".name")
  or begin ; echo "Could not parse downloaded JSON" ; exit 1 ; end
end
echo Using STARTER_REV "$STARTER_REV"

set -l STARTER_PATH $INNERWORKDIR/ArangoDB/build/install/usr/bin/arangodb
curl -s -L -o "$STARTER_PATH" "https://github.com/arangodb-helper/arangodb/releases/download/$STARTER_REV/arangodb-$PLATFORM-amd64"

and chmod 755 "STARTERPATH"
and echo Starter ready for build $STARTERPATH
