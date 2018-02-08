#!/usr/bin/fish

if test "$argv[1]" = ""
  echo Need DOWNLOAD_SYNC_USER as first argument!
  return 1
end
set -l DOWNLOAD_SYNC_USER "$argv[1]"

if test "$argv[2]" = ""
  eval "set "(grep SYNCER_REV $WORKDIR/work/ArangoDB/VERSIONS)
else
  set SYNCER_REV "$argv[2]"
end

echo Using DOWNLOAD_SYNC_USER "$DOWNLOAD_SYNC_USER"
echo Using SYNCER_REV "$SYNCER_REV"

# First find the assets and linux executable:
set -l meta (curl -s -L https://$DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/tags/$SYNCER_REV)
set -l s $status
if test ! "$s" = 0
  echo Finding download asset failed
  exit $s
end

set -l asset_id (echo $meta | jq ".assets | map(select(.name == \"arangosync-linux-amd64\"))[0].id")
echo Downloading: Asset with ID $asset_id

curl -L -H "Accept: application/octet-stream" "https://$DOWNLOAD_SYNC_USER@api.github.com/repos/arangodb/arangosync/releases/assets/$asset_id" -o "$INNERWORKDIR/ArangoDB/build/install/usr/bin/arangosync"

and chmod 755 "$INNERWORKDIR/ArangoDB/build/install/usr/bin/arangosync"

set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
