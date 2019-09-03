# Extendemos la imagen TOMCAT8 de Capside
#FROM registry.docker.pre.mango.com/capside/tomcat8:8.0.50
FROM 495248209902.dkr.ecr.eu-west-1.amazonaws.com/capside/tomcat8:latest

# Exponemos los puertos HTTP, AJP y JMX
EXPOSE 8080
EXPOSE 8009
EXPOSE 8090

# Parámetros JAVA
ENV JAVA_OPTS "\${ENV_JAVA_OPTS} -DENTORNO=\${ACTIVE_PROFILES} -Dspring.profiles.active=\${ACTIVE_PROFILES} "
# Necesitamos configurar la timeZone para poder apuntar a la base de datos
ENV TZ "Europe/Madrid"

# Añadimos el WAR dentro del webapps del tomcat
#COPY $ORIGIN_JAR /data/$DESTINATION_JAR
ADD ./image_scripts/*.sh /data/
RUN chmod +x /data/*.sh
#RUN /data/init_env.sh

RUN rm -R /usr/local/tomcat/webapps/*
ADD tmp_for_jars/ROOT.war /usr/local/tomcat/webapps/

HEALTHCHECK --interval=10s --timeout=3s --retries=10 CMD /data/health.sh

CMD ["/bin/bash","/data/init_env.sh"]