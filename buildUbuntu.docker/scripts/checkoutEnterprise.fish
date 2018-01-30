#!/usr/bin/fish
/scripts/checkoutArangoDB.fish
cd $INNERWORKDIR/ArangoDB
if test ! -d enterprise
  git clone ssh://git@github.com/arangodb/enterprise
end
#chown -R $UID:$GID $INNERWORKDIR
