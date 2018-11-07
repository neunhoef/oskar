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

set s 0

mv $SRC/arangodb3_*.deb $DST/release/packages/Community/Linux ; or set s 1
mv $SRC/arangodb3-*.deb $DST/release/packages/Community/Linux ; or set s 1
mv $SRC/arangodb3-*.rpm $DST/release/packages/Community/Linux ; or set s 1
mv $SRC/arangodb3-linux-*.tar.gz $DST/release/packages/Community/Linux ; or set s 1

mv $SRC/arangodb3-*.dmg $DST/release/packages/Community/MacOSX ; or set s 1
mv $SRC/arangodb3-macosx-*.tar.gz $DST/release/packages/Community/MacOSX ; or set s 1

mv $SRC/ArangoDB3-*.exe $DST/release/packages/Community/Windows ; or set s 1
mv $SRC/ArangoDB3-*.zip $DST/release/packages/Community/Windows ; or set s 1

mv $SRC/arangodb3e_*.deb $DST/release/packages/Enterprise/Linux ; or set s 1
mv $SRC/arangodb3e-*.deb $DST/release/packages/Enterprise/Linux ; or set s 1
mv $SRC/arangodb3e-*.rpm $DST/release/packages/Enterprise/Linux ; or set s 1
mv $SRC/arangodb3e-linux-*.tar.gz $DST/release/packages/Enterprise/Linux ; or set s 1

mv $SRC/arangodb3e-*.dmg $DST/release/packages/Enterprise/MacOSX ; or set s 1
mv $SRC/arangodb3e-macosx-*.tar.gz $DST/release/packages/Enterprise/MacOSX ; or set s 1

mv $SRC/ArangoDB3e-*.exe $DST/release/packages/Enterprise/Windows ; or set s 1
mv $SRC/ArangoDB3e-*.zip $DST/release/packages/Enterprise/Windows ; or set s 1

mv $SRC/*.html $DST/release/snippets ; or set s 1

exit $s