#!/usr/bin/fish
echo Hello there!
cd $HOME
if cd oskar ^ /dev/null ; git pull
else ; git clone https://github.com/neunhoef/oskar ; and cd oskar ; end
and source helper.fish
if test $status != 0 ; echo Did not find oskar and helpers ; exit 1 ; end

updateOskar ; lockDirectory ; clearResults

echo $EDITION $STORAGE_ENGINE $TEST_SUITE $ARANGODB_BRANCH $ENTERPRISE_BRANCH

$EDITION ; $STORAGE_ENGINE ; $TEST_SUITE

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
and oskar1

set -l s $status ; moveResultsToWorkspace ; unlockDirectory ; exit $s

