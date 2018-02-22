#!/usr/bin/env fish
mkdir -p "$HOME/$NODE_NAME" ; cd "$HOME/$NODE_NAME"
if not cd oskar ^ /dev/null 
  git clone https://github.com/neunhoef/oskar ; and cd oskar
end
and source helper.fish
if test $status != 0 ; echo Did not find oskar and helpers ; exit 1 ; end

lockDirectory ; updateOskar ; clearResults

community

switchBranches devel devel
and findArangoDBVersion
and buildStaticArangoDB
and downloadStarter
and makeDockerImage arangodb/arangodb-preview:3.4.devel
and docker push arangodb/arangodb-preview:3.4.devel

if test $status != 0
  echo Production of community image failed, giving up...
  exit 1
end

enterprise

switchBranches devel devel
and findArangoDBVersion
and buildStaticArangoDB
and downloadStarter
and downloadSyncer
and makeDockerImage registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4.devel-$KEY
and docker push registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4.devel-$KEY

and begin
  rm -rf $WORKSPACE/imagenames.log
  echo arangodb/arangodb-preview:3.4.devel >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4.devel-$KEY >> $WORKSPACE/imagenames.log
end

set -l s $status ; unlockDirectory ; exit $s

