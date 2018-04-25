#!/usr/bin/env fish

## NOTE: This script can obly ba called on an existing Build directory
cd $INNERWORKDIR/ArangoDB/build
make packages
# and move to folder
and make copy_packages
and echo Package build in $INNERWORKDIR
