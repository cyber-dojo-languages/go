FROM  cyberdojofoundation/ubuntu-build-essential:17.04
LABEL maintainer=jon@jaggersoft.com

RUN apt-get update
RUN apt-get install --yes golang

RUN go version | grep -q 1.7.4