#!/usr/bin/fish
cd $HOME
if test ! -d oskar ; git clone https://github.com/neunhoef/oskar
else ; git pull ; end
cd $HOME/oskar ; source helper.fish
if test $status != 0 ; echo Did not find helpers ; exit 1 ; end

function cleanup -s TERM ; cd $HOME/oskar ; unlockDirectory ; end

updateOskar ; lockDirectory ; clearResults

community ; mmfiles ; cluster

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
and oskar1

set -l s $status ; moveResultsToWorkspace ; unlockDirectory ; exit $s

