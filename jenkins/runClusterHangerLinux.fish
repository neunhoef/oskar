#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

echo "--------------------------------------------------------------------------------"
showConfig

echo Working on branch $ARANGODB_BRANCH of main repository and
echo on branch $ENTERPRISE_BRANCH of enterprise repository.

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
or begin
  echo switchBranches error, giving up.
  unlockDirectory
  exit 1
end

enterprise ; mmfiles ; cluster

oskar1

set -l s $status
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory 
exit $s
