# Usar Debian Bookworm (estable, soporta PHP 8.3 y recibe parches de seguridad activos)
FROM php:8.3-apache-bookworm

# Actualizar, instalar dependencias y limpiar caché en una sola capa para reducir la superficie de ataque
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libpng-dev \
    zlib1g-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libxpm-dev \
    libfreetype6-dev \
    # A partir de PHP 7.4 y en 8.x no es necesario especificar la ruta de los binarios para GD
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    # -j$(nproc) usa múltiples núcleos para compilar más rápido
    && docker-php-ext-install -j$(nproc) gd pdo_mysql exif \
    # Limpiar el gestor de paquetes para reducir peso y vulnerabilidades residuales
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Usar configuración de producción (oculta errores de código al usuario final)
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Hardening de PHP: Ocultar la cabecera "X-Powered-By: PHP"
RUN echo "expose_php = Off" > "$PHP_INI_DIR/conf.d/security-php.ini"

# Hardening de Apache: Ocultar versión del servidor y sistema operativo
RUN echo "ServerTokens Prod\nServerSignature Off" > /etc/apache2/conf-available/security-apache.conf \
    && a2enconf security-apache

# Habilitar el módulo rewrite de Apache
RUN a2enmod rewrite

# Asegurar que los archivos web pertenezcan al usuario sin privilegios de Apache
RUN chown -R www-data:www-data /var/www/html