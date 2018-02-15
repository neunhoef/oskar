set -xg SCRIPTSDIR $WORKDIR/scripts
set -xg PLATFORM darwin
set -xg UID (id -u)
set -xg GID (id -g)
set -xg INNERWORKDIR $WORKDIR/work

function runLocal
  if test -z "$SSH_AUTH_SOCK"
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/id_rsa
    set -l agentstarted 1
  else
    set -l agentstarted ""
  end
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
  runLocal $SCRIPTSDIR/buildArangoDB.fish $argv
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function buildStaticArangoDB
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/buildAlpine.fish $argv
  set -l s $status
  if test $s != 0
    echo Build error!
    return $s
  end
end

function oskar
  checkoutIfNeeded
  runLocal $SCRIPTSDIR/runTests.fish
end

function pushOskar
  cd $WORKDIR
  source helper.fish
  git push
end

function updateOskar
  cd $WORKDIR
  git pull
  source helper.fish
end

function downloadStarter
  runLocal $SCRIPTSDIR/downloadStarter.fish $argv
end

function downloadSyncer
  runLocal -e DOWNLOAD_SYNC_USER=$DOWNLOAD_SYNC_USER $SCRIPTSDIR/downloadSyncer.fish $argv
end

function buildMacPackage
  echo Not yet implemented
  return 1
end

function buildPackage
  buildMacPackage $argv
end
