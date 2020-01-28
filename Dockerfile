FROM alpine:3.9
MAINTAINER YesInteractive- http://yes-interactive.com

# Install modules and updates
RUN apk update \
    && apk --no-cache add \
        openssl=="1.1.1d-r2" \
        apache2=="2.4.41-r0" \
        apache2-ssl \
        apache2-http2 \
        git \
	unzip \
    # Install PHP from community
    && apk --no-cache --repository http://dl-4.alpinelinux.org/alpine/v3.9/community/ add \
        php7=="7.2.27-r0" \
        php7-apache2 \
        php7-bcmath \
        php7-bz2 \
        php7-calendar \
        php7-common \
        php7-ctype \
        php7-curl \
        php7-dev \
        php7-dom \
        php7-json \
        php7-mbstring \
        php7-mcrypt \
        php7-memcached \
        php7-mysqlnd \
        php7-opcache \
        php7-openssl \
        php7-pdo \
        php7-pdo_mysql \
        php7-pdo_sqlite \
        php7-phar \
        php7-session \
        php7-sockets \
        php7-xml \
        php7-xmlreader \
    && rm /var/cache/apk/* \

    # Run required config / setup for apache
    # Ensure apache can create pid file
    #&& mkdir /run/apache2 \
    # Fix group
    && sed -i -e 's/Group apache/Group www-data/g' /etc/apache2/httpd.conf \
    # Fix ssl module
    && sed -i -e 's/LoadModule ssl_module lib\/apache2\/mod_ssl.so/LoadModule ssl_module modules\/mod_ssl.so/g' /etc/apache2/conf.d/ssl.conf \
    && sed -i -e 's/LoadModule socache_shmcb_module lib\/apache2\/mod_socache_shmcb.so/LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so/g' /etc/apache2/conf.d/ssl.conf \
    # Enable modules
    && sed -i -e 's/#LoadModule rewrite_module modules\/mod_rewrite.so/LoadModule rewrite_module modules\/mod_rewrite.so/g' /etc/apache2/httpd.conf \
    # Change document root to /app
    && mkdir /app && chown -R apache:apache /app \
    && sed -i -e 's/\/var\/www\/localhost\/htdocs/\/app/g' /etc/apache2/httpd.conf \
    && sed -i -e 's/\/var\/www\/localhost\/htdocs/\/app/g' /etc/apache2/conf.d/ssl.conf \
    # Allow for custom apache configs
    && mkdir /etc/apache2/conf.d/custom \
    && echo '' >> /etc/apache2/httpd.conf \
    && echo 'IncludeOptional /etc/apache2/conf.d/custom/*.conf' >> /etc/apache2/httpd.conf \
    # Fix modules
    && sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf \	
    && sed -i -e 's/ServerRoot \/var\/www/ServerRoot \/etc\/apache2/g' /etc/apache2/httpd.conf \
    && mv /var/www/modules /etc/apache2/modules \
    && mv /var/www/run /etc/apache2/run \
    && mv /var/www/logs /etc/apache2/logs \
    # Empty /var/www and add an index.php to show phpinfo()
    && rm -rf /var/www/* \
    && echo '<?php phpinfo(); ?>' >  /app/phpinfo.php \
    && wget https://github.com/yesinteractive/dad-jokes_microservice/archive/master.zip -P /app  \
    && unzip /app/master.zip -d /app \
    && cp -r /app/dad-jokes_microservice-master/. /app \
    && rm -rf /app/dad-jokes_microservice-master

WORKDIR /app

# Export http and https
EXPOSE 80 443

# Run apache in foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
