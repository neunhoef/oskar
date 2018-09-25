#!/usr/bin/env fish

if test (count $argv) -lt 2
    echo "you did not provide enough arguments"
end

set -l arango $argv[1]
set -l enterprise $argv[2]
set -l force_clean false

if test (count $argv) -eq 3
    set -l force_clean $argv[3]
end

if test "$force_clean" = "true"
  cd $INNERWORKDIR/ArangoDB
  and git checkout -- .
  and git fetch
  and git checkout $arango
  and git reset --hard origin/$arango
  and git clean -fdx
  and if test $ENTERPRISEEDITION = On
    cd enterprise
    and git checkout -- .
    and git fetch
    and git checkout $enterprise
    and git reset --hard origin/$enterprise
    and git clean -fdx
  end
else
  cd $INNERWORKDIR/ArangoDB
  and git checkout $arango
  and git pull
  and if test $ENTERPRISEEDITION = On
    cd enterprise
    and git checkout $enterprise
    and git pull
  end
end
