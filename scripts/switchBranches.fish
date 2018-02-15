#!/usr/bin/fish
cd $INNERWORKDIR/ArangoDB
and git checkout -- .
and git pull
and git checkout $argv[1]
and git pull
and if test $ENTERPRISEEDITION = On
  cd enterprise
  git checkout -- .
  and git pull
  and git checkout $argv[2]
  and git pull
end
set -l s $status
chown -R $UID:$GID $INNERWORKDIR
exit $s
