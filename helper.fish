set -x UBUNTUBUILDIMAGE neunhoef/oskar
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
  set -l pid (echo %self)
  if test -f LOCK.$pid
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
  docker build -t $UBUNTUBUILDIMAGE .
  cd $WORKDIR
end
function pushUbuntuBuildImage ; docker push $UBUNTUBUILDIMAGE ; end
function pullUbuntuBuildImage ; docker pull $UBUNTUBUILDIMAGE ; end

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
  if test -z "$SSH_AUTH_SOCK"
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/id_rsa
    set -l agentstarted 1
  else
    set -l agentstarted ""
  end
  docker run -v $WORKDIR/work:$INNERWORKDIR \
             -v $SSH_AUTH_SOCK:/ssh-agent \
             -e SSH_AUTH_SOCK=/ssh-agent \
             -e UID=(id -u) \
             -e GID=(id -g) \
             --rm \
             -e NOSTRIP="$NOSTRIP" \
             -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
             -e INNERWORKDIR=$INNERWORKDIR \
             -e MAINTAINER=$MAINTAINER \
             -e BUILDMODE=$BUILDMODE \
             -e PARALLELISM=$PARALLELISM \
             -e STORAGEENGINE=$STORAGEENGINE \
             -e TESTSUITE=$TESTSUITE \
             -e VERBOSEOSKAR=$VERBOSEOSKAR \
             -e ENTERPRISEEDITION=$ENTERPRISEEDITION \
             $argv
  if test -n "$agentstarted"
    ssh-agent -k > /dev/null
    set -e SSH_AUTH_SOCK
    set -e SSH_AGENT_PID
  end
end

function checkoutArangoDB
  runInContainer $UBUNTUBUILDIMAGE /scripts/checkoutArangoDB.fish
  or return $status
  community
end

function checkoutEnterprise
  runInContainer $UBUNTUBUILDIMAGE /scripts/checkoutEnterprise.fish
  or return $status
  enterprise
end

function checkoutIfNeeded
  if test ! -d $WORKDIR/ArangoDB
    if test "$ENTERPRISEEDITION" = "On"
      checkoutEnterprise
    else
      checkoutArangoDB
    end
  end
end

function switchBranches
  checkoutIfNeeded
  runInContainer $UBUNTUBUILDIMAGE /scripts/switchBranches.fish $argv
end

function clearWorkdir
  runInContainer $UBUNTUBUILDIMAGE /scripts/clearWorkdir.fish
end

function clearResults
  cd $WORKDIR
  for f in testreport* ; rm -f $f ; end
  rm -f test.log
end

function buildArangoDB
  checkoutIfNeeded
  runInContainer $UBUNTUBUILDIMAGE /scripts/buildArangoDB.fish
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function buildStaticArangoDB
  checkoutIfNeeded
  if test ! -d $WORKDIR/ArangoDB
    if test "$ENTERPRISEEDITION" = "On"
      checkoutEnterprise
    else
      checkoutArangoDB
    end
  end
  runInContainer $ALPINEBUILDIMAGE /scripts/build.fish
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function buildDebianPackage
  # This assumes that a static build has already happened
  cd $WORKDIR
  rm -rf $WORKDIR/work/debian
  and if test "$ENTERPRISEEDITION" = "On"
    cp -a debian.enterprise $WORKDIR/work/debian
  else
    cp -a debian.community $WORKDIR/work
  end
  and runInContainer $UBUNTUBUILDIMAGE /scripts/buildDebianPackage.fish
  set -l s $status
  if test $s != 0
    echo Error when building a debian package
    return $s
  end
end

function shellInUbuntuContainer
  runInContainer $UBUNTUBUILDIMAGE fish
end

function shellInAlpineContainer
  runInContainer $ALPINEBUILDIMAGE fish
end

function oskar
  checkoutIfNeeded
  runInContainer $UBUNTUBUILDIMAGE /scripts/runTests.fish
end

function oskar1
  showConfig
  buildArangoDB ; or return $status
  oskar
end

function oskar2
  showConfig
  buildArangoDB ; or return $status
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster
end

function oskar4
  showConfig
  buildArangoDB ; or return $status
  rocksdb
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  mmfiles
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster ; rocksdb
end

function oskar8
  showConfig
  enterprise
  buildArangoDB ; or return $status
  rocksdb
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  mmfiles
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  community
  buildArangoDB ; or return $status
  rocksdb
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  mmfiles
  cluster ; oskar ; or return $status
  single ; oskar ; or return $status
  cluster ; rocksdb
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
