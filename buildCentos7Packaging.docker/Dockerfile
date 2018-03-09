FROM centos:7
MAINTAINER Max Neunhoeffer <max@arangodb.com>

RUN yum update -y && yum install -y gcc make rpm-build wget && cd /etc/yum.repos.d && wget http://download.opensuse.org/repositories/shells:fish:release:2/CentOS_7/shells:fish:release:2.repo && yum update -y && yum install -y fish && mkdir /root/{SPECS,

COPY ./scripts /scripts

CMD [ "/bin/bash" ]
