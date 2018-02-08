FROM  cyberdojofoundation/ubuntu-build-essential:18.04
LABEL maintainer=jon@jaggersoft.com

RUN apt-get update
RUN apt-get install --yes golang

RUN go version | grep -q 1.9.4