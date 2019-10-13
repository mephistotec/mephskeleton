FROM openjdk:8-jre-alpine

MAINTAINER mephistos

ARG ORIGIN_JAR
ARG DESTINATION_JAR
ARG BUILD_ID_INFO
ENV DESTINATION_JAR $DESTINATION_JAR
ENV BUILD_ID_INFO $BUILD_ID_INFO

#RUN apk update \
# && apk add jq \
# && apk add curl \
# && rm -rf /var/cache/apk/*

#RUN apk add --no-cache bash
#RUN  "Europe/Madrid" > /etc/timezone

VOLUME /var/log /var/log
COPY $ORIGIN_JAR /data/$DESTINATION_JAR
ADD ./image_scripts/*.sh /data/
RUN chmod 777 /data/*.sh
HEALTHCHECK --interval=10s --timeout=3s --retries=10 CMD /data/health.sh
CMD . /data/start_app.sh
