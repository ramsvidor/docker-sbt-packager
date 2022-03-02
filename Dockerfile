FROM debian:bullseye-slim

ARG GRAALVM_VERSION="22.0.0.2"
ARG JDK_VERSION="11"
ARG SCALA_VERSION="2.13.8"
ARG SBT_VERSION="1.6.2"
ARG APPUSER="marvin"
ARG VCS_REF
ARG VCS_URL
ARG BUILD_DATE

LABEL maintainer="Ramses Vidor <ramsvidor@gmail.com>" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="${VCS_URL}" \
      org.label-schema.build-date="${BUILD_DATE}" \
      com.ramsesvidor.license="Apache-2.0"

ENV LANG="C.UTF-8" \
    JAVA_HOME="/usr/lib/java/graalvm-ce-java${JDK_VERSION}-${GRAALVM_VERSION}" \
    SCALA_HOME="/usr/lib/scala/scala-${SCALA_VERSION}"
ENV PATH="${JAVA_HOME}/bin:${SCALA_HOME}/bin:${PATH}"

RUN apt-get -qq update; \
    apt-get -qq install --no-install-recommends wget ca-certificates p11-kit fakeroot gnupg2 build-essential lintian; \
    echo "deb [signed-by=/usr/share/keyrings/sbt-archive-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list; \
    echo "deb [signed-by=/usr/share/keyrings/sbt-archive-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list; \
    wget -qO- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --dearmor | tee /usr/share/keyrings/sbt-archive-keyring.gpg; \
    mkdir -m 755 -p "/usr/lib/java"; \
    mkdir -m 755 -p "/usr/lib/scala"; \
    wget -qO- "https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/graalvm-ce-java${JDK_VERSION}-linux-amd64-${GRAALVM_VERSION}.tar.gz" \
        | tar xfz - -C "/usr/lib/java"; \
    wget -qO- "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" \
             | tar xfz - -C /usr/lib/scala && \
             rm -f "${SCALA_HOME}/bin/*.bat"; \
    apt-get update -qq; \
    apt-get install -qq --no-install-recommends sbt; \
    apt-get autoremove -qq --purge; \
    adduser --quiet --system --group --home "/var/lib/${APPUSER}" --shell /bin/bash "${APPUSER}" && \
             install -d -m 0755 -o "${APPUSER}" -g "${APPUSER}" "/var/log/${APPUSER}"; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

USER "${APPUSER}"
WORKDIR "/var/lib/${APPUSER}"

RUN sbt sbtVersion; \
    echo "scalaVersion := \"${SCALA_VERSION}\"" | tee build.sbt; \
    echo "case object Temp" | tee Temp.scala; \
    sbt compile; \
    rm -rf *
