FROM debian:stretch
MAINTAINER Cajus Kamer <Cajus.Kamer@arcor.de>

ENV GLUON_SITE ffdo

ENV GLUON_TAG v2017.1.7
ENV GLUON_RELEASE 1.2.1

ENV GLUON_BRANCH stable
ENV GLUON_BROKEN 1
ENV GLUON_TARGETS ar71xx-generic ar71xx-nand ar71xx-tiny ar71xx-mikrotik mpc85xx-generic ramips-mt7621 x86-generic x86-64 

ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes

RUN apt-get update
RUN apt-get -y install --no-install-recommends adduser bash ca-certificates python wget file git subversion build-essential gawk unzip libncurses5-dev zlib1g-dev openssl libssl-dev bsdmainutils && apt-get clean

ADD build_all_lede.sh /usr/src/build_all_lede.sh
RUN chmod 777 /usr/src/build_all_lede.sh

RUN adduser --system --home /usr/src/build build
USER build
WORKDIR /usr/src/build
RUN git config --global user.email "technik@freifunk-dortmund.de"
RUN git config --global user.name "FFDO Gluon Build Container"

CMD ["/bin/bash", "/usr/src/build_all_lede.sh", "-g", "/usr/src/build/gluon/", "-s", "/usr/src/build/site/", "-o", "/usr/src/build/build/data/images.ffdo.de/ffdo/", "-B", "-t", "ar71xx-generic", "-t", "ar71xx-nand", "-t", "ar71xx-tiny", "-t", "ar71xx-mikrotik", "-t", "mpc85xx-generic", "-t", "ramips-mt7621", "-t", "x86-generic", "-t", "x86-64", "v2017.1.7", "1.2.1"]
