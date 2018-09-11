ARG SOCAT_VER=1.7.3.2
ARG LIBEVENT_VER=2.1.8-stable
ARG NCURSES_VER=6.1
ARG TMUX_VER=2.7
ARG AMP_VER=1.6.10.2

ARG PREFIX=/usr
ARG OUTDIR=/output
ARG AMPDIR=/opt/amp

FROM spritsail/debian-builder as builder

ARG SOCAT_VER
ARG LIBEVENT_VER
ARG NCURSES_VER
ARG TMUX_VER
ARG AMP_VER

ARG PREFIX
ARG OUTDIR
ARG AMPDIR

RUN apt-get update \
 && apt-get install -qqy dh-autoreconf libsqlite3-0 libgcc1 locales \
 && mkdir -p ${OUTDIR}{${PREFIX}/{bin,lib,share},${AMPDIR}}

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
 && cp -d build${PREFIX}/lib/*.so* ${OUTDIR}${PREFIX}/lib

RUN curl -fL https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VER}.tar.gz | tar xz \
 && cd ncurses-${NCURSES_VER} \
 && ./configure \
        --prefix=${PREFIX} \
        --disable-dependency-tracking \
        --enable-widec \
        --with-shared \
        --without-normal \
        --without-debug \
        --without-ada \
        --without-manpages \
 && make -j "$(nproc)" \
 && make DESTDIR="$(pwd)/build" install \
 && mkdir -p ${OUTDIR}${PREFIX}/share/terminfo/x \
 && cp -d build${PREFIX}/lib/libncursesw.so* ${OUTDIR}${PREFIX}/lib \
 && cp -d build${PREFIX}/share/terminfo/x/xterm ${OUTDIR}${PREFIX}/share/terminfo/x

RUN curl -fL https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz | tar xz \
 && cd tmux-${TMUX_VER}/ \
 && LE_DIR="../libevent-${LIBEVENT_VER}/build${PREFIX}" \
 && NCUR_DIR="../ncurses-${NCURSES_VER}/build${PREFIX}" \
 && ./configure \
        # Override libevent and libncurses directories
        LIBEVENT_LIBS="-L${LE_DIR}/lib -levent" \
        LIBEVENT_CFLAGS="-I${LE_DIR}/include" \
        LIBNCURSES_LIBS="-L${NCUR_DIR}/lib -lncursesw" \
        LIBNCURSES_CFLAGS="-I${NCUR_DIR}/include" \
        --prefix=${PREFIX} \
        --disable-dependency-tracking \
 && make -j "$(nproc)" \
 && mv ./tmux ${OUTDIR}${PREFIX}/bin

# Yeah we should probably build these from source, but its part of the debian image.....
RUN cp -d /lib/$(gcc -print-multiarch)/libgcc_s.so.1 ${OUTDIR}${PREFIX}/lib \
 && cp -d /usr/lib/$(gcc -print-multiarch)/libsqlite3.so.0 ${OUTDIR}${PREFIX}/lib \
 && cp -d /usr/lib/$(gcc -print-multiarch)/libsqlite3.so.0.8.6 ${OUTDIR}${PREFIX}/lib \
    # Generate a default UTF-8 locale
    # Source: https://github.com/jaymoulin/docker-plex/blob/65713c772d792fcbb9c486122183c1e0f66da077/Dockerfile.amd#L22-L23
 && mkdir -p ${OUTDIR}/usr/lib/locale \
 && localedef --force --prefix=${OUTDIR} --inputfile POSIX --charmap UTF-8 C.UTF-8 || true

ADD start.sh ${OUTDIR}/start.sh

WORKDIR /tmp/amp
RUN curl -fsS https://repo.cubecoders.com/ampinstmgr-${AMP_VER}.$(uname -m).deb \
        | dpkg-deb -x - . \
    # Temp fix for btls linking paths
 && mv opt/cubecoders/amp/btls.so ${OUTDIR}${PREFIX}/lib \
 && mv opt/cubecoders/amp/* ${OUTDIR}${AMPDIR} \
    # Temp fix until nightly is stable
 && touch ${OUTDIR}${PREFIX}/bin/screen \
 && chmod +x ${OUTDIR}/start.sh \
 && find ${OUTDIR} -exec sh -c 'file "{}" | grep -q ELF && strip --strip-all "{}"' \;

# ~~~~~~~~~~~~~~~~~~~~~~~

FROM spritsail/libressl

ARG SOCAT_VER
ARG LIBEVENT_VER
ARG NCURSES_VER
ARG TMUX_VER
ARG AMP_VER
ARG OUTDIR
ARG AMPDIR

LABEL maintainer="Spritsail <amp@spritsail.io>" \
      org.label-schema.name="AMP" \
      org.label-schema.url="https://cubecoders.com/AMP" \
      org.label-schema.description="A game server web management tool" \
      org.label-schema.version=${AMP_VER} \
      io.spritsail.version.socat=${SOCAT_VER} \
      io.spritsail.version.libevent=${LIBEVENT_VER} \
      io.spritsail.version.ncurses=${NCURSES_VER} \
      io.spritsail.version.tmux=${TMUX_VER}

COPY --from=builder ${OUTDIR}/ /

RUN addgroup -g 500 -S amp \
 && adduser -u 500 -s /bin/sh -SDG amp amp \
 && mkdir -p /home/amp/.ampdata/instances /ampdata \
 && ln -s /ampdata /home/amp/.ampdata/instances/instance \
 && chown -R amp:amp /ampdata /home/amp \
 && (echo '#!/bin/sh'; echo 'exec /bin/sh "$@"') > /usr/bin/bash \
 && chmod +x /usr/bin/bash \
 && ldconfig

# Defaults for tmux/ncurses
ENV TERM=xterm \
    LANG=C.UTF-8 \
    PATH=${PATH}:${AMPDIR} \
    MONO_TLS_PROVIDER=btls \
    \
    HOST=0.0.0.0 \
    PORT=8080 \
    USERNAME=admin \
    PASSWORD=changeme

USER    amp
VOLUME  /ampdata
WORKDIR ${AMPDIR}

ENTRYPOINT ["/sbin/tini","--"]
CMD ["/start.sh"]

EXPOSE 8080
