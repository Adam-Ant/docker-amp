FROM frebib/debian-builder as builder

ARG SOCAT_VER=1.7.3.2
ARG SCREEN_VER=v.4.5.1
ARG LIBEVENT_VER=2.1.8-stable
ARG TMUX_VER=2.4

ARG PREFIX=/usr

RUN apt-get update -qqy \
 && apt-get install -qqy dh-autoreconf libncurses5-dev libsqlite3-0 \
 && mkdir -p /output/bin /output/lib

RUN curl -fL http://www.dest-unreach.org/socat/download/socat-${SOCAT_VER}.tar.gz | tar xz \
 && cd socat-${SOCAT_VER} \
 && ./configure --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && mv ./socat /output/bin

RUN curl -fL http://git.savannah.gnu.org/cgit/screen.git/snapshot/screen-${SCREEN_VER}.tar.gz | tar xz \
 && cd screen-${SCREEN_VER}/src/ \
 && ./autogen.sh \
 && ./configure --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && mv ./screen /output/bin

RUN curl -fL https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VER}/libevent-${LIBEVENT_VER}.tar.gz | tar xz \
 && cd libevent-${LIBEVENT_VER} \
 && mkdir build/ \
 && ./configure --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && make DESTDIR="$(pwd)/build" install \
 && cp ./build/${PREFIX}/lib/*.so* /output/lib

RUN curl -fL https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz | tar xz \
 && cd tmux-${TMUX_VER}/ \
 && export LE_DIR="../libevent-${LIBEVENT_VER}/build/usr" \
 && ./configure CFLAGS="-I$LE_DIR/include" LDFLAGS="-L$LE_DIR/lib" --prefix=${PREFIX} \
 && make -j "$(nproc)" \
 && mv ./tmux /output/bin

# Yeah we should probably build these from source, but its part of the debian image.....
RUN cp /lib/$(gcc -print-multiarch)/libgcc_s.so.1 /output/lib \
 && cp /usr/lib/$(gcc -print-multiarch)/libsqlite3.so.0 /output/lib \
 && cp /usr/lib/$(gcc -print-multiarch)/libsqlite3.so.0.8.6 /output/lib


#================


FROM adamant/busybox:libressl

ADD start.sh /

COPY --from=builder /output/bin/* /usr/bin/
COPY --from=builder /output/lib/* /usr/lib/

RUN addgroup -S amp \
 && adduser -SDG amp amp \
 && chmod +x /start.sh \
 && mkdir -p /home/amp/.ampdata/instances /ampdata \
 && ln -s /ampdata /home/amp/.ampdata/instances/instance \
 && chown -R amp:amp /start.sh /ampdata /home/amp

USER amp

WORKDIR /home/amp

RUN wget -q https://cubecoders.com/Downloads/ampinstmgr.zip \
 && unzip ampinstmgr.zip \
 && rm -rf ampinstmgr.zip

VOLUME ["/ampdata"]

ENTRYPOINT ["/sbin/tini","--"]

CMD ["/start.sh"]

EXPOSE 8080
