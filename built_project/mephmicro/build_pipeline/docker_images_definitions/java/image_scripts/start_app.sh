/data/join_jars.sh

echo "------------- STARTING APP WITH ($SPRING_PROFILES_ACTIVE)-------------------";
unzip -l /data/$FINAL_JAR
echo "----------------------------------------------------------------------------";
JAVA_OPTS="-Dspring.profiles.active=$SPRING_PROFILES_ACTIVE"
java -jar $JAVA_OPTS /data/$FINAL_JAR
