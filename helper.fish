function showConfig
  echo "Workdir           : $WORKDIR"
  echo "Inner workdir     : $INNERWORKDIR"
  echo "Name              : $NAME"
  echo "Container running : $CONTAINERRUNNING"
  echo "Maintainer        : $MAINTAINER"
  echo "Buildmode         : $BUILDMODE"
  echo "Parallelism       : $PARALLELISM"
  echo "Enterpriseedition : $ENTERPRISEEDITION"
  echo "Storage engine    : $STORAGEENGINE"
  echo "Test suite        : $TESTSUITE"
  echo "Verbose           : $VERBOSEOSKAR"
end

function single ; set -g TESTSUITE single ; end
function cluster ; set -g TESTSUITE cluster ; end
function resilience ; set -g TESTSUITE resilience ; end
if test -z "$TESTSUITE" ; set -g TESTSUITE cluster ; end

function maintainerOn ; set -g MAINTAINER On ; end
function maintainerOff ; set -g MAINTAINER Off ; end
if test -z "$MAINTAINER" ; set -g MAINTAINER On ; end

function debugMode ; set -g BUILDMODE Debug ; end
function releaseMode ; set -g BUILDMODE RelWithDebInfo ; end
if test -z "$BUILDMODE" ; set -g BUILDMODE RelWithDebInfo ; end

function community ; set -g ENTERPRISEEDITION Off ; end
function enterprise ; set -g ENTERPRISEEDITION On ; end
if test -z "$ENTERPRISEEDITION" ; set -g ENTERPRISEEDITION On ; end

function mmfiles ; set -g STORAGEENGINE mmfiles ; end
function rocksdb ; set -g STORAGEENGINE rocksdb ; end
if test -z "$STORAGEENGINE" ; set -g STORAGEENGINE rocksdb ; end

function parallelism ; set -g PARALLELISM $argv[1] ; end
if test -z "$PARALLELISM" ; set -g PARALLELISM 64 ; end

function verbose ; set -g VERBOSEOSKAR On ; end
function silent ; set -g VERBOSEOSKAR Off ; end

set -g WORKDIR (pwd)
set -g INNERWORKDIR /work
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
set -g VERBOSEOSKAR Off

function buildImage
  cd $WORKDIR/buildUbuntu.docker
  docker build -t neunhoef/oskar .
  cd $WORKDIR
end
function pushImage ; docker push neunhoef/oskar ; end
function pullImage ; docker pull neunhoef/oskar ; end

function startContainer
  if test $CONTAINERRUNNING = no
    docker run -d --rm -v $WORKDIR/work:/work -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent --name $NAME neunhoef/oskar
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
  docker exec -it -e INNERWORKDIR=$INNERWORKDIR -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e TESTSUITE=$TESTSUITE -e VERBOSEOSKAR=$VERBOSEOSKAR -e ENTERPRISEEDITION=$ENTERPRISEEDITION $NAME /scripts/checkoutArangoDB.fish
  community
end

function checkoutEnterprise
  startContainer
  docker exec -it -e INNERWORKDIR=$INNERWORKDIR -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e VERBOSEOSKAR=$VERBOSEOSKAR -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/checkoutEnterprise.fish
  enterprise
end

function switchBranches
  startContainer
  docker exec -it -e INNERWORKDIR=$INNERWORKDIR -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e VERBOSEOSKAR=$VERBOSEOSKAR -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/switchBranches.fish $argv
end

function clearWorkdir
  startContainer
  docker exec -it -e INNERWORKDIR=$INNERWORKDIR -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e VERBOSEOSKAR=$VERBOSEOSKAR -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/clearWorkdir.fish
end

function showAndCheck
  startContainer
  showConfig
end

function buildArangoDB
  docker exec -it -e INNERWORKDIR=$INNERWORKDIR -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e VERBOSEOSKAR=$VERBOSEOSKAR -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/buildArangoDB.fish
  if test $status != 0
    echo Build error!
    return $status
  end
end

function oskar
  docker exec -it -e INNERWORKDIR=$INNERWORKDIR -e MAINTAINER=$MAINTAINER -e BUILDMODE=$BUILDMODE -e PARALLELISM=$PARALLELISM -e STORAGEENGINE=$STORAGEENGINE -e VERBOSEOSKAR=$VERBOSEOSKAR -e ENTERPRISEEDITION=$ENTERPRISEEDITION -e TESTSUITE=$TESTSUITE $NAME /scripts/runTests.fish
end

function oskar1
  showAndCheck
  buildArangoDB ; if test $status != 0 ; return $status ; end
  oskar
end

function oskar2
  showAndCheck
  buildArangoDB ; if test $status != 0 ; return $status ; end
  cluster ; oskar ; single ; oskar ; cluster
end

function oskar4
  showAndCheck
  buildArangoDB ; if test $status != 0 ; return $status ; end
  rocksdb
  cluster ; oskar ; single ; oskar ; cluster
  mmfiles
  cluster ; oskar ; single ; oskar ; cluster
  rocksdb
end

function oskar8
  showAndCheck
  enterprise
  buildArangoDB ; if test $status != 0 ; return $status ; end
  rocksdb
  cluster ; oskar ; single ; oskar ; cluster
  mmfiles
  cluster ; oskar ; single ; oskar ; cluster
  community
  buildArangoDB ; if test $status != 0 ; return $status ; end
  rocksdb
  cluster ; oskar ; single ; oskar ; cluster
  mmfiles
  cluster ; oskar ; single ; oskar ; cluster
  rocksdb
end

function updateOskar
  stopContainer
  pullImage
  git pull
  source helper.fish
  startContainer
end

function showLog
  less +G work/test.log
end

showConfig
