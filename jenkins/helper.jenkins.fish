#!/usr/bin/env fish

function prepareOskar
  mkdir -p "$HOME/$NODE_NAME" ; cd "$HOME/$NODE_NAME"
  if not cd oskar ^ /dev/null 
    git clone https://github.com/arangodb/oskar ; and cd oskar
  else
    git fetch ; and git reset --hard origin/master
  end
  and source helper.fish
  if test $status -ne 0 ; echo Did not find oskar and helpers ; exit 1 ; end
end
