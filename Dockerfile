FROM ubuntu:focal
USER root
WORKDIR /data
ARG ROOTDATADIR=/data
ARG RPCUSERNAME=user
ARG RPCPASSWORD=pass
ARG VERSION=7.17.2
ARG ARCH=x86_64

ARG MAINP2P=12024
ARG MAINRPC=14022
ARG TESTP2P=12026
ARG TESTRPC=14023

# Set to 1 for running it in testnet mode
ARG TESTNET=0

# We need some essential things to get building with
RUN apt-get update && apt-get install -y wget git build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev libdb-dev libdb++-dev

# Clone the Core wallet source from GitHub and checkout the version
RUN git clone https://github.com/DigiByte-Core/digibyte/
RUN cd digibyte
RUN git checkout -b ${VERSION}

# Start the build process
./autogen.sh
./configure --without-gui --with-incompatible-bdb
make
make install

RUN mkdir -vp ${ROOTDATADIR}/.digibyte
VOLUME ${ROOTDATADIR}/.digibyte

# Allow Mainnet P2P comms
EXPOSE 12024

# Allow Mainnet RPC
EXPOSE 14022

# Allow Testnet RPC
EXPOSE 14023

# Allow Testnet P2P comms
EXPOSE 12026

RUN echo -e "datadir=${ROOTDATADIR}/.digibyte/\n\
server=1\n\
maxconnections=300\n\
rpcallowip=127.0.0.1\n\
daemon=1\n\
rpcuser=${RPCUSERNAME}\n\
rpcpassword=$RPCPASSWORD}\n\
txindex=1\n\
# Uncomment below if you need Dandelion disabled for any reason but it is left on by default intentionally\n\
#disabledandelion=1\n\
testnet=${TESTNET}\n" > ${ROOTDATADIR}/.digibyte/digibyte.conf

# Create symlinks
RUN ln -s ${ROOTDATADIR}/digibyte-${VERSION}/src/digibyted /usr/bin/digibyted
RUN ln -s ${ROOTDATADIR}/digibyte-${VERSION}/src/digibyte-cli /usr/bin/digibyte-cli

CMD /usr/bin/digibyted
