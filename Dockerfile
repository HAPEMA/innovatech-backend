# ========== STAGE 1: Build ==========
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copiar dependencias primero (cache de capas)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ========== STAGE 2: Runtime ==========
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Usuario no root (seguridad)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar solo el JAR desde el stage anterior
COPY --from=builder /app/target/*.jar app.jar

RUN chown appuser:appgroup app.jar

USER appuser

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
