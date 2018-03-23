#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

enterprise ; rocksdb ; cluster ; maintainerOff

echo Working on branch $ARANGODB_BRANCH of main repository and
echo on branch $ENTERPRISE_BRANCH of enterprise repository.

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
and buildStaticArangoDB
or begin
  echo Build failure with maintainer mode off in enterprise.
  moveResultsToWorkspace ; unlockDirectory
  exit 1
end

cd $WORKDIR/work
mv cmakeArangoDB.log cmakeArangoDBEnterprise.log
mv buildArangoDB.log buildArangoDBEnterprise.log

community
buildStaticArangoDB

set -l s $status
if test $s != 0
  echo Build failure with maintainer mode off in community.
end
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory 
exit $s

