# FROM bellsoft/liberica-openjdk-debian:17

# WORKDIR /app

# COPY . .

# CMD ["./gradlew", "bootRun", "--no-daemon"]


# What you'll notice — and why this is still naive:

# Slow start — every docker run re-triggers Gradle's wrapper download (first time), dependency resolution, and full compilation, before your app even starts listening. That's minutes of dead time on every container start, not just every code change.

# Bloated image — the final image now carries a full JDK, the entire Gradle distribution, your source code, and every build-time dependency, none of which the running app actually needs. A JRE is enough to execute a compiled jar.

# No layer caching for dependencies — because you COPY . . before running Gradle, any change to a single source file invalidates the cache and forces Gradle to re-resolve dependencies from scratch on the next build.


# ------------------------------------------------------------------------------

# FROM bellsoft/liberica-openjdk-debian:17
# 
# WORKDIR /app
# 
# COPY . .
# 
# RUN ./gradlew dependencies
# 
# CMD ["./gradlew", "bootRun", "--no-daemon"]

# ------------------------------------------------------------------------------

# FROM bellsoft/liberica-openjdk-debian:17

# WORKDIR /app

# COPY gradlew mvnw build.gradle mvnw.cmd ./app
 
# RUN ./gradlew --no-dependencies dependencies

# COPY . .
 
# CMD ["./gradlew", "bootRun", "--no-daemon"]
# 


# -------------------------------------------------------------------------------------


# ---------------- BUILD STAGE-----------------------

# FROM bellsoft/liberica-openjdk-debian:17 AS build
# 
# WORKDIR /app
# 
# COPY . .
# 
# RUN ./gradlew bootJar --no-daemon
# 
# 
# # ----------- RUNTIME STAGE -----------------------------
# FROM bellsoft/liberica-openjre-debian:17-cds
# 
# WORKDIR /app
# 
# COPY --from=build /app/build/libs/*.jar app.jar
# 
# EXPOSE 8080
# 
# CMD ["java", "-jar", "app.jar"]


