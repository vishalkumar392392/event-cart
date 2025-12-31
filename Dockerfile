# Use Amazon Corretto 21 on Alpine Linux
FROM amazoncorretto:21-alpine

# Set working directory
WORKDIR /app

# Copy the Spring Boot application JAR file
COPY eventcart-0.0.2-SNAPSHOT.jar app.jar

# Expose application port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar", "--server.port=8080"]