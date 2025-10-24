# --- 1) Vendors PHP ---
FROM composer:2 AS vendor
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress

COPY . .
RUN composer install --no-dev --no-interaction --prefer-dist --no-progress

# --- 2) Runtime Apache + PHP ---
FROM php:8.2-apache

# Extensions fréquemment utiles pour Symfony
RUN apt-get update && apt-get install -y --no-install-recommends \
      libicu-dev libzip-dev libpng-dev unzip git \
  && docker-php-ext-configure intl \
  && docker-php-ext-install -j"$(nproc)" intl pdo_mysql zip gd \
  && docker-php-ext-enable opcache \
  && a2enmod rewrite headers \
  && rm -rf /var/lib/apt/lists/*

# Servir /public
RUN sed -ri -e 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri -e 's/DocumentRoot .*/DocumentRoot \/var\/www\/html\/public/' /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Copie code + vendors
COPY --chown=www-data:www-data --from=vendor /app /var/www/html

# Permissions cache/logs
RUN mkdir -p var && chown -R www-data:www-data var

# (Option) warmup cache prod — à activer si pas de commande DB nécessaire ici
# ENV APP_ENV=prod
# RUN su -s /bin/sh -c "php bin/console cache:clear --env=prod && php bin/console cache:warmup --env=prod" www-data

EXPOSE 80
