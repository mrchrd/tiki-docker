FROM docker.io/php:8.2.22-fpm AS build

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      libavif-dev \
      libbz2-dev \
      libffi-dev \
      libfreetype-dev \
      libgd-dev \
      libicu-dev \
      libjpeg-dev \
      libldap-dev \
      liblz4-dev \
      libmagickwand-dev \
      libmemcached-dev \
      libonig-dev \
      libpng-dev \
      libsasl2-dev \
      libssl-dev \
      libtidy-dev \
      libwebp-dev \
      libxml2-dev \
      libxpm-dev \
      libxslt1-dev \
      libzip-dev \
      zlib1g-dev \
      ; \
    apt-get install -y --no-install-recommends \
      7zip \
      git \
      npm \
      sudo \
      unzip \
      wget \
      ; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    docker-php-ext-configure gd \
      --with-avif \
      --with-external-gd \
      --with-freetype \
      --with-jpeg \
      --with-webp \
      --with-xpm \
      ; \
    docker-php-ext-configure ldap \
      --with-ldap-sasl \
      ; \
    docker-php-ext-install -j "$(nproc)" \
      bcmath \
      bz2 \
      calendar \
      exif \
      ffi \
      ftp \
      gd \
      gettext \
      intl \
      ldap \
      mbstring \
      mysqli \
      opcache \
      pdo_mysql \
      shmop \
      soap \
      sockets \
      sysvmsg \
      sysvsem \
      sysvshm \
      tidy \
      xsl \
      zip \
      ;

RUN set -eux; \
    pecl install --force \
      igbinary \
      msgpack \
      ; \
    pecl install --force \
      --configureoptions=' \
        enable-apcu-debug="no" \
        enable-memcached-igbinary="yes" \
        enable-memcached-json="yes" \
        enable-memcached-msgpack="yes" \
        enable-memcached-protocol="no" \
        enable-memcached-sasl="yes" \
        enable-memcached-session="yes" \
        enable-redis-igbinary="yes" \
        enable-redis-lz4="yes" \
        enable-redis-lzf="yes" \
        enable-redis-msgpack="yes" \
        enable-redis-zstd="yes" \
        with-imagick="yes" \
        with-liblz4="yes" \
        with-libmemcached-dir="no" \
        with-system-fastlz="no" \
        with-zlib-dir="no"' \
      apcu \
      imagick \
      memcached \
      redis \
      xdebug \
      ; \
    rm -rf /tmp/pear

RUN set -eux; \
    docker-php-ext-enable \
      igbinary \
      msgpack \
      ; \
    docker-php-ext-enable \
      apcu \
      imagick \
      memcached \
      redis \
#      xdebug \
      ;

RUN set -eux; \
    git clone \
      --depth 1 \
      --single-branch \
      --branch=tags/27.0 \
      https://gitlab.com/tikiwiki/tiki.git \
      /var/www/html; \
    chown -R www-data:www-data /var/www/html; \
    sudo -E -u www-data -g www-data ln -s _htaccess /var/www/html/.htaccess; \
    install -o www-data -g www-data -m 0755 -d \
      /var/www/sessions \
      /var/www/tikiconfig \
      /var/www/tikifiles \
      /var/www/tikifiles/fgal_batch_dir \
      /var/www/tikifiles/fgal_use_dir \
      /var/www/tikifiles/gal_use_dir \
      /var/www/tikifiles/t_use_dir \
      /var/www/tikifiles/uf_use_dir \
      /var/www/tikifiles/w_use_dir \
      ; \
true
#    find /var/www/html/lang/ -name language.php -exec php doc/devtools/stripcomments.php {} \; ; \
#    find /var/www/html -name .git -type d -exec rm -rf {} +; \
#    find /var/www/html -name .gitignore -type f -exec rm -f {} +; \
#    rm -rf /var/www/html/doc/devtools

COPY php.ini /usr/local/etc/php/conf.d/tiki.ini
COPY --chown=www-data:www-data prefs.ini.php /var/www/tikiconfig/prefs.ini.php
COPY --chown=www-data:www-data local.php /var/www/html/db/local.php

COPY --from=docker.io/composer:2.7.7 /usr/bin/composer /usr/local/bin/composer
ENV COMPOSER_HOME=/tmp/composer
ENV npm_config_cache=/tmp/npm
RUN set -eux; \
    bash /var/www/html/setup.sh -n build; \
    bash /var/www/html/setup.sh -n fix; \
    chown -R www-data:www-data /var/www/html; \
true
#    find /var/www/html -name .gitignore -type f -exec rm -f {} +; \
#    rm -rf /var/www/html/bin; \
#    rm -rf /var/www/html/node_modules

FROM docker.io/php:8.2.22-fpm

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      libavif15 \
      libbz2-1.0 \
      libffi8 \
      libfreetype6 \
      libgd3 \
      libicu72 \
      libjpeg62-turbo \
      libldap-2.5-0 \
      liblz4-1 \
      libmagickwand-6.q16-6 \
      libmemcached11 \
      libmemcachedutil2 \
      libonig5 \
      libpng16-16 \
      libsasl2-2 \
      libssl3 \
      libtidy5deb1 \
      libwebp7 \
      libxml2 \
      libxpm4 \
      libxslt1.1 \
      libzip4 \
      zlib1g \
      ; \
    apt-get install -y --no-install-recommends \
      7zip \
      cron \
      git \
      mariadb-client \
      npm \
      nullmailer \
      poppler-utils \
      rsync \
      sqlite3 \
      ssh \
      sudo \
      syncthing \
      tesseract-ocr-all \
      unzip \
      ; \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/etc/php /usr/local/etc/php
COPY --from=build /usr/local/lib/php /usr/local/lib/php
COPY --from=docker.io/composer:2.7.8 /usr/bin/composer /usr/local/bin/composer

RUN crontab -u root - <<-EOF
*/5 * * * * sudo -Eu www-data php /var/www/html/console.php scheduler:run >/proc/1/fd/1 2>/proc/1/fd/2
EOF

COPY --from=build /var/www /var/www
VOLUME /var/www
WORKDIR /var/www/html

COPY entrypoint.sh /usr/local/bin/docker-tiki-entrypoint

ENTRYPOINT ["docker-tiki-entrypoint"]
CMD ["php-fpm"]
