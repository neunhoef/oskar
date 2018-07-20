#!/usr/bin/env fish
cd $INNERWORKDIR
if test ! -d ArangoDB
  git clone ssh://git@github-proxy01:8088/arangodb/ArangoDB
end
