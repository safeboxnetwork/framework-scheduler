# FROM alpine:latest AS redis-source

# ARG REDIS_VERSION="7.2.4"
# ARG REDIS_DOWNLOAD_URL="http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
# RUN apk add --update --no-cache --virtual build-deps gcc make linux-headers musl-dev tar openssl-dev pkgconfig
# RUN wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" && \
#     mkdir -p /usr/src/redis && \
#     tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 && \
#     cd /usr/src/redis/src && \
#     make BUILD_TLS=yes MALLOC=libc redis-cli

FROM alpine:latest

# COPY --from=redis-source /usr/src/redis/src/redis-cli /usr/bin/redis-cli
# RUN chmod +x /usr/bin/redis-cli

RUN apk add --update --no-cache docker-cli wget curl dos2unix jq openssl git coreutils inotify-tools acl apache2-utils

COPY scripts/scheduler/*.sh /scripts/
RUN find ./scripts -name "*.sh" | xargs dos2unix
RUN ["chmod", "+x", "-R", "/scripts/"]

ENTRYPOINT ["/scripts/entrypoint.sh"]
