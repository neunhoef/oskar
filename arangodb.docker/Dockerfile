FROM alpine:3.7
MAINTAINER Max Neunhoeffer <max@arangodb.com>

COPY ../work/ArangoDB/build/install.tar.gz /install.tar.gz
RUN cd / && tar xzvf install.tar.gz && rm /install.tar.gz

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8529
CMD [ "arangod" ]
