FROM alpine:3.11

# make sure you can use HTTPS
RUN apk --update add ca-certificates

# Install packages
RUN apk --no-cache add php php-fpm php-opcache php-openssl php-curl \
    nginx supervisor curl

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY conf/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
# COPY conf/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /app

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Add application
WORKDIR /app
COPY app/ /app

# Switch to use a non-root user from here on
USER nobody

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
# HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
