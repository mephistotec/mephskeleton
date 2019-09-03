FROM amd64/ubuntu
MAINTAINER Daniel Luque
COPY ./binaries/* /
RUN apt-get update && \
    apt-get install -y awscli jq  && \
    chmod +x /krav*

