#!/usr/bin/env fish

function cleanup
  # Hard kill all running processes.
  # First kill any starter running to stop respawning
  killall -9 arangodb
  # Then kill all arangodb
  killall -9 arangod
end


source jenkins/helper.jenkins.fish ; prepareOskar
lockDirectory ; updateOskar ; clearResults

set -g LOCALWORKDIR "$WORKDIR/$INNERWORKDIR"
set -g DATA_PATH "$LOCALWORKDIR/perfCluster"

function archiveAgency
  tar czf $WORKDIR/work/agency.tar.gz $DATA_PATH/
end

function archiveDBServer
  tar czf $WORKDIR/work/dbserver.tar.gz $DATA_PATH/dbserver8530/arangod.log
end

function archiveCoordinator
  tar czf $WORKDIR/work/coordinator.tar.gz $DATA_PATH/coordinator8529/arangod.log
end

function stopAndArchive
  if test -d $DATA_PATH
    set -l STARTER "$LOCALWORKDIR/ArangoDB/build/install/usr/bin/arangodb"
    if test -x $STARTER
      # try graceful shutdown
      eval $STARTER stop
    end
    archiveAgency
    archiveDBServer
    archiveCoordinator
    moveResultsToWorkspace
  end
  cleanup
end

stopAndArchive
