#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults ; cleanWorkspace

switchBranches "$RELEASE_TAG" "$RELEASE_TAG" true
and findArangoDBVersion
and test -d $WORKSPACE/release/packages
and test -d $STORAGE_PATH/$ARANGODB_PACKAGES
and tar -C $WORKSPACE/release -c -f - packages | tar -C $STORAGE_PATH/$ARANGODB_PACKAGES -x -f -

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; unlockDirectory
exit $s

