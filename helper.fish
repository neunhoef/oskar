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
  set -g NAME "oskar_"(random)_(random)
  echo $NAME >oskar_name
end
if test ! -d work ; mkdir work ; end
set -g CONTAINERRUNNING no
set -g PARALLELISM 64

function buildImage ; cd $WORKDIR ; docker build -t neunhoef/oskar . ; end
function pushImage ; docker push neunhoef/oskar ; end
function pullImage ; docker pull neunhoef/oskar ; end

function startContainer
  docker run -d --rm -v $WORKDIR/work:/work -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent --name $NAME neunhoef/oskar
  set -g CONTAINERRUNNING yes
end

function stopContainer
  docker stop $NAME
  set -g CONTAINERRUNNING no
end

function checkoutArangoDB
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e TESTSUITE=$TESTSUITE -e ENTERPRISEEDITION=$ENTERPRISEEDITION $NAME /scripts/checkoutArangoDB.fish
  community
end

function checkoutEnterprise
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/checkoutEnterprise.fish
  enterprise
end

function clearWorkdir
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/clearWorkdir.fish
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
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/buildArangoDB.fish
end

function oskar
  showAndCheck
  cd $WORKDIR
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/runTests.fish
end

showConfig
