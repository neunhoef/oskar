FROM ubuntu:17.10
MAINTAINER Max Neunhoeffer <max@arangodb.com>

RUN apt-get update && apt-get install -y build-essential g++ cmake make bison flex python ccache git libjemalloc-dev vim exuberant-ctags gdb fish ruby ruby-httparty ruby-rspec psmisc sudo debhelper debconf jq wget libdb-dev curl && gem install persistent_httparty && apt-get clean

COPY ./tools/* /tools/

RUN /tools/install.sh

COPY ./scripts /scripts

CMD [ "/usr/bin/fish" ]
