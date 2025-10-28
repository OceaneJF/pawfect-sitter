# Stage 1: Build assets
FROM node:18-alpine AS node_builder

WORKDIR /app

RUN apk add --no-cache python3 make g++ git

# Copier package.json
COPY package.json package-lock.json* ./

# Installer les dépendances + forcer l'installation de @symfony/ux-vue
RUN npm install

# Copier les fichiers de configuration
COPY webpack.config.js ./
COPY postcss.config.js ./

# Copier les sources
COPY assets ./assets
COPY templates ./templates
COPY public ./public

ENV NODE_ENV=production
ENV NODE_OPTIONS=--max_old_space_size=4096

# Build
RUN npm run build && \
    echo "=== Checking build output ===" && \
    ls -la /app/public/build || echo "Build directory not found!"

# Stage 2: PHP Application
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git unzip libpq-dev libzip-dev libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip opcache intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock symfony.lock* ./
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

COPY . .
COPY --from=node_builder /app/public/build ./public/build

RUN composer dump-autoload --optimize --classmap-authoritative && \
    mkdir -p var/cache var/log && \
    chown -R www-data:www-data var/ public/

RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 8000

CMD ["sh", "-c", "php bin/console cache:clear && php bin/console cache:warmup && php -S 0.0.0.0:8000 -t public public/index.php"]