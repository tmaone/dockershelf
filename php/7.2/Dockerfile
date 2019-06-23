FROM dockershelf/debian:sid
MAINTAINER Luis Alejandro Martínez Faneyth <luis@luisalejandro.org>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="php7.2" \
      org.label-schema.description="A PHP 7.2 image based on Debian sid." \
      org.label-schema.url="https://github.com/LuisAlejandro/dockershelf" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url="https://github.com/LuisAlejandro/dockershelf" \
      org.label-schema.vendor="Luis Alejandro Martínez Faneyth" \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0.0-rc.1"

ENV PHP_VER_NUM="7.2" PHP_DEBIAN_SUITE="sid"

COPY build-image.sh library.sh /usr/share/dockershelf/php/
RUN bash /usr/share/dockershelf/php/build-image.sh

CMD ["php"]