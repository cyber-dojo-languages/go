FROM cyberdojofoundation/alpine_glibc
LABEL maintainer=jon@jaggersoft.com

# set up nsswitch.conf for Go's "netgo" implementation
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN  echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GOLANG_VERSION 1.13.4

RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
    ca-certificates \
    git \
	; \
	wget -O go.tgz "https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz"; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
