#!/usr/bin/fish

echo Hello, syncer here, arguments are: $argv

if test -z "$DOWNLOAD_SYNC_USER"
  echo Need DOWNLOAD_SYNC_USER environment variable set!
  exit 1
end

if test (count $argv) = 0
  eval "set "(grep SYNCER_REV $INNERWORKDIR/ArangoDB/VERSIONS)
else
  set SYNCER_REV "$argv[1]"
end

echo Using DOWNLOAD_SYNC_USER "$DOWNLOAD_SYNC_USER"
echo Using SYNCER_REV "$SYNCER_REV"

# First find the assets and linux executable:
set -l meta (curl -s -L https://$DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/tags/$SYNCER_REV)
if test $status != 0
  echo Finding download asset failed
  exit 1
end

echo $meta > $INNERWORKDIR/assets.json

set -l asset_id (echo $meta | jq ".assets | map(select(.name == \"arangosync-linux-amd64\"))[0].id")
if test $status = 0
  echo Downloaded JSON cannot be parsed
  exit 1
end
echo Downloading: Asset with ID $asset_id

curl -L -H "Accept: application/octet-stream" "https://$DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/assets/$asset_id" -o "$INNERWORKDIR/ArangoDB/build/install/usr/bin/arangosync"

and chmod 755 "$INNERWORKDIR/ArangoDB/build/install/usr/bin/arangosync"

set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
