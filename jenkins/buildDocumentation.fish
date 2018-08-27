#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults
rocksdb ; cluster ; maintainerOff, community

echo "--------------------------------------------------------------------------------"
showConfig

echo Working on branch $ARANGODB_BRANCH of main repository and
echo on branch $ENTERPRISE_BRANCH of enterprise repository.

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
and buildDocumentationInPr

set -l s $status
if test $s != 0
  echo Build failure with maintainer mode off in $EDITION.
end
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory 
exit $s
