#!/usr/bin/fish

# This is to be run in the oskar main directory

source helper.fish
if test $status != 0
  echo Did not find fish helper functions.
  exit 1
end

pullUbuntuBuildImage

lockDirectory

clearResults

community
rocksdb
cluster
switchBranches devel devel
and oskar1

set -l s $status
if test $s != 0
  for f in work/testresult* ; mv $f $WORKSPACE ; end
  if test -f work/test.log ; mv work/test.log $WORKSPACE ; end
end

unlockDirectory
exit $s
