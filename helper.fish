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

function single ; set -g TESTSUITE single ; showConfig ; end
function cluster ; set -g TESTSUITE cluster ; showConfig ; end
function resilience ; set -g TESTSUITE resilience ; showConfig ; end
if test -z "$TESTSUITE" ; set -g TESTSUITE cluster ; end

function maintainerOn ; set -g MAINTAINER On ; showConfig ; end
function maintainerOff ; set -g MAINTAINER Off ; showConfig ; end
if test -z "$MAINTAINER" ; set -g MAINTAINER On ; end

function debugMode ; set -g BUILDMODE Debug ; showConfig ; end
function releaseMode ; set -g BUILDMODE RelWithDebInfo ; showConfig ; end
if test -z "$BUILDMODE" ; set -g BUILDMODE RelWithDebInfo ; end

function community ; set -g ENTERPRISEEDITION Off ; showConfig ; end
function enterprise ; set -g ENTERPRISEEDITION On ; showConfig ; end
if test -z "$ENTERPRISEEDITION" ; set -g ENTERPRISEEDITION On ; end

function mmfiles ; set -g STORAGEENGINE mmfiles ; showConfig ; end
function rocksdb ; set -g STORAGEENGINE rocksdb ; showConfig ; end
if test -z "$STORAGEENGINE" ; set -g STORAGEENGINE rocksdb ; end

function parallelism ; set -g PARALLELISM $argv[1] ; showConfig ; end
if test -z "$PARALLELISM" ; set -g PARALLELISM 64 ; end

set -g WORKDIR (pwd)
if test -f oskar_name
  set -g NAME (cat oskar_name)
else
  set -g NAME "oskar_"(random)_(random)
  echo $NAME >oskar_name
end
if test ! -d work ; mkdir work ; end
if docker exec -it $NAME true ^/dev/null
  set -g CONTAINERRUNNING yes
else
  set -g CONTAINERRUNNING no
end

function buildImage ; cd $WORKDIR ; docker build -t neunhoef/oskar . ; end
function pushImage ; docker push neunhoef/oskar ; end
function pullImage ; docker pull neunhoef/oskar ; end

function startContainer
  if test $CONTAINERRUNNING = no
    docker run -d --rm -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group -v $WORKDIR/work:/work --user (id -u):(id -g) -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent --name $NAME neunhoef/oskar
    set -g CONTAINERRUNNING yes
  end
end

function stopContainer
  if test $CONTAINERRUNNING = yes
    docker stop $NAME
    set -g CONTAINERRUNNING no
  end
end

function checkoutArangoDB
  startContainer
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e TESTSUITE=$TESTSUITE -e ENTERPRISEEDITION=$ENTERPRISEEDITION $NAME /scripts/checkoutArangoDB.fish
  community
end

function checkoutEnterprise
  startContainer
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/checkoutEnterprise.fish
  enterprise
end

function switchBranches
  startContainer
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/switchBranches.fish $argv
end

function clearWorkdir
  startContainer
  docker exec -it -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/clearWorkdir.fish
end

function showAndCheck
  startContainer
  showConfig
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
