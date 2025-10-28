# Stage 1: Build assets
FROM node:18-alpine AS node_builder

WORKDIR /app

# Installation des outils de build
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Copier les fichiers de dépendances
COPY package.json package-lock.json* ./

# Installer les dépendances
RUN npm ci --legacy-peer-deps

# Copier les fichiers de configuration
COPY webpack.config.js ./
COPY babel.config.js* .babelrc* ./
COPY postcss.config.js* ./
COPY tsconfig.json* ./

# Copier les sources
COPY assets ./assets
COPY templates ./templates

# Variables d'environnement pour le build
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max_old_space_size=4096

# Build avec verbose pour voir les erreurs
RUN npm run build || (cat /root/.npm/_logs/* && exit 1)

# Stage 2: PHP Application
FROM php:8.2-fpm

# Installation des extensions PHP
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        zip \
        opcache \
        intl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copier les fichiers de dépendances PHP
COPY composer.json composer.lock symfony.lock* ./

# Installer les dépendances PHP
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-scripts \
    --no-interaction \
    --prefer-dist

# Copier le code source
COPY . .

# Copier les assets buildés
COPY --from=node_builder /app/public/build ./public/build

# Finaliser l'installation Composer
RUN composer dump-autoload --optimize --classmap-authoritative

# Créer les dossiers nécessaires avec les bonnes permissions
RUN mkdir -p var/cache var/log && \
    chown -R www-data:www-data var/

# Configuration PHP pour la production
COPY <<EOF /usr/local/etc/php/conf.d/production.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.interned_strings_buffer=16
realpath_cache_size=4096K
realpath_cache_ttl=600
EOF

EXPOSE 8000

# Utiliser un array pour CMD (recommandé)
CMD ["sh", "-c", "php bin/console cache:clear && php bin/console cache:warmup && php -S 0.0.0.0:8000 -t public"]