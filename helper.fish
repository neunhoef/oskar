function single
  set -x TESTSUITE single
end

function cluster
  set -x TESTSUITE cluster
end

function oskar
  echo Testing $TESTSUITE
end
