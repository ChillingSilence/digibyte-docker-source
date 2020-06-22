# digibyte-docker-source
Run DigiByte easily from within a Docker image, built completely from source

Simply run:
<pre>git clone https://github.com/DigiByte-Core/digibyte-docker-source
cd digibyte-docker-source
docker build -t digibyte-source:latest .
docker run digibyte-source:latest</pre>

NOTE: This is built --without-qt so there is no GUI

This will download the latest release specified in the file (which can easily be tweaked manually) and get it all spun up and running, built from source on Ubuntu 20.04.
It's also very easy to run it on testnet etc by tweaking the variables at the top of the Dockerfile

## Wallet file format compatibility
Note that this intentionally builds using <pre>--with-incompatible-bdb</pre> to install BerkeleyDB 5.1. This is incompatible with BerkeleyDB 4.8 (As per BTC and other code forks). You can customize this yourself if desired.
