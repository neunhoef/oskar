set -x OSKARBUILDIMAGE neunhoef/oskar
set -x ALPINEBUILDIMAGE neunhoef/alpinebuildarangodb

function lockDirectory
  set -l pid (echo %self)
  if test ! -f LOCK.$pid
    touch LOCK.$pid
    while true
      if ln LOCK.$pid LOCK ^/dev/null
        break
      end
      echo -n Directory is locked, waiting...
      date
      sleep 15
    end
  end
end

function unlockDirectory
  if test -f LOCK
    set -l pid (echo %self)
    rm -rf LOCK LOCK.$pid
  end
end

function showConfig
  echo "Workdir           : $WORKDIR"
  echo "Inner workdir     : $INNERWORKDIR"
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
if test ! -d work ; mkdir work ; end
set -g VERBOSEOSKAR Off

function buildUbuntuBuildImage
  cd $WORKDIR/buildUbuntu.docker
  docker build -t $OSKARBUILDIMAGE .
  cd $WORKDIR
end
function pushUbuntuBuildImage ; docker push $OSKARBUILDIMAGE ; end
function pullUbuntuBuildImage ; docker pull $OSKARBUILDIMAGE ; end

function buildAlpineBuildImage
  cd $WORKDIR/buildAlpine.docker
  docker build -t $ALPINEBUILDIMAGE .
  cd $WORKDIR
end
function pushAlpineBuildImage ; docker push $ALPINEBUILDIMAGE ; end
function pullAlpineBuildImage ; docker pull $ALPINEBUILDIMAGE ; end

function remakeImages
  buildUbuntuBuildImage
  pushUbuntuBuildImage
  buildAlpineBuildImage
  pushAlpineBuildImage
end

function runInContainer
  docker run -it -v $WORKDIR/work:$INNERWORKDIR \
                 -v $SSH_AUTH_SOCK:/ssh-agent \
                 -e SSH_AUTH_SOCK=/ssh-agent \
                 -e UID=(id -u) \
                 -e GID=(id -g) \
                 --rm \
                 -e INNERWORKDIR=$INNERWORKDIR \
                 -e MAINTAINER=$MAINTAINER \
                 -e BUILDMODE=$BUILDMODE \
                 -e PARALLELISM=$PARALLELISM \
                 -e STORAGEENGINE=$STORAGEENGINE \
                 -e TESTSUITE=$TESTSUITE \
                 -e VERBOSEOSKAR=$VERBOSEOSKAR \
                 -e ENTERPRISEEDITION=$ENTERPRISEEDITION \
                 $argv
end

function checkoutArangoDB
  runInContainer $OSKARBUILDIMAGE /scripts/checkoutArangoDB.fish
  if test $status != 0 ; return $status ; end
  community
end

function checkoutEnterprise
  runInContainer $OSKARBUILDIMAGE /scripts/checkoutEnterprise.fish
  if test $status != 0 ; return $status ; end
  enterprise
end

function switchBranches
  runInContainer $OSKARBUILDIMAGE /scripts/switchBranches.fish $argv
end

function clearWorkdir
  runInContainer $OSKARBUILDIMAGE /scripts/clearWorkdir.fish
end

function buildArangoDB
  runInContainer $OSKARBUILDIMAGE /scripts/buildArangoDB.fish
  if test $status != 0
    echo Build error!
    return $status
  end
end

function buildStaticArangoDB
  runInContainer $ALPINEBUILDIMAGE /scripts/build.fish
  if test $status != 0
    echo Build error!
    return $status
  end
end

function shellInUbuntuContainer
  runInContainer $OSKARBUILDIMAGE fish
end

function shellInAlpineContainer
  runInContainer $ALPINEBUILDIMAGE fish
end

function oskar
  runInContainer $OSKARBUILDIMAGE /scripts/runTests.fish
end

function oskar1
  showConfig
  buildArangoDB ; if test $status != 0 ; return $status ; end
  oskar
end

function oskar2
  showConfig
  buildArangoDB ; if test $status != 0 ; return $status ; end
  cluster ; oskar ; single ; oskar ; cluster
end

function oskar4
  showConfig
  buildArangoDB ; if test $status != 0 ; return $status ; end
  rocksdb
  cluster ; oskar ; single ; oskar ; cluster
  mmfiles
  cluster ; oskar ; single ; oskar ; cluster
  rocksdb
end

function oskar8
  showConfig
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

function pushOskar
  source helper.fish
  git push
  buildUbuntuBuildImage
  pushUbuntuBuildImage
  buildAlpineBuildImage
  pushAlpineBuildImage
end

function updateOskar
  pullUbuntuBuildImage
  pullAlpineBuildImage
  git pull
  source helper.fish
end

function showLog
  less +G work/test.log
end

showConfig
