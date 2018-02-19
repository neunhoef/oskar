#!/usr/bin/env fish
cd $INNERWORKDIR
for f in testreport* ; rm -f $f ; end
for f in .ccache* ; rm -rf $f ; end
rm -rf ArangoDB
