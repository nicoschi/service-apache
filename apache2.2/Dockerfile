FROM httpd:2.2.34-alpine

# Build mod_proxy_fcgi from source
RUN set -x \
	&& buildDeps=' \
		autoconf \
		gcc \
		git \
		libc-dev \
		make \
	' \
	&& apk add --no-cache \
		$buildDeps \
	\
	&& git clone https://github.com/ceph/mod-proxy-fcgi \
	&& cd mod-proxy-fcgi \
	&& autoconf \
	&& ./configure \
	&& make \
	&& make install \
	&& cd .. && rm -rf mod-proxy-fcgi \
	\
	&& apk del $buildDeps

# Generate a self-signed cert
RUN apk add --no-cache openssl \
	&& openssl req -batch -x509 -newkey rsa:4096 -days 3650 -nodes -sha256 -subj "/" \
		-keyout /usr/local/apache2/conf/server.key -out /usr/local/apache2/conf/server.crt \
	&& apk del openssl

# Configure Apache environment variables
ENV \
	APACHE_DOCUMENTROOT=/var/www/docroot \
	APACHE_FCGI_HOST_PORT="cli:9000"

RUN set -x \
	# Enabled extra modules
	&& sed -i '/^#.* proxy_module /s/^#//' /usr/local/apache2/conf/httpd.conf \
	&& sed -i '/^LoadModule proxy_module /a LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so' /usr/local/apache2/conf/httpd.conf \
	&& sed -i '/^#.* proxy_connect_module /s/^#//' /usr/local/apache2/conf/httpd.conf \
	&& sed -i '/^#.* ssl_module /s/^#//' /usr/local/apache2/conf/httpd.conf \
	&& sed -i '/^#.* rewrite_module /s/^#//' /usr/local/apache2/conf/httpd.conf \
	# Enable extra config files
	&& sed -i '/^#.* conf\/extra\/httpd-vhosts.conf/s/^#//' /usr/local/apache2/conf/httpd.conf \
	# Used for runtime config overrides
	&& mkdir -p /usr/local/apache2/conf/custom \
	# Link out custom docroot location to the default htdocs folder by default
	&& mkdir -p /var/www \
	&& ln -s /usr/local/apache2/htdocs $APACHE_DOCUMENTROOT

COPY httpd-foreground /usr/local/bin/
COPY conf /usr/local/apache2/conf
COPY healthcheck.sh /opt/healthcheck.sh

WORKDIR /var/www

EXPOSE 80 443

CMD ["httpd-foreground"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["/opt/healthcheck.sh"]
