# Si vous n'avez pas de Dockerfile, créez-en un :
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app

RUN composer install --no-dev --optimize-autoloader

RUN php bin/console cache:clear --env=prod
RUN php bin/console assets:install --env=prod

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]