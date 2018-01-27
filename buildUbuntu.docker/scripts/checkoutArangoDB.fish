#!/usr/bin/fish
cd $INNERWORKDIR
if test ! -d ArangoDB
  git clone ssh://git@github.com/arangodb/ArangoDB
end
chown -R $UID: $INNERWORKDIR
