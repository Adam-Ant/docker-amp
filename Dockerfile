FROM debian:jessie

MAINTAINER 'Adam Dodman <adam.dodman@gmx.com>'

ADD start.sh /

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends lib32gcc1 coreutils screen tmux socat unzip git wget \
 && useradd -mr AMP \
 && mkdir /ampdata \
 && chmod +x /start.sh \
 && chown AMP:AMP /start.sh \
 && chown AMP:AMP /ampdata \
 && ln -s /ampdata /home/AMP/.ampdata \
 && apt-get clean \
 && rm -rf /var/lib/apt /tmp/* /var/tmp/*

USER AMP

WORKDIR /home/AMP

RUN wget -q http://cubecoders.com/Downloads/ampinstmgr.zip \
 && unzip ampinstmgr.zip \
 && rm -rf  ampinstmgr.zip

VOLUME ["/ampdata"]

CMD ["/start.sh"]

EXPOSE 8080
