# Stage 1: Build assets
FROM node:18-alpine AS node_builder

WORKDIR /app

# Installation des outils de build
RUN apk add --no-cache python3 make g++ git

# Copier package.json
COPY package.json package-lock.json* ./

# Installer les dépendances
RUN npm ci --legacy-peer-deps

# Copier les fichiers de configuration Webpack
COPY webpack.config.js ./
COPY babel.config.js* .babelrc* ./
COPY postcss.config.js* ./
COPY tsconfig.json* ./

# Copier les sources
COPY assets ./assets
COPY templates ./templates
COPY public ./public

# Variables d'environnement
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max_old_space_size=4096

# Build avec vérification
RUN npm run build && \
    echo "=== Checking build output ===" && \
    ls -la public/build/ && \
    test -f public/build/entrypoints.json || (echo "ERROR: entrypoints.json not found!" && exit 1) && \
    echo "✓ Build successful!"

# Stage 2: PHP Application
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git unzip libpq-dev libzip-dev libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql zip opcache intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copier composer files
COPY composer.json composer.lock symfony.lock* ./

# Installer les dépendances PHP
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# Copier le code source
COPY . .

# Copier les assets buildés depuis le stage Node
COPY --from=node_builder /app/public/build ./public/build

# Vérifier que les assets sont bien copiés
RUN ls -la public/build/ && \
    test -f public/build/entrypoints.json || (echo "ERROR: entrypoints.json not copied!" && exit 1)

# Finaliser Composer
RUN composer dump-autoload --optimize --classmap-authoritative

# Permissions
RUN mkdir -p var/cache var/log && \
    chown -R www-data:www-data var/ public/

# Configuration PHP
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 8000

CMD ["sh", "-c", "php bin/console cache:clear && php bin/console cache:warmup && php -S 0.0.0.0:8000 -t public public/index.php"]