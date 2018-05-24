#!/usr/bin/env fish
cd $INNERWORKDIR/ArangoDB
and git checkout -- .
and git fetch
and git checkout $argv[1]
and git reset --hard origin/$argv[1]
and if test $ENTERPRISEEDITION = On
  cd enterprise
  git checkout -- .
  and git fetch
  and git checkout $argv[2]
  and git reset --hard origin/$argv[2]
end
