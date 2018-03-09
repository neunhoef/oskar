#!/usr/bin/env fish
mkdir -p "$HOME/$NODE_NAME" ; cd "$HOME/$NODE_NAME"
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
and docker tag arangodb/arangodb-preview:3.3 registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.3
and docker push registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.3
and docker tag arangodb/arangodb-preview:3.3 arangodb/arangodb-preview:latest
and docker push arangodb/arangodb-preview:latest

if test $status != 0
  echo Production of community image failed, giving up...
  cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory
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
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.3
and docker push registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.3
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY registry.arangodb.biz:5000/arangodb/arangodb-preview:latest-$KEY
and docker push registry.arangodb.biz:5000/arangodb/arangodb-preview:latest-$KEY

and begin
  rm -rf $WORKSPACE/imagenames.log
  echo arangodb/arangodb-preview:3.3 >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.3 >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.3 >> $WORKSPACE/imagenames.log
end

set -l s $status
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory
exit $s

