FROM adamant/busybox

MAINTAINER 'Adam Dodman <adam.dodman@gmx.com>'

ADD start.sh /

WORKDIR /tmp

RUN wget http://ftp.de.debian.org/debian/pool/main/t/tcp-wrappers/libwrap0_7.6.q-25_amd64.deb \ 
 && wget http://ftp.de.debian.org/debian/pool/main/s/socat/socat_1.7.2.4-2_amd64.deb \
 && wget http://ftp.de.debian.org/debian/pool/main/n/ncurses/libtinfo5_5.9+20140913-1+b1_amd64.deb \
 && 
 && useradd -mr AMP \
 && mkdir /ampdata \
 && chmod +x /start.sh \
 && chown AMP:AMP /start.sh \
 && chown AMP:AMP /ampdata \
 && ln -s /ampdata /home/AMP/.ampdata \
 && rm -rf /var/lib/apt /tmp/* /var/tmp/*

USER AMP

WORKDIR /home/AMP

RUN wget -q http://cubecoders.com/Downloads/ampinstmgr.zip \
 && unzip ampinstmgr.zip \
 && rm -rf  ampinstmgr.zip

VOLUME ["/ampdata"]

CMD ["/start.sh"]

EXPOSE 8080
