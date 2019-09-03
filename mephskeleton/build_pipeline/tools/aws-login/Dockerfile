FROM amd64/ubuntu

MAINTAINER Daniel Luque

RUN apt-get update
RUN apt-get -y install curl wget sudo
RUN curl -s https://www.sys.mango/bin/aws-login/install.sh | bash -
CMD aws-login; cat /tmp/bash_file.sh
