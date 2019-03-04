FROM debian:stretch
MAINTAINER Cajus Kamer <Cajus.Kamer@arcor.de>

ENV GLUON_TAG_DOCKER_ENV v2018.2
ENV GLUON_RELEASE_DOCKER_ENV 2.2.2

ENV GLUON_TARGETS_DOCKER_ENV ar71xx-generic ar71xx-nand ar71xx-tiny ar71xx-mikrotik ipq40xx mpc85xx-generic ramips-mt7621 x86-generic x86-64 
# ENV DOMAINS_TO_BUILD_DOCKER_ENV Domäne-01 Domäne-02 Domäne-03 Domäne-04 Domäne-05 Domäne-06 Domäne-07 Domäne-08 Domäne-09 Domäne-09 Domäne-10 Domäne-11

ENV BUILD_GLUON_DIR_DOCKER_ENV /usr/src/build/gluon
ENV BUILD_SITE_DIR_DOCKER_ENV /usr/src/build/site
ENV BUILD_ALL_SITES_DIR_DOCKER_ENV /usr/src/sites
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
RUN apt-get -y install --no-install-recommends adduser bash ca-certificates curl python python3 python3-yaml python3-jinja2 wget file git subversion build-essential gawk unzip libncurses5-dev zlib1g-dev openssl libssl-dev bsdmainutils time && apt-get clean

ADD build_all_lede.sh /usr/src/build_all_lede.sh
RUN chmod 777 /usr/src/build_all_lede.sh
ADD ChatAuthTokens /usr/src/ChatAuthTokens
COPY ChatAuthTokens/* /usr/src/ChatAuthTokens/

RUN adduser --system --home /usr/src/build build
USER build
WORKDIR /usr/src/build
COPY generated/sites /usr/src/sites
RUN git config --global user.email "technik@freifunk-dortmund.de"
RUN git config --global user.name "FFDO Gluon Build Container"

CMD ["/bin/bash", "/usr/src/build_all_lede.sh", "-B", "--force-retries", "3"]
