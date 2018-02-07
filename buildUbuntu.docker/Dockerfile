FROM ubuntu:17.10
MAINTAINER Max Neunhoeffer <max@arangodb.com>

RUN apt-get update && apt-get install -y build-essential g++ cmake make bison flex libssl-dev python ccache git libjemalloc-dev vim exuberant-ctags gdb fish ruby ruby-httparty ruby-rspec psmisc libldap2-dev sudo && gem install persistent_httparty debhelper debconf && apt-get clean

COPY ./scripts /scripts

CMD [ "/usr/bin/fish" ]
