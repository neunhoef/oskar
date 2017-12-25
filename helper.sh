function single {
  export TESTSUITE=single
}

function cluster {
  export TESTSUITE=cluster
}

cluster

function oskar {
  echo Testing $TESTSUITE
}
