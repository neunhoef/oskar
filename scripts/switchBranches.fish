#!/usr/bin/fish
cd $INNERWORKDIR/ArangoDB
git checkout -- .
git checkout $argv[1]
git pull
if test $ENTERPRISEEDITION = On
  cd enterprise
  git checkout -- .
  git checkout $argv[2]
  git pull
end
