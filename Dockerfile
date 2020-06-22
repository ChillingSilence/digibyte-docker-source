FROM ubuntu:focal
USER root
WORKDIR /data
ARG ROOTDATADIR=/data
ARG RPCUSERNAME=user
ARG RPCPASSWORD=pass
ARG DGBVERSION=7.17.2
ARG ARCH=x86_64

ARG MAINP2P=12024
ARG MAINRPC=14022
ARG TESTP2P=12026
ARG TESTRPC=14023

# You can confirm your timezone by setting the TZ database name field from:
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG LOCALTIMEZONE=Pacific/Auckland

# Set to 1 for running it in testnet mode
ARG TESTNET=0

# Do we want any blockchain pruning to take place? Set to 4096 for a 4GB blockchain prune.
# Alternatively set size=1 to prune with RPC call 'pruneblockchainheight <height>'
ARG PRUNESIZE=0

# First we update the apt cache
RUN apt-get update

# Set tzdata to non-interactive or it will fail later
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN ln -fs /usr/share/zoneinfo/${LOCALTIMEZONE} /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

# We need some essential things to get building with
RUN apt-get update && apt-get install -y wget git build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev libdb-dev libdb++-dev

# Clone the Core wallet source from GitHub and checkout the version
RUN git clone https://github.com/DigiByte-Core/digibyte/ --branch ${DGBVERSION} --single-branch

# Start the build process
# For some reason it wants me to change in to it before each running command so I'll come back and revisit this later
RUN cd ${ROOTDATADIR}/digibyte && ./autogen.sh
RUN cd ${ROOTDATADIR}/digibyte && ./configure --without-gui --with-incompatible-bdb
RUN cd ${ROOTDATADIR}/digibyte && make
RUN cd ${ROOTDATADIR}/digibyte && make install

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
prune=${PRUNESIZE}
maxconnections=300\n\
rpcallowip=127.0.0.1\n\
daemon=1\n\
rpcuser=${RPCUSERNAME}\n\
rpcpassword=$RPCPASSWORD}\n\
txindex=0\n\
# Uncomment below if you need Dandelion disabled for any reason but it is left on by default intentionally\n\
#disabledandelion=1\n\
testnet=${TESTNET}\n" > ${ROOTDATADIR}/.digibyte/digibyte.conf

# Create symlinks shouldn't be needed as they're installed in /usr/local/bin/
#RUN ln -s /usr/local/bin/digibyted /usr/bin/digibyted
#RUN ln -s /usr/local/bin/digibyte-cli /usr/bin/digibyte-cli

CMD /usr/local/bin/digibyted
