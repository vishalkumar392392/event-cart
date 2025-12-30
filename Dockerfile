FROM amazoncorretto:17-alpine
WORKDIR /app

COPY eventcart-0.0.2-SNAPSHOT.jar app.jar

EXPOSE 80

ENTRYPOINT ["java", "-jar", "app.jar", "--server.port=8081"]