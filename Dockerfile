FROM php:8.2-apache

# Arguments
ARG DOWNLOAD_URL
ARG FOLDER

# Environment
ENV DIR_OPENCART="/var/www/html/"
ENV DIR_STORAGE="/storage/"
ENV DIR_IMAGE="${DIR_OPENCART}image/"

# Install required packages
RUN apt-get update && apt-get install -y \
    unzip curl libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli zip \
    && a2enmod rewrite \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /storage /opencart ${DIR_OPENCART}

# Download OpenCart
RUN if [ -z "$DOWNLOAD_URL" ]; then \
      DOWNLOAD_URL=$(curl -s https://api.github.com/repos/opencart/opencart/releases/latest \
        | grep -o 'https.*opencart.*\.zip' | head -n 1); \
      echo "Downloading OpenCart from: $DOWNLOAD_URL"; \
      curl -L -o /tmp/opencart.zip "$DOWNLOAD_URL"; \
    else \
      echo "Using custom URL: ${DOWNLOAD_URL}"; \
      curl -L -o /tmp/opencart.zip "${DOWNLOAD_URL}"; \
    fi


# Unzip and move files
RUN unzip /tmp/opencart.zip -d /tmp/opencart && \
    cp -r /tmp/opencart/*/upload/* ${DIR_OPENCART} && \
    rm -rf /tmp/opencart.zip /tmp/opencart && \
    mv ${DIR_OPENCART}system/storage/* ${DIR_STORAGE} && \
    rm -rf ${DIR_OPENCART}install

# Permissions
RUN chown -R www-data:www-data ${DIR_OPENCART} ${DIR_STORAGE} && \
    chmod -R 755 ${DIR_OPENCART} ${DIR_STORAGE}

# Apache config for Render (port 8080)
RUN sed -i 's|Listen 80|Listen 8080|g' /etc/apache2/ports.conf \
    && sed -i 's|<VirtualHost \*:80>|<VirtualHost *:8080>|g' /etc/apache2/sites-available/000-default.conf \
    && echo '<Directory /var/www/html/>\nAllowOverride All\n</Directory>' >> /etc/apache2/apache2.conf

EXPOSE 8080

CMD ["apache2-foreground"]
