#!/usr/bin/env fish
if test (count $argv) -lt 3
  echo "Error: We need exactly three servers to join"
  exit 1
end

set -g JOIN_PART "--join $argv[1] --join $argv[2] --join $argv[3]"

function startClusterStarter
  set -l LOCALWORKDIR "$WORKDIR/$INNERWORKDIR"
  set -l DATA_PATH "$LOCALWORKD/perfCluster"
  rm -rf DATA_PATH
  if test "$ENTERPRISEEDITION" = "On"
    set -l ENTERPRISE_JS_PATH "--all.javascript.module-path $LOCALWORKDIR/ArangoDB/enterprise/js"
  else
    set -l ENTERPRISE_JS_PATH ""
  end
  set -l JS_PATH "$LOCALWORKDIR/ArangoDB/js"
  set -l ARANGOD_PATH "$LOCALWORKDIR/ArangoDB/build/bin/arangod"
  set -l STARTER "$LOCALWORKDIR/ArangoDB/build/install/usr/bin/arangodb"
  # Tell jenkins to not kill this job.
  set -xg BUILD_ID dontKillMe
  eval $STARTER start --starter.wait --starter.data-dir $DATA_PATH --server.js-dir $JS_PATH --server.arangod $ARANGOD_PATH $ENTERPRISE_JS_PATH $JOIN_PART
end

source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults
eval $EDITION ; eval $STORAGE_ENGINE

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH
maintainerOff
releaseMode
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter

if test $status != 0
  echo Building arangodb failed, stopping.
  exit 1
end

startClusterStarter
