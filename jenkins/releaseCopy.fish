#!/usr/bin/env fish
set -xg SRC .
set -xg DST .

rm -rf $DST/release
and mkdir -p $DST/release/snippets
and for e in Community Enterprise
  for d in Linux Windows MacOSX
    mkdir -p $DST/release/packages/$e/$d
  end
end

and mv $SRC/arangodb3[_-]*.deb $DST/release/packages/Community/Linux
and mv $SRC/arangodb3[_-]*.rpm $DST/release/packages/Community/Linux
and mv $SRC/arangodb3-linux-*.tar.gz $DST/release/packages/Community/Linux

and mv $SRC/arangodb3-*.dmg $DST/release/packages/Community/MacOSX
and mv $SRC/arangodb3-macosx-*.tar.gz $DST/release/packages/Community/MacOSX

and mv $SRC/ArangoDB3-*.exe $DST/release/packages/Community/Windows
and mv $SRC/ArangoDB3-*.zip $DST/release/packages/Community/Windows

and mv $SRC/arangodb3e[_-]*.deb $DST/release/packages/Enterprise/Linux
and mv $SRC/arangodb3e[_-]*.rpm $DST/release/packages/Enterprise/Linux
and mv $SRC/arangodb3e-linux-*.tar.gz $DST/release/packages/Enterprise/Linux

and mv $SRC/arangodb3e-*.dmg $DST/release/packages/Enterprise/MacOSX
and mv $SRC/arangodb3e-macosx-*.tar.gz $DST/release/packages/Enterprise/MacOSX

and mv $SRC/ArangoDB3e-*.exe $DST/release/packages/Enterprise/Windows
and mv $SRC/ArangoDB3e-*.zip $DST/release/packages/Enterprise/Windows

and mv $SRC/*.html $DST/release/snippets
