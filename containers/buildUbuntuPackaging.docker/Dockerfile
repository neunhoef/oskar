FROM ubuntu:18.04
MAINTAINER Max Neunhoeffer <max@arangodb.com>

RUN apt-get update && apt-get install -y fish sudo debhelper debconf && apt-get clean

COPY ./scripts /scripts

CMD [ "/usr/bin/fish" ]
