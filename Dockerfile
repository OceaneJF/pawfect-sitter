# syntax=docker/dockerfile:1.7

##########################################
# PHP base avec extensions Symfony
##########################################
FROM php:8.3-fpm-alpine AS php-base

# Dépendances runtime
RUN apk add --no-cache \
    bash git unzip shadow \
    icu-dev oniguruma-dev libzip-dev \
    libpng-dev libjpeg-turbo-dev libwebp-dev

# Dépendances build pour phpize et extensions (seront supprimées ensuite)
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

# Extensions PHP nécessaires à Symfony
RUN docker-php-ext-configure gd --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" intl pdo_mysql opcache gd zip

# APCu via PECL
RUN pecl install apcu \
 && docker-php-ext-enable apcu

# Réglages PHP
RUN { \
      echo "memory_limit=512M"; \
      echo "opcache.enable=1"; \
      echo "opcache.preload_user=www-data"; \
      echo "opcache.validate_timestamps=0"; \
    } > /usr/local/etc/php/conf.d/symfony.ini

WORKDIR /var/www/html


##########################################
# Composer: installation vendor prod
##########################################
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock symfony.lock* ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction


##########################################
# Build des assets (Encore ou Vite)
##########################################
FROM node:20-alpine AS assets-builder
WORKDIR /app

COPY package.json* package-lock.json* yarn.lock* pnpm-lock.yaml* ./
RUN --mount=type=cache,target=/root/.npm \
    (npm ci || (npm install -g corepack && corepack enable && yarn install --frozen-lockfile || pnpm install --frozen-lockfile))

COPY assets ./assets
COPY vite.config.* webpack.config.* postcss.config.* babel.config.* ./
RUN (npm run build || yarn build || pnpm build) || \
    (echo "Aucun script build trouvé. Ignorer si AssetMapper pur.")


##########################################
# PROD
##########################################
FROM php-base AS prod
ENV APP_ENV=prod

WORKDIR /var/www/html

COPY . ./
COPY --from=vendor /app/vendor ./vendor
COPY --from=assets-builder /app/public ./public

# Droits et warmup
RUN chown -R www-data:www-data var public \
 && mkdir -p var/cache var/log \
 && php bin/console cache:clear --no-warmup --env=prod \
 && php bin/console cache:warmup --env=prod

EXPOSE 9000
USER www-data
CMD ["php-fpm"]


##########################################
# DEV
##########################################
FROM php-base AS dev
ENV APP_ENV=dev
WORKDIR /var/www/html

# Node.js + Symfony CLI pour dev local
RUN apk add --no-cache nodejs npm \

COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/tmp/composer \
    composer install --prefer-dist --no-progress --no-interaction

COPY . ./

RUN chown -R www-data:www-data var public

EXPOSE 9000
USER www-data
CMD ["php-fpm"]
