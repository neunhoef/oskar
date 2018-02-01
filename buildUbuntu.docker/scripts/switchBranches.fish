#!/usr/bin/fish
echo $SSH_AUTH_SOCK
ssh-add -l
cd $INNERWORKDIR/ArangoDB
git checkout -- .
git pull
git checkout $argv[1]
git pull
if test $ENTERPRISEEDITION = On
  cd enterprise
  git checkout -- .
  git pull
  git checkout $argv[2]
  git pull
end
chown -R $UID:$GID $INNERWORKDIR
