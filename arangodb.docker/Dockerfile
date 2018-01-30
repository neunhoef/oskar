FROM alpine:3.7
MAINTAINER Max Neunhoeffer <max@arangodb.com>

COPY install.tar.gz /install.tar.gz
RUN cd / && tar xzvf install.tar.gz && strip /usr/sbin/arangod /usr/bin/arangoimport /usr/bin/arangosh /usr/bin/arangovpack /usr/bin/arangoexport /usr/bin/arangobench /usr/bin/arangodump /usr/bin/arangorestore && rm /install.tar.gz

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8529
CMD [ "arangod" ]
