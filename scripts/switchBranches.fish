#!/usr/bin/fish
cd /work/ArangoDB
git checkout $argv[1]
cd enterprise
git checkout $argv[2]
