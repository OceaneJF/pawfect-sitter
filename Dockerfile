# syntax=docker/dockerfile:1.7

############################
# Base PHP (extensions)
############################
FROM php:8.3-fpm-alpine AS php-base

# Dépendances système utiles (intl, gd, zip, etc.)
RUN apk add --no-cache \
    bash git unzip icu-dev oniguruma-dev \
    libzip-dev libpng-dev libjpeg-turbo-dev libwebp-dev \
    shadow

# Extensions PHP courantes pour Symfony
RUN docker-php-ext-configure gd --with-jpeg --with-webp \
 && docker-php-ext-install -j$(nproc) \
    intl pdo_mysql opcache gd zip

# APCu pour le cache applicatif
RUN pecl install apcu \
 && docker-php-ext-enable apcu

# Réglages PHP raisonnables
RUN { \
      echo "memory_limit=128M"; \
      echo "opcache.enable=1"; \
      echo "opcache.preload_user=www-data"; \
      echo "opcache.validate_timestamps=0"; \
    } > /usr/local/etc/php/conf.d/symfony.ini

WORKDIR /var/www/html

############################
# Composer (vendors)
############################
FROM composer:2 AS vendor
WORKDIR /app
# Copie ciblée pour tirer parti du cache Docker
COPY composer.json composer.lock symfony.lock* ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction
# Pour le dev, on fera un install complet dans la cible dev si besoin

############################
# Build des assets (Vite ou Encore)
############################
FROM node:20-alpine AS assets-builder
WORKDIR /app
# Copie des manifests pour cache
COPY package.json* package-lock.json* yarn.lock* pnpm-lock.yaml* ./
# Installation dépendances front (on essaie npm puis yarn)
RUN --mount=type=cache,target=/root/.npm \
    (npm ci || (npm install -g corepack && corepack enable && yarn install --frozen-lockfile || pnpm install --frozen-lockfile))
# Copie du code nécessaire à la compilation
COPY assets ./assets
# Si vous utilisez AssetMapper + Vite/Encore, il faut les fichiers suivants:
COPY vite.config.* webpack.config.* postcss.config.* babel.config.* ./
# Build, on tolère npm/yarn/pnpm
RUN (npm run build || yarn build || pnpm build) || \
    (echo "Aucun script build trouvé. Ignorer si AssetMapper sans bundler.")

############################
# PROD runtime
############################
FROM php-base AS prod
ENV APP_ENV=prod
WORKDIR /var/www/html

# Copie du code applicatif
COPY . ./

# Vendors depuis l'étage Composer
COPY --from=vendor /app/vendor ./vendor

# Assets construits
# Vite/Encore: public/build ; AssetMapper: public/assets (adaptez si besoin)
COPY --from=assets-builder /app/public ./public

# Droits et warmup du cache
RUN chown -R www-data:www-data var public \
 && mkdir -p var/cache var/log \
 && php bin/console cache:clear --no-warmup --env=prod \
 && php bin/console cache:warmup --env=prod

USER www-data
EXPOSE 9000
CMD ["php-fpm"]

############################
# DEV runtime (hot reload possible)
############################
FROM php-base AS dev
ENV APP_ENV=dev
WORKDIR /var/www/html

# Outils dev: Node pour Vite/Encore, Symfony CLI pratique
RUN apk add --no-cache nodejs npm \
 && wget -qO - https://get.symfony.com/cli/installer | bash \
 && mv /root/.symfony*/bin/symfony /usr/local/bin/symfony

# Copie et install Composer (avec dev)
COPY composer.json composer.lock symfony.lock* ./
RUN --mount=type=cache,target=/tmp/composer \
    composer install --prefer-dist --no-progress --no-interaction

# Copie du reste du projet
COPY . ./

# Prépare les répertoires d’écriture
RUN chown -R www-data:www-data var public

USER www-data
EXPOSE 9000
# php-fpm pour servir via un reverse-proxy (nginx/caddy) côté compose
CMD ["php-fpm"]
