#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults ; cleanWorkspace

set -g SOURCE_TAG $RELEASE_TAG

if test (string sub --length 1 "$RELEASE_TAG") = "v"
  set -g SOURCE_TAG (string sub --start 2 "$RELEASE_TAG")
end

switchBranches "$RELEASE_TAG" "$RELEASE_TAG" true
and findArangoDBVersion
and buildSourcePackage $SOURCE_TAG
and buildSourceSnippet $SOURCE_TAG

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
exit $s

