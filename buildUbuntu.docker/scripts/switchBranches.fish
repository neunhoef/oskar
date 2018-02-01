#!/usr/bin/fish
echo $SSH_AUTH_SOCK
cd $INNERWORKDIR/ArangoDB
echo Hallo1
git checkout -- .
echo Hallo2
git pull
echo Hallo3
git checkout $argv[1]
echo Hallo4
git pull
echo Hallo5
if test $ENTERPRISEEDITION = On
  cd enterprise
  git checkout -- .
echo Hallo6
  git pull
echo Hallo7
  git checkout $argv[2]
echo Hallo8
  git pull
echo Hallo9
end
chown -R $UID:$GID $INNERWORKDIR
