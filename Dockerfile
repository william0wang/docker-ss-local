#
# Dockerfile for shadowsocks-libev
#

FROM alpine
MAINTAINER William Wang <william@10ln.com>

ARG SS_VER=3.0.6
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SS_VER/shadowsocks-libev-$SS_VER.tar.gz

ENV SERVER_ADDR=
ENV LOCAL_ADDR 0.0.0.0
ENV SERVER_PORT 8388
ENV LOCAL_PORT 8668
ENV PASSWORD=
ENV METHOD      aes-256-cfb
ENV TIMEOUT     300

RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                autoconf \
                                build-base \
                                curl \
                                libev-dev \
                                libtool \
                                linux-headers \
                                udns-dev \
                                libsodium-dev \
                                mbedtls-dev \
                                pcre-dev \
                                tar \
                                udns-dev && \
    cd /tmp && \
    curl -sSL $SS_URL | tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    rm -rf /tmp/*

USER nobody

EXPOSE $LOCAL_PORT/tcp $LOCAL_PORT/udp

CMD ss-local  -s $SERVER_ADDR \
              -p $SERVER_PORT \
              -b $LOCAL_ADDR \
              -l $LOCAL_PORT \
              -k $PASSWORD \
              -m $METHOD \
              -t $TIMEOUT \
              -u
