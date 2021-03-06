# Alpine Image for Nginx and PHP

# NGINX x ALPINE.
FROM nginx:1.19.3-alpine

# MAINTAINER OF THE PACKAGE.
LABEL maintainer="Neo Ighodaro <neo@creativitykills.co>"

# INSTALL SOME SYSTEM PACKAGES.
RUN apk --update --no-cache add ca-certificates \
    bash \
    supervisor

# trust this project public key to trust the packages.
ADD https://packages.whatwedo.ch/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# CONFIGURE ALPINE REPOSITORIES AND PHP BUILD DIR.
ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=3.12
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories && \
    echo "https://packages.whatwedo.ch/php-alpine/v3.12/php-7.4" >> /etc/apk/repositories

# INSTALL PHP AND SOME EXTENSIONS. SEE: https://github.com/codecasts/php-alpine
RUN apk add --no-cache --update tzdata php-fpm \
    php7 \
    php7-bcmath \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-ftp \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-mysqli \
    php7-mysqlnd \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-pear \
    php7-phar \
    php7-posix \
    php7-redis \
    php7-session \
    php7-sockets \
    php7-sqlite3 \
    php7-xml \
    php7-xmlreader \
    php7-zip \
    php7-zlib \
    curl \
    wget \
    libjpeg \
    libpng  \
    freetype \
    libxml2 \
    libxslt \
    libmcrypt  \
    libmemcached \
    gettext \
    libzip && \
    ln -s /usr/bin/php7 /usr/bin/php

# SETS TIME
RUN cp /usr/share/zoneinfo/Africa/Lagos /etc/localtime \
&& echo "Africa/Lagos" >  /etc/timezone \
&& date

# CONFIGURE WEB SERVER.
RUN mkdir -p /var/www && \
    mkdir -p /run/php && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /etc/nginx/sites-enabled && \
    mkdir -p /etc/nginx/sites-available && \
    rm /etc/nginx/nginx.conf && \
    rm /etc/php7/php-fpm.d/www.conf && \
    rm /etc/php7/php-fpm.conf

# INSTALL COMPOSER.
ARG COMPOSER_HASH=756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '${COMPOSER_HASH}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

# ADD START SCRIPT, SUPERVISOR CONFIG, NGINX CONFIG AND RUN SCRIPTS.
ADD start.sh /start.sh
RUN mkdir -p /var/config
COPY config/supervisor/sredis.conf /var/config/redis.conf
COPY config/supervisor/srabbitmq.conf /var/config/rabbitmq.conf
COPY config/supervisor/spos.conf /var/config/pos.conf
COPY config/supervisor/sbiller.conf /var/config/biller.conf
COPY config/supervisor/swallets.conf /var/config/wallet.conf
RUN ls -la /var/config
ADD config/nginx/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx/site.conf /etc/nginx/sites-available/default.conf
COPY config/php/php.ini /etc/php7/conf.d/custom.ini
ADD config/php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
ADD config/php-fpm/php-fpm.conf /etc/php7/php-fpm.conf
RUN chmod 755 /start.sh

# EXPOSE PORTS!
ARG NGINX_HTTP_PORT=80
ARG NGINX_HTTPS_PORT=443
EXPOSE ${NGINX_HTTPS_PORT} ${NGINX_HTTP_PORT}

# SET THE WORK DIRECTORY.
WORKDIR /var/www
COPY apm-agent-php_1.2_all.apk .
RUN apk add --allow-untrusted apm-agent-php_1.2_all.apk

# KICKSTART!
CMD ["/start.sh"]
