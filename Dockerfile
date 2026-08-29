# # FROM bellsoft/liberica-openjdk-debian:17

# # WORKDIR /app

# # COPY . .

# # CMD ["./gradlew", "bootRun", "--no-daemon"]


# # What you'll notice — and why this is still naive:

# # Slow start — every docker run re-triggers Gradle's wrapper download (first time), dependency resolution, and full compilation, before your app even starts listening. That's minutes of dead time on every container start, not just every code change.

# # Bloated image — the final image now carries a full JDK, the entire Gradle distribution, your source code, and every build-time dependency, none of which the running app actually needs. A JRE is enough to execute a compiled jar.

# # No layer caching for dependencies — because you COPY . . before running Gradle, any change to a single source file invalidates the cache and forces Gradle to re-resolve dependencies from scratch on the next build.


# # ------------------------------------------------------------------------------

# # FROM bellsoft/liberica-openjdk-debian:17
# # 
# # WORKDIR /app
# # 
# # COPY . .
# # 
# # RUN ./gradlew dependencies
# # 
# # CMD ["./gradlew", "bootRun", "--no-daemon"]

# # ------------------------------------------------------------------------------

# # FROM bellsoft/liberica-openjdk-debian:17

# # WORKDIR /app

# # COPY gradlew mvnw build.gradle mvnw.cmd ./app
 
# # RUN ./gradlew --no-dependencies dependencies

# # COPY . .
 
# # CMD ["./gradlew", "bootRun", "--no-daemon"]
# # 


# # -------------------------------------------------------------------------------------


# # ---------------- BUILD STAGE-----------------------

# # FROM bellsoft/liberica-openjdk-debian:17 AS build
# # 
# # WORKDIR /app
# # 
# # COPY . .
# # 
# # RUN ./gradlew bootJar --no-daemon
# # 
# # 
# # # ----------- RUNTIME STAGE -----------------------------
# # FROM bellsoft/liberica-openjre-debian:17-cds
# # 
# # WORKDIR /app
# # 
# # COPY --from=build /app/build/libs/*.jar app.jar
# # 
# # EXPOSE 8080
# # 
# # CMD ["java", "-jar", "app.jar"]

# # ---- Build stage ----
# # Pinned to an exact patch version + vendor, not a floating major tag like
# # ":17" or ":25" — those get repointed to new patch releases over time,
# # which means the "same" Dockerfile can silently pull a different JDK
# # build on a different day. Check the actual digest for your platform with:
# #   docker pull bellsoft/liberica-openjdk-debian:17.0.13
# #   docker inspect --format='{{.RepoDigests}}' bellsoft/liberica-openjdk-debian:17.0.13
# # and pin by @sha256:... instead of tag alone for full immutability.


# FROM bellsoft/liberica-openjdk-debian:17.0.13 AS build

# WORKDIR /app

# # Copy only what's needed to resolve dependencies first. This layer is
# # now independent of source code changes — Gradle re-downloads deps
# # only when these specific files change, giving predictable, repeatable
# # dependency resolution across builds and across machines.

# COPY gradlew ./

# COPY gradle ./gradle

# COPY build.gradle settings.gradle ./

# RUN chmod +x gradlew && ./gradlew --no-daemon dependencies

# # Now copy source and build. Using --no-daemon avoids a background
# # process whose warm state could differ between build runs; every build
# # starts from the same clean state.

# COPY src ./src
# RUN ./gradlew --no-daemon bootJar

# # ---- Runtime stage ----
# # Match the JDK version used in the build stage exactly (both 17.0.13)
# # so runtime behavior can't drift from what was actually compiled/tested.

# FROM bellsoft/liberica-openjre-debian:17.0.13-cds

# WORKDIR /app

# COPY --from=build /app/build/libs/*.jar app.jar

# EXPOSE 8080

# CMD ["java", "-jar", "app.jar"]


# # ---- Build stage ----
# FROM bellsoft/liberica-openjdk-debian:17.0.13 AS build
# WORKDIR /app

# COPY gradlew ./
# COPY gradle ./gradle
# COPY build.gradle settings.gradle ./
# RUN chmod +x gradlew && ./gradlew --no-daemon dependencies

# COPY src ./src
# RUN ./gradlew --no-daemon bootJar

# # ---- Runtime stage ----
# FROM bellsoft/liberica-openjre-debian:17.0.13-cds
# WORKDIR /app

# RUN groupadd --system spring && useradd --system --gid spring --no-create-home --shell /usr/sbin/nologin spring

# COPY --from=build --chown=spring:spring /app/build/libs/*.jar app.jar

# USER spring

# EXPOSE 8080

# CMD ["java", "-jar", "app.jar"]


# # Notes on the implementation (kept the two stage-header comments since they're just navigational, not explanatory):

# # Build stage split into two COPY blocks: gradlew/gradle//build.gradle/settings.gradle come in first and get their own RUN ... dependencies step, before src/ is copied. Docker caches each layer independently — editing application code invalidates only the final COPY src + bootJar layers; the dependency-download layer stays cached and doesn't re-run.

# # Pinned to 17.0.13 on both stages (build and runtime), matching your build.gradle toolchain requirement exactly, and avoiding the version drift that comes from floating tags like :17 or :25.

# # groupadd/useradd creates a dedicated spring system user with no home directory and nologin shell — used only to run the app, never for interactive access.

# # COPY --from=build --chown=spring:spring pulls the built jar from the first stage into the final image and sets ownership in the same instruction, so no root-owned intermediate layer exists.

# # USER spring switches the container's runtime identity before CMD executes — the JVM process itself runs unprivileged, not as root.

# # Final image contains no JDK, no Gradle, no source code — only the JRE and the compiled jar, since everything else was left behind in the discarded build stage.

# ARG JAVA_VERSION=17.0.13
# ARG APP_NAME=spring-petclinic

# # ---- Build stage ----
# FROM bellsoft/liberica-openjdk-debian:${JAVA_VERSION} AS build
# WORKDIR /app

# COPY gradlew ./
# COPY gradle ./gradle
# COPY build.gradle settings.gradle ./
# RUN chmod +x gradlew && ./gradlew --no-daemon dependencies

# COPY src ./src
# RUN ./gradlew --no-daemon bootJar

# # ---- Runtime stage ----
# FROM bellsoft/liberica-openjre-debian:${JAVA_VERSION}-cds
# ARG APP_NAME
# WORKDIR /app

# RUN groupadd --system spring \
#     && useradd --system --gid spring --no-create-home --shell /usr/sbin/nologin spring

# COPY --from=build --chown=spring:spring /app/build/libs/*.jar app.jar

# USER spring

# EXPOSE 8080

# CMD ["java", "-jar", "app.jar"]

# LABEL org.opencontainers.image.title="${APP_NAME}"
# LABEL org.opencontainers.image.source="https://github.com/spring-projects/spring-petclinic"
# LABEL org.opencontainers.image.description="Spring Boot Petclinic application"





# #  Notes on the implementation:

# #  ARG JAVA_VERSION=17.0.13 at the top, referenced in both FROM lines — this is the single biggest maintainability win. Before, bumping the JDK version meant editing 17.0.13 in two separate places and hoping you didn't miss one (exactly the kind of drift that caused your earlier toolchain mismatch). Now it's one line to change, and both stages update together automatically. You can also override it at build time without touching the file: docker build --build-arg JAVA_VERSION=21.0.4 .

# #  ARG APP_NAME=spring-petclinic + LABEL metadata — bakes the image's identity, source repo, and purpose directly into the image itself. Anyone (including future-you) running docker inspect on this image months from now can tell what it is and where it came from, without needing to trace it back to a specific Dockerfile or README.

# #  Global ARG scoping: declaring JAVA_VERSION before the first FROM makes it available to every subsequent FROM line in the file — that's what lets both stages share the exact same version without redeclaring it per-stage.
  

# #  One tradeoff worth naming: this file now assumes the -cds suffix always exists for whatever JAVA_VERSION you set. If you ever bump to a version where BellSoft hasn't published a -cds variant, the runtime stage's FROM will fail to resolve — a reasonable price for the reuse, but worth knowing before a version bump surprises you.





