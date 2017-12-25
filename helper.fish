function single
  set -g TESTSUITE single
end

function cluster
  set -g TESTSUITE cluster
end

cluster

function oskar
  echo Testing $TESTSUITE
end
