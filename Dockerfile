FROM debian:stretch
MAINTAINER Cajus Kamer <Cajus.Kamer@arcor.de>

ENV GLUON_TAG_DOCKER_ENV v2020.1.2
ENV GLUON_RELEASE_DOCKER_ENV 3.0.0
ENV GLUON_BROKEN_DOCKER_ENV 1

ENV GLUON_TARGETS_DOCKER_ENV ar71xx-generic ar71xx-nand ar71xx-tiny ar71xx-mikrotik mpc85xx-generic ramips-mt7621 x86-generic x86-64 

ENV BUILD_GLUON_DIR_DOCKER_ENV /usr/src/build/gluon
ENV BUILD_LOG_DIR_DOCKER_ENV /usr/src/build/log
ENV BUILD_OUTPUT_DIR_DOCKER_ENV /usr/src/build/build
ENV BUILD_IMAGE_DIR_PREFIX_DOCKER_ENV /data/images.ffdo.de/ffdo_ng/domaenen

# ENV TELEGRAM_NOTIFY_CHATID_DOCKER_ENV=
ENV TELEGRAM_AUTH_TOKEN_DOCKER_ENV=/usr/src/ChatAuthTokens/telegram.authToken
ENV TELEGRAM_CHAT_ID_DOCKER_ENV=/usr/src/ChatAuthTokens/telegram.chatID

ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update
RUN apt-get -y install --no-install-recommends adduser ca-certificates python python3 wget file git subversion build-essential gawk unzip libncurses5-dev zlib1g-dev openssl libssl-dev bsdmainutils && apt-get clean

ADD docker-build.py /usr/src/build.py
ADD site.mk /usr/src/site.mk
ADD site.conf /usr/src/site.conf
ADD domains /usr/src/domains
ADD i18n /usr/src/i18n

RUN adduser --system --home /usr/src/build build
USER build
WORKDIR /usr/src/build
RUN git config --global user.email "technik@freifunk-dortmund.de"
RUN git config --global user.name "FFDO Gluon Build Container"

CMD ["/usr/src/build.py"]