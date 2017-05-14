FROM debian:jessie-slim as builder

WORKDIR /tmp

RUN apt update -qqy && apt install -qqy build-essential curl dh-autoreconf libncurses5-dev \
 && mkdir --p /output/bin /output/lib

ARG CFLAGS="-Os -pipe -fstack-protector-strong"
ARG LDFLAGS="-Wl,-O1,--sort-common -Wl,-s"
ARG PREFIX=/tmp

RUN curl -L http://www.dest-unreach.org/socat/download/socat-1.7.3.2.tar.gz | tar xz \
 && cd socat-1.7.3.2 \
 && /tmp/socat-1.7.3.2/configure && make -C /tmp/socat-1.7.3.2 \
 && mv /tmp/socat-1.7.3.2/socat /output/bin \
 && cd /tmp


RUN curl -L http://git.savannah.gnu.org/cgit/screen.git/snapshot/screen-v.4.5.1.tar.gz | tar xz \
 && cd /tmp/screen-v.4.5.1/src/ && ./autogen.sh && /tmp/screen-v.4.5.1/src/configure \
 && make -C /tmp/screen-v.4.5.1/src \
 && mv /tmp/screen-v.4.5.1/src/screen /output/bin \
 && cd /tmp

RUN curl -L https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz | tar xz \
 && cd libevent-2.1.8-stable && ./configure && make && make install \
 && rm -r /usr/local/lib/*.*a /usr/local/lib/pkgconfig && cp /usr/local/lib/* /output/lib \
 && cd /tmp \
 && curl -L https://github.com/tmux/tmux/releases/download/2.4/tmux-2.4.tar.gz | tar xz \
 && cd /tmp/tmux-2.4/ && ./configure && make && ls -lah /tmp/tmux-2.4 \
 && mv /tmp/tmux-2.4/tmux /output/bin

# Yeah we should probably build this from source, but its part of the base debian image.....
RUN cp /lib/x86_64-linux-gnu/libgcc_s.so.1 /output/lib


#================


FROM adamant/busybox

ADD start.sh /

WORKDIR /tmp

COPY --from=builder /output/bin/* /usr/bin/
COPY --from=builder /output/lib/* /usr/lib/


RUN adduser -SD AMP \
 && addgroup AMP \
 && mkdir /ampdata \
 && chmod +x /start.sh \
 && chown AMP:AMP /start.sh \
 && chown AMP:AMP /ampdata \
 && ln -s /ampdata /home/AMP/.ampdata/ \

USER AMP

WORKDIR /home/AMP

RUN wget -q http://cubecoders.com/Downloads/ampinstmgr.zip \
 && unzip ampinstmgr.zip \
 && rm -rf  ampinstmgr.zip

VOLUME ["/ampdata"]

CMD ["/start.sh"]

EXPOSE 8080
