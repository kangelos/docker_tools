# original idea  from https://hub.docker.com/r/testnet/litecoin/dockerfile
# since I have no clue what litecoin is supposed to do

FROM ubuntu:20.04

# litecoin deps
RUN apt-get update && apt-get install -y \
    curl tar  vim  sudo

# create a non-root user
RUN adduser --disabled-login --gecos "" lite --shell /bin/bash

# litecoin
WORKDIR /home/lite
RUN curl -s  https://download.litecoin.org/litecoin-0.18.1/linux/litecoin-0.18.1-x86_64-linux-gnu.tar.gz \
    -o litecoin-0.18.1-x86_64-linux-gnu.tar.gz && \
  tar  xzvf litecoin-0.18.1-x86_64-linux-gnu.tar.gz 

# make lite user own the litecoin-testnet-box
RUN chown -R lite:lite /home/lite

# use the lite user when running the image
USER lite

# expose two daemon port
EXPOSE 9332 9333
ENTRYPOINT ["/home/lite/litecoin-0.18.1/bin/litecoind"]
