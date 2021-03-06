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
ARG LOCALTIMEZONE=Etc/UTC

# Set to 1 for running it in testnet mode
ARG TESTNET=0

# Do we want any blockchain pruning to take place? Set to 4096 for a 4GB blockchain prune.
# Alternatively set size=1 to prune with RPC call 'pruneblockchainheight <height>'
ARG PRUNESIZE=0

# Update apt cache and set tzdata to non-interactive or it will fail later.
# Also install essential dependencies for the build project.
RUN DEBIAN_FRONTEND="noninteractive" apt-get update \
  && apt-get -y install tzdata \
  && ln -fs /usr/share/zoneinfo/${LOCALTIMEZONE} /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata \
  && apt-get install -y wget git build-essential libtool autotools-dev automake \
  pkg-config curl python bsdmainutils


# Clone the Core wallet source from GitHub and checkout the version.
RUN git clone https://github.com/DigiByte-Core/digibyte/ --branch ${DGBVERSION} --single-branch

# Prepare the build process
# Build for x86_64-pc-linux-gnu as per https://github.com/DigiByte-Core/digibyte/tree/master/depends
RUN cd ${ROOTDATADIR}/digibyte \
        && cd depends \
        && make \
        && cd .. \
        && ./contrib/install_db4.sh `pwd` \
        && ./autogen.sh \
        && ./configure BDB_LIBS="-L${ROOTDATADIR}/digibyte/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${ROOTDATADIR}/digibyte/include" --prefix=$PWD/depends/x86_64-pc-linux-gnu \
        && make && make install


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

# Create digibyte.conf file
RUN echo -e "datadir=${ROOTDATADIR}/.digibyte/\n\
server=1\n\
prune=${PRUNESIZE}\n\
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

CMD /usr/local/bin/digibyted -conf=${ROOTDATADIR}/.digibyte/digibyte.conf
