FROM openjdk:8u151-jdk-alpine3.7

MAINTAINER Daniel Luque

ARG GIT_USER
ARG GIT_PASSWORD


RUN apk update && \
    apk upgrade && \
    apk add --no-cache nss && \
    apk add git
RUN apk add maven --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
	&& rm -rf /var/cache/apk/*

ENV MAVEN_HOME /usr/share/java/maven-3
ENV PATH $PATH:$MAVEN_HOME/bin

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

RUN cd /tmp && \
    wget --no-check-certificate -O tomcat8.zip https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.28/bin/apache-tomcat-8.5.28.zip && \
    unzip tomcat8.zip && \
    echo "--- LS ----" && \
     ls . && \
    cd ./apache-tomcat-8.5.28 && \
    chmod 777 bin/*.sh && \
    mv * $CATALINA_HOME && \
    rm -R $CATALINA_HOME/webapps/* && \
    ls -la $CATALINA_HOME/webapps

RUN mkdir /data && \
    cd /data &&\
    #echo "Descargamos ... https://$GIT_USER:$GIT_PASSWORD@jira.mangodev.net/stash/scm/sb/mnghttpmockserver.git" && \
    git clone https://$GIT_USER:$GIT_PASSWORD@jira.mangodev.net/stash/scm/sb/mnghttpmockserver.git && \
    echo "Repositorio clonado ..." && \
    cd mnghttpmockserver && \
    git checkout develop && \
    mvn package && \
    mv ./target/*.war $CATALINA_HOME/webapps/ROOT.war && \
    ls -la $CATALINA_HOME/webapps

WORKDIR $CATALINA_HOME/bin

EXPOSE 8080
CMD ["catalina.sh", "run"]