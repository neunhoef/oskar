#!/usr/bin/env fish
#source helper.fish
source jenkins/helper.jenkins.fish
and prepareOskar; and lockDirectory; and updateOskar; and clearResults
and rocksdb; and cluster; and maintainerOff; and community

echo "--------------------------------------------------------------------------------"
showConfig

echo Working on branch $ARANGODB_BRANCH of main repository
and echo on branch $ENTERPRISE_BRANCH of enterprise repository.
and switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
and buildStaticArangoDB
and buildDocumentationInPr

set -l s $status
if test $s != 0
  echo Build failure with maintainer mode off in $EDITION.
end

cd "$HOME/$NODE_NAME/oskar";and  moveResultsToWorkspace; and unlockDirectory 
or echo "clean up failed"

exit $s
