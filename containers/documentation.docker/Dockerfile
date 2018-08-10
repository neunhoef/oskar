FROM debian:stretch
MAINTAINER ArangoDB Hackers <hacker@arangodb.com>

#set proper shell
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install base dependencies
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        git \
        libssl-dev \
        wget \
        rsync \
        tree \
        && apt-get clean

#python
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        python \
        python-setuptools \
        python-pip \
        python-argparse \
        && apt-get clean
#doc
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        git \
        calibre-bin \
        tar \
        ditaa \
        && apt-get clean

# get nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 8.11.3
WORKDIR $NVM_DIR
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

WORKDIR /root
RUN wget https://raw.githubusercontent.com/ObiWahn/config/add3758b5437802d89241363c4f78547ed93304e/etc/skel.obi/.bashrc.d/all/bash_lib

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN pip install lockfile

COPY setup_gitbook /setup_gitbook
RUN /setup_gitbook

COPY setup /setup
RUN /setup

COPY entrypoint /root/entrypoint
COPY build_documentation /root/build_documentation
COPY oskar.bash /root/oskar.bash
COPY buildLib /root/buildLib

ENTRYPOINT [ "/root/entrypoint" ]

#EXPOSE 8529
#CMD [ "arangod" ]
