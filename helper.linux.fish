set -gx INNERWORKDIR /work
set -gx SCRIPTSDIR /scripts
set -gx PLATFORM linux
set -gx ARCH (uname -m)
set -gx UBUNTUBUILDIMAGE neunhoef/ubuntubuildarangodb-$ARCH
set -gx UBUNTUPACKAGINGIMAGE neunhoef/ubuntupackagearangodb-$ARCH
set -gx ALPINEBUILDIMAGE neunhoef/alpinebuildarangodb-$ARCH
set -gx CENTOSPACKAGINGIMAGE neunhoef/centospackagearangodb-$ARCH

function buildUbuntuBuildImage
  cd $WORKDIR
  cp -a scripts/{makeArangoDB,buildArangoDB,checkoutArangoDB,checkoutEnterprise,clearWorkDir,downloadStarter,downloadSyncer,runTests,switchBranches,recursiveChown}.fish buildUbuntu.docker/scripts
  cd $WORKDIR/buildUbuntu.docker
  docker build -t $UBUNTUBUILDIMAGE .
  rm -f $WORKDIR/buildUbuntu.docker/scripts/*.fish
  cd $WORKDIR
end
function pushUbuntuBuildImage ; docker push $UBUNTUBUILDIMAGE ; end
function pullUbuntuBuildImage ; docker pull $UBUNTUBUILDIMAGE ; end

function buildUbuntuPackagingImage
  cd $WORKDIR
  cp -a scripts/buildDebianPackage.fish buildUbuntuPackaging.docker/scripts
  cd $WORKDIR/buildUbuntuPackaging.docker
  docker build -t $UBUNTUPACKAGINGIMAGE .
  rm -f $WORKDIR/buildUbuntuPackaging.docker/scripts/*.fish
  cd $WORKDIR
end
function pushUbuntuPackagingImage ; docker push $UBUNTUPACKAGINGIMAGE ; end
function pullUbuntuPackagingImage ; docker pull $UBUNTUPACKAGINGIMAGE ; end

function buildAlpineBuildImage
  cd $WORKDIR
  cp -a scripts/makeAlpine.fish scripts/buildAlpine.fish buildAlpine.docker/scripts
  cd $WORKDIR/buildAlpine.docker
  docker build -t $ALPINEBUILDIMAGE .
  rm -f $WORKDIR/buildAlpine.docker/scripts/*.fish
  cd $WORKDIR
end
function pushAlpineBuildImage ; docker push $ALPINEBUILDIMAGE ; end
function pullAlpineBuildImage ; docker pull $ALPINEBUILDIMAGE ; end

function buildCentosPackagingImage
  cd $WORKDIR
  cp -a scripts/buildRPMPackage.sh buildCentos7Packaging.docker/scripts
  cd $WORKDIR/buildCentos7Packaging.docker
  docker build -t $CENTOSPACKAGINGIMAGE .
  rm -f $WORKDIR/buildCentos7Packaging.docker/scripts/*.sh
  cd $WORKDIR
end
function pushCentosPackagingImage ; docker push $CENTOSPACKAGINGIMAGE ; end
function pullCentosPackagingImage ; docker pull $CENTOSPACKAGINGIMAGE ; end

function remakeImages
  buildUbuntuBuildImage
  pushUbuntuBuildImage
  buildAlpineBuildImage
  pushAlpineBuildImage
  buildUbuntuPackagingImage
  pushUbuntuPackagingImage
  buildCentosPackagingImage
  pushCentosPackagingImage
end

function runInContainer
  if test -z "$SSH_AUTH_SOCK"
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/id_rsa
    set -l agentstarted 1
  else
    set -l agentstarted ""
  end

  # Run script in container in background, but print output and react to
  # a TERM signal to the shell or to a foreground subcommand. Note that the
  # container process itself will run as root and will be immune to SIGTERM
  # from a regular user. Therefore we have to do some Eiertanz to stop it
  # if we receive a TERM outside the container. Note that this does not
  # cover SIGINT, since this will directly abort the whole function.
  set c (docker run -d -v $WORKDIR/work:$INNERWORKDIR \
             -v $SSH_AUTH_SOCK:/ssh-agent \
             -e SSH_AUTH_SOCK=/ssh-agent \
             -e UID=(id -u) \
             -e GID=(id -g) \
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
             -e SCRIPTSDIR=$SCRIPTSDIR \
             -e PLATFORM=$PLATFORM \
             $argv)
  function termhandler --on-signal TERM --inherit-variable c
    if test -n "$c" ; docker stop $c >/dev/null ; end
  end
  docker logs -f $c          # print output to stdout
  docker stop $c >/dev/null  # happens when the previous command gets a SIGTERM
  set s (docker inspect $c --format "{{.State.ExitCode}}")
  docker rm $c >/dev/null
  functions -e termhandler
  # Cleanup ownership:
  docker run -v $WORKDIR/work:$INNERWORKDIR -e UID=(id -u) -e GID=(id -g) \
      -e INNERWORKDIR=$INNERWORKDIR \
      $UBUNTUBUILDIMAGE $SCRIPTSDIR/recursiveChown.fish

  if test -n "$agentstarted"
    ssh-agent -k > /dev/null
    set -e SSH_AUTH_SOCK
    set -e SSH_AGENT_PID
  end
  return $s
end

function checkoutArangoDB
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/checkoutArangoDB.fish
  or return $status
  community
end

function checkoutEnterprise
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/checkoutEnterprise.fish
  or return $status
  enterprise
end

function switchBranches
  checkoutIfNeeded
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/switchBranches.fish $argv
end

function clearWorkDir
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/clearWorkDir.fish
end

function buildArangoDB
  checkoutIfNeeded
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/buildArangoDB.fish $argv
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function makeArangoDB
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/makeArangoDB.fish $argv
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function buildStaticArangoDB
  checkoutIfNeeded
  runInContainer $ALPINEBUILDIMAGE $SCRIPTSDIR/buildAlpine.fish $argv
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function makeStaticArangoDB
  runInContainer $ALPINEBUILDIMAGE $SCRIPTSDIR/makeAlpine.fish $argv
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function buildDebianPackage
  # This assumes that a static build has already happened
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  set -l v "$ARANGODB_FULL_VERSION"
  set -l ch $WORKDIR/work/debian/changelog
  if test -z "$v"
    echo Need one version argument in the form 3.3.3-1.
    return 1
  end

  cd $WORKDIR
  rm -rf $WORKDIR/work/debian
  and if test "$ENTERPRISEEDITION" = "On"
    echo Building enterprise edition debian package...
    cp -a debian.enterprise $WORKDIR/work/debian
    and echo -n "arangodb3e " > $ch
  else
    echo Building community edition debian package...
    cp -a debian.community $WORKDIR/work/debian
    and echo -n "arangodb3 " > $ch
  end
  and echo "($v) UNRELEASED; urgency=medium" >> $ch
  and echo >> $ch
  and echo "  * New version." >> $ch
  and echo >> $ch
  and echo -n " -- ArangoDB <hackers@arangodb.com>  " >> $ch
  and date -R >> $ch
  and runInContainer $UBUNTUPACKAGINGIMAGE $SCRIPTSDIR/buildDebianPackage.fish
  set -l s $status
  if test $s != 0
    echo Error when building a debian package
    return $s
  end
end

function transformSpec
  if test (count $argv) != 2
    echo transformSpec: wrong number of arguments
    return 1
  end
  cp "$argv[1]" "$argv[2]"
  sed -i -e "s/@PACKAGE_VERSION@/$ARANGODB_VERSION/" "$argv[2]"
  sed -i -e "s/@PACKAGE_REVISION@/$ARANGODB_PACKAGE_REVISION/" "$argv[2]"
end

function buildRPMPackage
  # This assumes that a static build has already happened
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  if test "$ENTERPRISEEDITION" = "On"
    transformSpec rpm/arangodb3e.spec.in $WORKDIR/work/arangodb3.spec
  else
    transformSpec rpm/arangodb3.spec.in $WORKDIR/work/arangodb3.spec
  end
  and runInContainer -e ARANGODB_VERSION=$ARANGODB_VERSION -e ARANGODB_PACKAGE_REVISION=$ARANGODB_PACKAGE_REVISION -e ARANGODB_FULL_VERSION=$ARANGODB_FULL_VERSION $CENTOSPACKAGINGIMAGE $SCRIPTSDIR/buildRPMPackage.sh
end

function buildTarGzPackage
  # This assumes that a static build has already happened
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  set -l v "$ARANGODB_FULL_VERSION"
  cd $WORKDIR
  and pushd $WORKDIR/work/ArangoDB/build/install
  and rm -rf bin
  and cp -a $WORKDIR/binForTarGz bin
  or begin ; popd ; return $status ; end
  strip usr/sbin/arangod usr/bin/{arangobench,arangodump,arangoexport,arangoimp,arangorestore,arangosh,arangovpack}
  and if test "$ENTERPRISEEDITION" = "On"
    tar czvf "$WORKDIR/work/arangodb3e-binary-$v.tar.gz" *
  else
    tar czvf "$WORKDIR/work/arangodb3-binary-$v.tar.gz" *
  end
  set s $status
  popd
  return $s 
end

function interactiveContainer
  docker run -it -v $WORKDIR/work:$INNERWORKDIR \
             -v $SSH_AUTH_SOCK:/ssh-agent \
             -e SSH_AUTH_SOCK=/ssh-agent \
             -e UID=(id -u) \
             -e GID=(id -g) \
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
             -e SCRIPTSDIR=$SCRIPTSDIR \
             -e PLATFORM=$PLATFORM \
             $argv
end

function shellInUbuntuContainer
  interactiveContainer $UBUNTUBUILDIMAGE fish
end

function shellInAlpineContainer
  interactiveContainer $ALPINEBUILDIMAGE fish
end

function oskar
  checkoutIfNeeded
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/runTests.fish
end

function pushOskar
  cd $WORKDIR
  source helper.fish
  git push
  buildUbuntuBuildImage
  pushUbuntuBuildImage
  buildAlpineBuildImage
  pushAlpineBuildImage
  buildUbuntuPackagingImage
  pushUbuntuPackagingImage
end

function updateOskar
  cd $WORKDIR
  and git checkout -- .
  and git pull
  and source helper.fish
  and pullUbuntuBuildImage
  and pullAlpineBuildImage
  and pullUbuntuPackagingImage
end

function downloadStarter
  runInContainer $UBUNTUBUILDIMAGE $SCRIPTSDIR/downloadStarter.fish $argv
end

function downloadSyncer
  runInContainer -e DOWNLOAD_SYNC_USER=$DOWNLOAD_SYNC_USER $UBUNTUBUILDIMAGE $SCRIPTSDIR/downloadSyncer.fish $argv
end

function makeDockerImage
  if test "$DOWNLOAD_SYNC_USER" = ""
    echo "Need to set environment variable DOWNLOAD_SYNC_USER."
    return 1
  end
  if test (count $argv) = 0
    echo Must give image name as argument
    return 1
  end
  set -l imagename $argv[1]

  cd $WORKDIR/work/ArangoDB/build/install
  and tar czvf $WORKDIR/arangodb.docker/install.tar.gz *
  if test $status != 0
    echo Could not create install tarball!
    return 1
  end

  cd $WORKDIR/arangodb.docker
  docker build -t $imagename .
end

function buildPackage
  # Must have set ARANGODB_VERSION and ARANGODB_PACKAGE_REVISION and
  # ARANGODB_FULL_VERSION, for example by running findArangoDBVersion.
  buildDebianPackage
  # and buildRpmPackage
  and buildTarGzPackage
end

# Set PARALLELISM in a sensible way:
set -xg PARALLELISM (math (grep processor /proc/cpuinfo | wc -l) "*" 2)
