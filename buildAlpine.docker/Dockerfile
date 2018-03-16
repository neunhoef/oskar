FROM alpine:3.7
MAINTAINER Max Neunhoeffer <max@arangodb.com>

COPY ./tools/* /tools/

RUN /tools/install.sh

COPY ./scripts /scripts

CMD [ "/usr/bin/fish" ]
