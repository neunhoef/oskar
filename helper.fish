function single ; set -g TESTSUITE single ; end
function cluster ; set -g TESTSUITE cluster ; end
function resilience ; set -g TESTSUITE resilience ; end
cluster

function maintainerOn ; set -g MAINTAINER on ; end
function maintainerOff ; set -g MAINTAINER off ; end
maintainerOn

function debugMode ; set -g BUILDMODE Debug ; end
function releaseMode ; set -g BUILDMODE RelWithDebInfo ; end
releaseMode

function community ; set -g ENTERPRISEEDITION Off ; end
function enterprise ; set -g ENTERPRISEEDITION On ; end
enterprise

function mmfiles ; set -g STORAGEENGINE mmfiles ; end
function rocksdb ; set -g STORAGEENGINE rocksdb ; end
rocksdb

set -g WORKDIR (pwd)
if test -f oskar_name
  set -g NAME (cat oskar_name)
else
  set -g NAME "oskar_"(random)
  echo $NAME >oskar_name
end
set -g CONTAINERRUNNING no
set -g PARALLELISM 64

function checkoutArangoDB
  cd $WORKDIR
  rm -rf ArangoDB
  git clone ssh://git@github.com/arangodb/ArangoDB
  community
end

function checkoutEnterprise
  cd $WORKDIR
  if test ! -d ArangoDB
    checkoutArangoDB
  end
  cd ArangoDB
  if test ! -d enterprise
    git clone ssh://git@github.com/arangodb/enterprise
    enterprise
  end
end

function buildBuildImage ; cd $WORKDIR ; docker build -t neunhoef/oskar . ; end
function pushBuildImage ; docker push neunhoef/oskar ; end
function pullBuildImage ; docker pull neunhoef/oskar ; end

function startContainer
  docker run -d --rm -v $WORKDIR:/ArangoDB -name $NAME neunhoef/oskar
  set -g CONTAINERRUNNING yes
end

function stopContainer
  docker stop $NAME
  set -g CONTAINERRUNNING no
end

function showConfig
  echo "Workdir           : $WORKDIR"
  echo "Name              : $NAME"
  echo "Container running : $CONTAINERRUNNING"
  echo "Maintainer        : $MAINTAINER"
  echo "Buildmode         : $BUILDMODE"
  echo "Parallelism       : $PARALLELISM"
  echo "Enterpriseedition : $ENTERPRISEEDITION"
  echo "Storage engine    : $STORAGEENGINE"
  echo "Test suite        : $TESTSUITE"
end

function showAndCheck
  showConfig
  if test $CONTAINERRUNNING = no
    echo You have to start the container first using startContainer
  end
end

function buildArangoDB
  showAndCheck
  cd $WORKDIR
  set -x MAINTAINER $MAINTAINER
  set -x BUILDMODE $BUILDMODE
  set -x PARALLELISM $PARALLELISM
  set -x STORAGEENGINE $STORAGEENGINE
  set -x TESTSUITE $TESTSUITE
  docker exec -it $NAME /scripts/buildArangoDB.fish
end

function oskar
  showAndCheck
  cd $WORKDIR
  set -x MAINTAINER $MAINTAINER
  set -x BUILDMODE $BUILDMODE
  set -x PARALLELISM $PARALLELISM
  set -x STORAGEENGINE $STORAGEENGINE
  set -x TESTSUITE $TESTSUITE
  docker exec -it $NAME /scripts/runTests.fish
end

showConfig
