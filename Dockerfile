FROM ubuntu:17.10
MAINTAINER Max Neunhoeffer <max@arangodb.com>

RUN apt-get update && apt-get install -y build-essential g++ cmake make bison flex libssl-dev python ccache git libjemalloc-dev vim exuberant-ctags gdb fish && ccache -M 16G

COPY ./scripts /scripts

ENTRYPOINT [ "/scripts/wait.sh" ]
