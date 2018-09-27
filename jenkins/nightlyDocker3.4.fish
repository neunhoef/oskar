#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

community

switchBranches 3.4 3.4 true
and findArangoDBVersion
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter
and makeDockerImage arangodb/arangodb-preview:3.4
and docker push arangodb/arangodb-preview:3.4
and docker tag arangodb/arangodb-preview:3.4 registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.4
and docker push registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.4

if test $status -ne 0
  echo Production of community image failed, giving up...
  cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
  exit 1
end

enterprise

switchBranches 3.4 3.4 true
and findArangoDBVersion
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter
and downloadSyncer
and makeDockerImage registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4-$KEY
and docker push registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4-$KEY
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4-$KEY registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.4
and docker push registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.4

and begin
  rm -rf $WORKSPACE/imagenames.log
  echo arangodb/arangodb-preview:3.4 >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.4 >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/arangodb-preview:3.4-$KEY >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.4 >> $WORKSPACE/imagenames.log
end

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
exit $s

