FROM alpine:3.16 as base

RUN apk add --no-cache glib libmad libvorbis nginx gnu-libiconv inotify-tools

FROM base as build

RUN apk add --no-cache glib-dev libc-dev libmad-dev libvorbis-dev gcc libtool automake autoconf patch m4 make gnu-libiconv-dev

COPY ./streamripper.tar.gz /root/

RUN mkdir /root/build \
    && tar xpf /root/streamripper.tar.gz -C /root/build --strip-components 1 \
    && rm /root/streamripper.tar.gz

WORKDIR /root/build

# https://sourceforge.net/p/streamripper/bugs/193/
COPY ./streamripper-http-1.0.patch streamripper-http-1.0.patch
RUN cat streamripper-http-1.0.patch | patch -p1 \
    && sed -i lib/ripstream.c -e 's/__uint32_t/uint32_t/g'

RUN libtoolize --install --copy --force --automake \
    && aclocal -I m4 \
    && autoconf --force \
    && autoheader \
    && automake --add-missing --copy --foreign --force-missing

RUN ./configure --prefix=/usr/local --disable-dependency-tracking --disable-silent-rules --without-included-libmad --without-included-argv --with-ogg \
    && make DESTDIR=/root/image install

FROM base

COPY --from=build /root/image/usr/local/ /usr/local/

COPY ./nginx.conf /etc/nginx/nginx.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stdout /var/log/nginx/error.log \
    && chmod a+rwX /etc/nginx/http.d/default.conf /var/lib/nginx /var/lib/nginx/tmp /var/run

ENV USER_AGENT="RadioWalker" \
    STREAM_URL="" \
    REQUIRED_COLLECTED_MB="" \
    DATA_DIR="/data"

COPY ./entrypoint.sh /usr/local/bin/entrypoint
STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/local/bin/entrypoint"]
