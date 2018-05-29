#!/usr/bin/env fish

## unlock keychain to make code signing work
if test -z "$MACOS_ADMIN_KEYCHAIN_PASS"
  echo Need MACOS_ADMIN_KEYCHAIN_PASS environment variable set!
  exit 1
end

security unlock-keychain -p $MACOS_ADMIN_KEYCHAIN_PASS ~/Library/Keychains/login.keychain-db

## NOTE: This script can obly ba called on an existing Build directory
cd $INNERWORKDIR/ArangoDB/build
make packages
# and move to folder
and make copy_packages
and echo Package build in $INNERWORKDIR
