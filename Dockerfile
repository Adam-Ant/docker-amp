ARG SOCAT_VER=1.7.3.2
ARG LIBEVENT_VER=2.1.8-stable
ARG TMUX_VER=2.7

ARG PREFIX=/usr
ARG OUTDIR=/output

FROM spritsail/debian-builder as builder

ARG SOCAT_VER
ARG LIBEVENT_VER
ARG TMUX_VER

ARG PREFIX
ARG OUTDIR

RUN apt-get update \
 && apt-get install -qqy dh-autoreconf libncurses5-dev libsqlite3-0 libgcc1 \
 && mkdir -p ${OUTDIR}${PREFIX}/{bin,lib}

RUN curl -fL http://www.dest-unreach.org/socat/download/socat-${SOCAT_VER}.tar.gz | tar xz \
 && cd socat-${SOCAT_VER} \
 && ./configure --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && mv ./socat ${OUTDIR}${PREFIX}/bin

RUN curl -fL https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VER}/libevent-${LIBEVENT_VER}.tar.gz | tar xz \
 && cd libevent-${LIBEVENT_VER} \
 && mkdir build/ \
 && ./configure --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && make DESTDIR="$(pwd)/build" install \
 && cp -d ./build/${PREFIX}/lib/*.so* ${OUTDIR}${PREFIX}/lib

RUN curl -fL https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz | tar xz \
 && cd tmux-${TMUX_VER}/ \
 && export LE_DIR="../libevent-${LIBEVENT_VER}/build/usr" \
 && ./configure CFLAGS="-I$LE_DIR/include" LDFLAGS="-L$LE_DIR/lib" --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && mv ./tmux ${OUTDIR}${PREFIX}/bin

# Yeah we should probably build this from source, but that requires building all of gcc
RUN cp -d /lib/$(gcc -print-multiarch)/libgcc_s.so.1 ${OUTDIR}${PREFIX}/lib \
 && cp -d /usr/lib/$(gcc -print-multiarch)/libsqlite3.so.0 ${OUTDIR}${PREFIX}/lib \
 && cp -d /usr/lib/$(gcc -print-multiarch)/libsqlite3.so.0.8.6 ${OUTDIR}${PREFIX}/lib

# ~~~~~~~~~~~~~~~~~~~~~~~

FROM spritsail/libressl

ARG SOCAT_VER
ARG LIBEVENT_VER
ARG TMUX_VER
ARG OUTDIR

LABEL maintainer="Spritsail <amp@spritsail.io>" \
      org.label-schema.name="AMP" \
      org.label-schema.url="https://cubecoders.com/AMP" \
      org.label-schema.description="A game server web management tool" \
      org.label-schema.version="latest" \
      io.spritsail.version.socat=${SOCAT_VER} \
      io.spritsail.version.libevent=${LIBEVENT_VER} \
      io.spritsail.version.tmux=${TMUX_VER}

COPY --from=builder ${OUTDIR}/ /

RUN addgroup -S amp \
 && adduser -SDG amp amp \
 && mkdir -p /home/amp/.ampdata/instances /ampdata \
 && ln -s /ampdata /home/amp/.ampdata/instances/instance \
 && chown -R amp:amp /ampdata /home/amp \
 && (echo '#!/bin/sh'; echo 'exec /bin/sh "$@"') > /usr/bin/bash \
 && chmod +x /usr/bin/bash \
 && ldconfig && ldconfig -p

WORKDIR /opt/amp

RUN wget -q https://cubecoders.com/Downloads/ampinstmgr.zip \
 && unzip ampinstmgr.zip \
 && rm -rf ampinstmgr.zip

ADD start.sh /start.sh
RUN chmod +x /start.sh

USER amp

VOLUME  /ampdata
WORKDIR /ampdata

ENTRYPOINT ["/sbin/tini","--"]
CMD ["/start.sh"]

EXPOSE 8080
