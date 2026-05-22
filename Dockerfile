FROM php:8.3.7-fpm-alpine

RUN apk add --no-cache linux-headers
RUN apk --no-cache upgrade && \
    apk --no-cache add bash git sudo openssh libxml2-dev oniguruma-dev autoconf gcc g++ make npm freetype-dev libjpeg-turbo-dev libpng-dev libzip-dev ssmtp openssl-dev icu-dev

# Configuración e instalación de extensiones nativas (Sin Swoole ni PECL)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure intl && \
    docker-php-ext-install mbstring xml pcntl gd zip sockets pdo pdo_mysql bcmath soap intl mysqli

# Herramientas de Composer y RoadRunner (Ya viene precompilado, no consume RAM)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --from=spiralscout/roadrunner:2.4.2 /usr/bin/rr /usr/bin/rr

WORKDIR /app
COPY . .

# Instalación de dependencias del proyecto
RUN composer install
RUN composer require laravel/octane spiral/roadrunner
COPY .env.example .env
RUN mkdir -p /app/storage/logs

# Configuración y arranque con RoadRunner
RUN php artisan octane:install --server="roadrunner"

EXPOSE 8000
CMD ["php", "artisan", "octane:start", "--server=roadrunner", "--host=0.0.0.0", "--port=8000"]
