# Stage 1: Build assets
FROM node:18-alpine AS node_builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY webpack.config.js ./
COPY assets ./assets
RUN npm run build

# Stage 2: PHP Application
FROM php:8.2-fpm

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip opcache \
    && apt-get clean

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copier les fichiers PHP
COPY composer.json composer.lock symfony.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

COPY . .

# Copier les assets buildés depuis le stage Node
COPY --from=node_builder /app/public/build ./public/build

# Générer les assets manifest
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# Permissions
RUN chown -R www-data:www-data /app/var

# Configuration PHP optimisée
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 8000

CMD php bin/console cache:warmup && \
    php -S 0.0.0.0:8000 -t public