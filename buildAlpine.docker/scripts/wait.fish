#!/usr/bin/fish
set -l d (date)
echo $d > /tmp/used_stamp
while true
  sleep 24h
  set -l g (cat /tmp/used_stamp)
  if test $d = $g
    echo Not used in 24h, goodbye!
    exit 0
  end
  echo Used.
  set -l d $g
end
