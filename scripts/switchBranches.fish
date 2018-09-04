#!/usr/bin/env fish

if set -q JENKINS_HOME
  cd $INNERWORKDIR/ArangoDB
  and git checkout -- .
  and git fetch
  and git checkout $argv[1]
  and git reset --hard origin/$argv[1]
  and git clean -fdx
  and if test $ENTERPRISEEDITION = On
    cd enterprise
    and git checkout -- .
    and git fetch
    and git checkout $argv[2]
    and git reset --hard origin/$argv[2]
    and git clean -fdx
  end
else
  cd $INNERWORKDIR/ArangoDB
  and git checkout $argv[1]
  and git pull
  and if test $ENTERPRISEEDITION = On
    cd enterprise
    and git checkout $argv[2]
    and git pull
  end
end
