#!/usr/bin/fish
/scripts/checkoutArangoDB.fish
cd /work/ArangoDB
if test ! -d enterprise
  git clone ssh://git@github.com/arangodb/enterprise
end
