#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

community

switchBranches devel devel
and findArangoDBVersion
and buildStaticArangoDB
and downloadStarter
and makeDockerImage arangodb/arangodb-preview:3.4.devel
and docker push arangodb/arangodb-preview:3.4.devel
and docker tag arangodb/arangodb-preview:3.4.devel registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.4.devel
and docker push registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.4.devel

if test $status != 0
  echo Production of community image failed, giving up...
  cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory
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
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4.devel-$KEY registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.4.devel
and docker push registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.4.devel

and begin
  rm -rf $WORKSPACE/imagenames.log
  echo arangodb/arangodb-preview:3.4.devel >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.4.devel >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4.devel-$KEY >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.4.devel >> $WORKSPACE/imagenames.log
end

set -l s $status
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory
exit $s

