#!/usr/bin/env fish
#source jenkins/helper.jenkins.fish
source helper.fish
and rocksdb ; cluster ; maintainerOff ; community
#and prepareOskar; lockDirectory ; updateOskar ; clearResults

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

cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory
exit $s
