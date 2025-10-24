FROM php:8.2.11-apache

ARG DOWNLOAD_URL
ARG FOLDER


ENV DIR_OPENCART='/var/www/html/'
ENV DIR_STORAGE='/storage/'
ENV DIR_CACHE=${DIR_STORAGE}'cache/'
ENV DIR_DOWNLOAD=${DIR_STORAGE}'download/'
ENV DIR_LOGS=${DIR_STORAGE}'logs/'
ENV DIR_SESSION=${DIR_STORAGE}'session/'
ENV DIR_UPLOAD=${DIR_STORAGE}'upload/'
ENV DIR_IMAGE=${DIR_OPENCART}'image/'


RUN apt-get clean && apt-get update && apt-get install unzip

RUN apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libzip-dev \
  vim \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd zip mysqli


RUN apt-get install -y vim
RUN apt-get install -y jq
RUN mkdir /storage && mkdir /opencart

RUN if [ -z "$DOWNLOAD_URL" ]; then \
    curl -s https://api.github.com/repos/opencart/opencart/releases/latest \
    | jq -r '.assets[] | select(.name == "opencart-4.1.0.3.zip") | .browser_download_url' \
    | head -n 1 \
    | xargs -n 1 curl -Lo /tmp/opencart.zip; \
  else \
    curl -Lo /tmp/opencart.zip "$DOWNLOAD_URL"; \
  fi

RUN unzip /tmp/opencart.zip -d  /tmp/opencart;
RUN FOLDER_NAME=$(ls -d /tmp/opencart/*/ | grep -vE '(docs|licence)' | head -n 1 | xargs basename) && \
    mv /tmp/opencart/${FOLDER_NAME}/upload/* /var/www/html/ && \
    mv /tmp/opencart/${FOLDER_NAME}/storage /storage;


RUN rm -rf /tmp/opencart.zip && rm -rf /tmp/opencart && rm -rf ${DIR_OPENCART}install;

RUN mv /var/www/html/storage/* /storage



RUN a2enmod rewrite

RUN chown -R www-data:www-data ${DIR_STORAGE}
RUN chmod -R 555 ${DIR_OPENCART}
RUN chmod -R 666 ${DIR_STORAGE}
RUN chmod 555 ${DIR_STORAGE}
RUN chmod -R 555 ${DIR_STORAGE}vendor
RUN chmod 755 ${DIR_LOGS}
RUN chmod -R 644 ${DIR_LOGS}*

RUN chown -R www-data:www-data ${DIR_IMAGE}
RUN chmod -R 744 ${DIR_IMAGE}
RUN chmod -R 755 ${DIR_CACHE}

RUN chmod -R 666 ${DIR_DOWNLOAD}
RUN chmod -R 666 ${DIR_SESSION}
RUN chmod -R 666 ${DIR_UPLOAD}

CMD ["apache2-foreground"]
