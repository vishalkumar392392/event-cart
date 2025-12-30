# ---- Build Stage ----
FROM amazoncorretto:17-alpine AS builder

WORKDIR /app

# Copy only necessary files first (faster Docker caching)
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

RUN ./mvnw dependency:go-offline

# Copy project source
COPY src ./src

# Build the Spring Boot app (skip tests for speed)
RUN ./mvnw clean package -DskipTests

# ---- Runtime Stage ----
FROM amazoncorretto:17-alpine

WORKDIR /app

# Copy final jar from build stage
COPY --from=builder /app/target/*.jar app.jar

# Expose Spring Boot app port
EXPOSE 8081

# Run Spring Boot on port 8081
ENTRYPOINT ["java", "-jar", "app.jar", "--server.port=8081"]