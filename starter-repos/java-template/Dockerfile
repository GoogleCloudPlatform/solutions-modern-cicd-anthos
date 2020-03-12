FROM adoptopenjdk/openjdk13:jre-13.0.2_8-alpine
COPY target/app.jar app.jar
EXPOSE 8080
CMD java -Dcom.sun.management.jmxremote -noverify ${JAVA_OPTS} -jar app.jar