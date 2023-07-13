# Stage 1: Installing dependencies for the application and RoadRunner to work

FROM ubuntu:20.04 AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php8.2 \
        php8.2-cli \
        php8.2-zip \
        php8.2-sockets \
        php8.2-intl \
        php8.2-pgsql \
        php8.2-mongodb \
        php8.2-pdo-pgsql \
        php8.2-xml \
        php8.2-curl \
    && wget https://github.com/roadrunner-server/roadrunner/releases/download/v2023.1.5/roadrunner-2023.1.5-linux-amd64.deb \
    && dpkg -i roadrunner-2023.1.5-linux-amd64.deb \
    && rm -rf roadrunner-2023.1.5-linux-amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mv /etc/php/8.2/cli/php.ini /etc/php/8.2/cli/php.ini-production

# Stage 2: Installing dev dependencies to build the application and an image for testing

FROM base AS dev
RUN apt-get update && apt-get install -y \
        curl \
        git \
        zip \
        unzip \
        openssl \
        php8.2-dev \
        build-essential \
        libzip-dev \
        libicu-dev \
        libpq-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
#WORKDIR /composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-scripts --ignore-platform-req=php

# Stage 3: Base image to run the application

FROM base AS app
WORKDIR /app
COPY --from=dev /app/vendor /app/vendor
COPY . .
ENTRYPOINT ["rr", "serve", "--config", "/app/.rr.yaml"]
