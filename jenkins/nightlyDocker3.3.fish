#!/usr/bin/env fish
mkdir -p "$HOME/x$NODE_NAME" ; cd "$HOME/x$NODE_NAME"
if not cd oskar ^ /dev/null 
  git clone https://github.com/neunhoef/oskar ; and cd oskar
end
and source helper.fish
if test $status != 0 ; echo Did not find oskar and helpers ; exit 1 ; end

lockDirectory ; updateOskar ; clearResults

community

switchBranches 3.3 3.3
and findArangoDBVersion
and buildStaticArangoDB
and downloadStarter
and makeDockerImage arangodb/arangodb-preview:3.3
and docker push arangodb/arangodb-preview:3.3

if test $status != 0
  echo Production of community image failed, giving up...
  exit 1
end

enterprise

switchBranches 3.3 3.3
and findArangoDBVersion
and buildStaticArangoDB
and downloadStarter
and downloadSyncer
and makeDockerImage registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY
and docker push registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY

set -l s $status ; unlockDirectory ; exit $s

