#!/usr/bin/fish
cd /work/ArangoDB
git checkout -- .
git checkout $argv[1]
if test $ENTERPRISEEDITION = On
  cd enterprise
  git checkout -- .
  git checkout $argv[2]
end
