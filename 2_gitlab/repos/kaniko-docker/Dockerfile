FROM gcr.io/kaniko-project/executor:latest as kaniko

FROM docker:19-git
COPY --from=kaniko /kaniko/executor /usr/local/bin
RUN mkdir -p /kaniko && \
    ln -sf /usr/local/bin/executor /kaniko/executor