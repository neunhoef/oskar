#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

echo Working on branch $ARANGODB_BRANCH of main repository and
echo on branch $ENTERPRISE_BRANCH of enterprise repository.

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
or begin
  echo switchBranches error, giving up.
  unlockDirectory
  exit 1
end

enterprise ; rocksdb ; cluster

oskar1
or begin
  echo Errors in enterprise/rocksdb/cluster, stopping.
  moveResultsToWorkspace
  unlockDirectory
  exit 1
end
  
mv work/cmakeAlpine.log work/cmakeAlpine.log
mv work/buildAlpine.log work/buildAlpineEnterprise.log

community ; mmfiles ; single

oskar1

set -l s $status
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory 
exit $s
