#!/usr/bin/fish
cd $HOME
if test ! -d oskar ; git clone https://github.com/neunhoef/oskar
else ; git pull ; end
cd $HOME/oskar ; source helper.fish
if test $status != 0 ; echo Did not find helpers ; exit 1 ; end

updateOskar ; lockDirectory ; clearResults

community ; rocksdb ; single

switchBranches devel devel
and oskar1

set -l s $status ; moveResultsToWorkspace ; unlockDirectory ; exit $s

