#!/usr/bin/fish
cd /work
if test ! -d ArangoDB
  git clone ssh://git@github.com/arangodb/ArangoDB
end
