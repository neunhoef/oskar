set -gx SCRIPTSDIR $WORKDIR/scripts
set -gx PLATFORM darwin
set -gx UID (id -u)
set -gx GID (id -g)
set -gx INNERWORKDIR $WORKDIR/work
set -gx THIRDPARTY_BIN $INNERWORKDIR/third_party/bin
set -gx CCACHEBINPATH /usr/local/opt/ccache/libexec
set -gx CMAKE_INSTALL_PREFIX /opt/arangodb

if test -z "$PARALLELISM" ; parallelism 8 ; end

function runLocal
  if test -z "$SSH_AUTH_SOCK"
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/id_rsa
    set -l agentstarted 1
  else
    set -l agentstarted ""
  end
  set -xg GIT_SSH_COMMAND "ssh -o StrictHostKeyChecking=no"
  eval $argv 
  set -l s $status
  if test -n "$agentstarted"
    ssh-agent -k > /dev/null
    set -e SSH_AUTH_SOCK
    set -e SSH_AGENT_PID
  end
  return $s
end

function checkoutArangoDB
  runLocal $SCRIPTSDIR/checkoutArangoDB.fish
  or return $status
  community
end

function checkoutEnterprise
  runLocal $SCRIPTSDIR/checkoutEnterprise.fish
  or return $status
  enterprise
end

function switchBranches
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/switchBranches.fish $argv
end

function clearWorkdir
  runLocal $SCRIPTSDIR/clearWorkdir.fish
end

function buildArangoDB
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/buildMacOs.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function makeArangoDB
  runLocal $SCRIPTSDIR/makeArangoDB.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function buildStaticArangoDB
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/buildMacOs.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function makeStaticArangoDB
  runLocal $SCRIPTSDIR/makeArangoDB.fish $argv
  set -l s $status
  if test $s -ne 0
    echo Build error!
    return $s
  end
end

function oskar
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/runTests.fish
end

function oskarFull
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/runFullTests.fish
end


function pushOskar
  cd $WORKDIR
  source helper.fish
  git push
end

function updateOskar
  cd $WORKDIR
  and git checkout -- .
  and git pull
  and source helper.fish
end

function downloadStarter
  runLocal $SCRIPTSDIR/downloadStarter.fish $THIRDPARTY_BIN $argv
end

function downloadSyncer
  runLocal $SCRIPTSDIR/downloadSyncer.fish $THIRDPARTY_BIN $argv
end

function buildPackage
  # This assumes that a build has already happened
  # Must have set ARANGODB_DARWIN_UPSTREAM and ARANGODB_DARWIN_REVISION,
  # for example by running findArangoDBVersion.
  if test -z "$ARANGODB_DARWIN_REVISION"
    set v "$ARANGODB_DARWIN_UPSTREAM"
  else  
    set v "$ARANGODB_DARWIN_UPSTREAM-$ARANGODB_DARWIN_REVISION"
  end

  if test "$ENTERPRISEEDITION" = "On"
    echo Building enterprise edition MacOs bundle...
  else
    echo Building community edition MacOs bundle...
  end

  and runLocal $SCRIPTSDIR/buildMacOsPackage.fish
  and buildTarGzPackage
end

function cleanupThirdParty
  rm -rf $THIRDPARTY_BIN
end

function buildEnterprisePackage
  if test "$DOWNLOAD_SYNC_USER" = ""
    echo "Need to set environment variable DOWNLOAD_SYNC_USER."
    return 1
  end
 
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  maintainerOff
  releaseMode
  enterprise
  set -xg NOSTRIP dont

  cleanupThirdParty
  and downloadStarter
  and downloadSyncer
  and buildStaticArangoDB \
      -DTARGET_ARCHITECTURE=nehalem \
      -DPACKAGING=Bundle \
      -DPACKAGE_TARGET_DIR=$INNERWORKDIR \
      -DTHIRDPARTY_SBIN=$THIRDPARTY_BIN/arangosync \
      -DTHIRDPARTY_BIN=$THIRDPARTY_BIN/arangodb \
      -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX
  and buildPackage

  if test $status != 0
    echo Building enterprise release failed, stopping.
    return 1
  end
end

function buildCommunityPackage
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  maintainerOff
  releaseMode
  community
  set -xg NOSTRIP dont

  cleanupThirdParty
  and downloadStarter
  and buildStaticArangoDB \
      -DTARGET_ARCHITECTURE=nehalem \
      -DPACKAGING=Bundle \
      -DPACKAGE_TARGET_DIR=$INNERWORKDIR \
      -DTHIRDPARTY_BIN=$THIRDPARTY_BIN/arangodb \
      -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX
  and buildPackage

  if test $status != 0
    echo Building community release failed.
    return 1
  end
end

function buildTarGzPackage
  cd $INNERWORKDIR/ArangoDB/build
  and rm -rf install
  and make install DESTDIR=install
  and mkdir install/usr
  and mv install/opt/arangodb/bin install/usr
  and mv install/opt/arangodb/sbin install/usr
  and mv install/opt/arangodb/share install/usr
  and mv install/opt/arangodb/etc install
  and rm -rf install/opt
  and buildTarGzPackageHelper "macosx"
end
