#!/bin/sh
getent group arangodb > /dev/null || addgroup -S arangodb
getent passwd arangodb > /dev/null || adduser -S -G arangodb -D -h /usr/share/arangodb3 -H -s /bin/false -g "ArangoDB Application User" arangodb

install -o arangodb -g arangodb -m 755 -d /var/lib/arangodb3
install -o arangodb -g arangodb -m 755 -d /var/lib/arangodb3-apps
install -o arangodb -g arangodb -m 755 -d /var/log/arangodb3

