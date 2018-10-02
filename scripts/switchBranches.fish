#!/usr/bin/env fish

function checkoutRepo
  if test (count $argv) -ne 2
      echo "Checkout needs two parameters branch force"
      return 1
  end
  set -l branch (string trim $argv[1])
  set -l clean $argv[2]

  git checkout -- .
  and git fetch
  and git checkout "$branch"
  and if test "$clean" = "true"
    git reset --hard "origin/$branch"
    and git clean -fdx
  else
    git pull
  end
  return $status
end

if test (count $argv) -lt 2
    echo "you did not provide enough arguments"
end

set -l arango $argv[1]
set -l enterprise $argv[2]
set -l force_clean false

if test (count $argv) -eq 3
    set force_clean $argv[3]
end

cd $INNERWORKDIR/ArangoDB
and checkoutRepo $arango $force_clean
if test $status -ne 0
  echo "Failed to checkout community branch"
  exit $status
end

if test $ENTERPRISEEDITION = On
  cd enterprise
  and checkoutRepo $enterprise $force_clean
  if test $status -ne 0
    echo "Failed to checkout enterprise branch"
    exit $status
  end
end
