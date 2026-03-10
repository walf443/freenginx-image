FROM golang:1.26-trixie AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    git \
    mercurial \
    patch \
    && rm -rf /var/lib/apt/lists/*

RUN go install github.com/cubicdaiya/nginx-build@latest

COPY configure.sh /tmp/configure.sh
RUN chmod +x /tmp/configure.sh

ARG FREENGINX_VERSION=1.29.5
RUN nginx-build -d /tmp/nginx-build \
    -freenginx \
    -freenginxversion=${FREENGINX_VERSION} \
    -c /tmp/configure.sh \
    -zlib \
    && cd /tmp/nginx-build/freenginx/${FREENGINX_VERSION}/freenginx-${FREENGINX_VERSION} \
    && make install

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    openssl \
    libpcre2-8-0 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/nginx /var/cache/nginx

COPY --from=builder /usr/local/nginx /usr/local/nginx

RUN ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin/nginx

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
