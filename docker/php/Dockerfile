FROM wordpress:php8.3-apache

COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions xdebug

# Run Apache as the host user so bind-mounted files stay writable on both sides.
ARG UID=1000
ARG GID=1000
RUN groupmod -o -g "${GID}" www-data && usermod -o -u "${UID}" -g "${GID}" www-data

COPY php.ini /usr/local/etc/php/conf.d/zz-dev.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug.ini
