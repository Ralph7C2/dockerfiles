FROM php:7.2-fpm

RUN apt-get update -y \
    && apt-get install -y nginx nano

# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"


#####
# SYSTEM REQUIREMENT
#####
ENV BUILD_DEPS \
        zlib1g-dev \
        git \
        libgmp-dev \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        build-essential \
        chrpath \
        libssl-dev \
        libxft-dev \
        libfreetype6 \
        libfontconfig1 \
        libfontconfig1-dev

RUN apt-get update \
    && apt-get install -y --no-install-recommends $BUILD_DEPS \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mbstring pdo pdo_mysql zip gd gmp opcache

ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64
# Install PHANTOMJS
RUN curl -o ${PHANTOMJS}.tar.bz2 -SL https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOMJS}.tar.bz2 \
    && tar xvjf ${PHANTOMJS}.tar.bz2 \
    && rm ${PHANTOMJS}.tar.bz2 \
    && mv ${PHANTOMJS} /usr/local/share \
    && ln -sf /usr/local/share/${PHANTOMJS}/bin/phantomjs /usr/local/bin \
    && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

#####
# DOWNLOAD AND INSTALL INVOICE NINJA
#####

######
# DEFAULT ENV
######
ENV LOG errorlog
ENV SELF_UPDATER_SOURCE ''
ENV PHANTOMJS_BIN_PATH /usr/local/bin/phantomjs

RUN mkdir -p /spool/logs
WORKDIR /var/www/app

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./entrypoint.sh /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["sh", "/entrypoint.sh"]
