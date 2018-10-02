#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

eval $EDITION ; eval $STORAGE_ENGINE ; eval $TEST_SUITE
parallelism 20

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH true
and oskar1Limited

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory 
exit $s

