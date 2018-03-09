#!/usr/bin/env fish
mkdir -p "$HOME/$NODE_NAME" ; cd "$HOME/$NODE_NAME"
if not cd oskar ^ /dev/null 
  git clone https://github.com/neunhoef/oskar ; and cd oskar
end
and source helper.fish
if test $status != 0 ; echo Did not find oskar and helpers ; exit 1 ; end

lockDirectory ; updateOskar ; clearResults

eval $EDITION ; eval $STORAGE_ENGINE ; eval $TEST_SUITE

echo Working on branch $ARANGODB_BRANCH of main repository and
echo on branch $ENTERPRISE_BRANCH of enterprise repository.

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
and oskar1

set -l s $status
cd "$HOME/$NODE_NAME/oskar" ; moveResultsToWorkspace ; unlockDirectory 
exit $s

