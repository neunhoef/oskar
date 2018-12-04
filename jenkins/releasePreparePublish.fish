#!/usr/bin/env fish
source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults ; cleanWorkspace

set SP_PACKAGES $STORAGE_PATH/$ARANGODB_PACKAGES
set SP_SNIPPETS_CO $STORAGE_PATH/Snippets/Community
set SP_SNIPPETS_EN $STORAGE_PATH/Snippets/Enterprise
set SP_SOURCE $STORAGE_PATH/Source

set WS_PACKAGES $WORKSPACE/release/packages
set WS_SNIPPETS $WORKSPACE/release/snippets
set WS_SOURCE $WORKSPACE/release/source

switchBranches "$RELEASE_TAG" "$RELEASE_TAG" true
and findArangoDBVersion
and echo "checking source directory '$WS_PACKAGES'"
and test -d $WS_PACKAGES
and echo "checking source directory '$WS_SNIPPETS'"
and test -d $WS_SNIPPETS
and echo "checking source directory '$WS_SOURCE'"
and test -d $WS_SOURCE
and echo "checking destination directory '$SP_PACKAGES'"
and test -d $SP_PACKAGES
and echo "checking destination directory '$SP_SNIPPETS'"
and test -d $SP_SNIPPETS/Community
and test -d $SP_SNIPPETS/Enterprise
and echo "checking destination directory '$SP_SOURCE'"
and test -d $SP_SOURCE
and echo "========== COPYING PACKAGES =========="
and tar -C $WORKSPACE/release -c -f - packages | tar -C $SP_PACKAGES -x -v -f -
and echo "========== COPYING SOURCE =========="
and tar -C $WORKSPACE/release -c -f - source | tar -C $SP_SOURCE -x -v -f -
and echo "========== COPYING SNIPPETS =========="
and cp -v $WS_SNIPPETS/download-arangodb3-debian.html  $SP_SNIPPETS_CO/download-debian.html
and cp -v $WS_SNIPPETS/download-arangodb3-debian.html  $SP_SNIPPETS_CO/download-ubuntu.html
and cp -v $WS_SNIPPETS/download-arangodb3-rpm.html     $SP_SNIPPETS_CO/download-centos.html
and cp -v $WS_SNIPPETS/download-arangodb3-rpm.html     $SP_SNIPPETS_CO/download-fedora.html
and cp -v $WS_SNIPPETS/download-arangodb3-rpm.html     $SP_SNIPPETS_CO/download-opensuse.html
and cp -v $WS_SNIPPETS/download-arangodb3-rpm.html     $SP_SNIPPETS_CO/download-redhat.html
and cp -v $WS_SNIPPETS/download-arangodb3-rpm.html     $SP_SNIPPETS_CO/download-sle.html
and cp -v $WS_SNIPPETS/download-arangodb3-linux.html   $SP_SNIPPETS_CO/download-linux-general.html
and cp -v $WS_SNIPPETS/download-arangodb3-macosx.html  $SP_SNIPPETS_CO/download-macosx.html
and cp -v $WS_SNIPPETS/download-docker-community.html  $SP_SNIPPETS_CO/download-docker.html
and cp -v $WS_SNIPPETS/download-source.html            $SP_SNIPPETS_CO/download-source.html
and cp -v $WS_SNIPPETS/download-arangodb3e-debian.html $SP_SNIPPETS_EN/download-debian.html
and cp -v $WS_SNIPPETS/download-arangodb3e-debian.html $SP_SNIPPETS_EN/download-ubuntu.html
and cp -v $WS_SNIPPETS/download-arangodb3e-rpm.html    $SP_SNIPPETS_EN/download-centos.html
and cp -v $WS_SNIPPETS/download-arangodb3e-rpm.html    $SP_SNIPPETS_EN/download-fedora.html
and cp -v $WS_SNIPPETS/download-arangodb3e-rpm.html    $SP_SNIPPETS_EN/download-opensuse.html
and cp -v $WS_SNIPPETS/download-arangodb3e-rpm.html    $SP_SNIPPETS_EN/download-redhat.html
and cp -v $WS_SNIPPETS/download-arangodb3e-rpm.html    $SP_SNIPPETS_EN/download-sle.html
and cp -v $WS_SNIPPETS/download-arangodb3e-linux.html  $SP_SNIPPETS_EN/download-linux-general.html
and cp -v $WS_SNIPPETS/download-arangodb3e-macosx.html $SP_SNIPPETS_EN/download-macosx.html
and cp -v $WS_SNIPPETS/download-docker-enterprise.html $SP_SNIPPETS_EN/download-docker.html

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; unlockDirectory
exit $s
