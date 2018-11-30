#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults ; cleanWorkspace

set -g DOCKER_TAG $RELEASE_TAG

if test (string sub --length 1 "$RELEASE_TAG") = "v"
  set -g DOCKER_TAG (string sub --start 2 "$RELEASE_TAG")
end

community
and maintainerOff
and releaseMode
and switchBranches "$RELEASE_TAG" "$RELEASE_TAG" true
and findArangoDBVersion
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter
and makeDockerImage arangodb/arangodb-preview:$DOCKER_TAG
and docker push arangodb/arangodb-preview:$DOCKER_TAG

if test $status -ne 0
  echo Production of community image failed, giving up...
  cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
  exit 1
end

enterprise
and maintainerOff
and releaseMode
and switchBranches "$RELEASE_TAG" "$RELEASE_TAG" true
and findArangoDBVersion
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter
and downloadSyncer
and makeDockerImage registry.arangodb.biz:5000/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY
and docker push registry.arangodb.biz:5000/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:$DOCKER_TAG
and docker push registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:$DOCKER_TAG
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY registry-upload.arangodb.info/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY
and docker push registry-upload.arangodb.info/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY
and begin
  rm -rf $WORKDIR/*.docker
  echo arangodb/arangodb-preview:$DOCKER_TAG > $WORKDIR/work/arangodb3.docker
  echo registry.arangodb.com/arangodb/arangodb-preview:$DOCKER_TAG-$ENTERPRISE_DOCKER_KEY > $WORKDIR/work/arangodb3e.docker
end
and community
and buildDockerSnippet
and enterprise
and buildDockerSnippet

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
exit $s

