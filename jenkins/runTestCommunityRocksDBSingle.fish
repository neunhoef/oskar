#!/usr/bin/fish

# This is to be run in the oskar main directory

source helper.fish
if test $status != 0
  echo Did not find fish helper functions.
  exit 1
end

lockDirectory
community
rocksdb
single
echo Hallo1
switchBranches bug-fix/static-build devel
echo Hallo2 $status
oskar1
unlockDirectory
