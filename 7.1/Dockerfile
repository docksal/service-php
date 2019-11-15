FROM php:7.1-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN set -xe; \
	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d; \
	chmod +x /usr/sbin/policy-rc.d

# Set en_US.UTF-8 as the default locale
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get install -y --no-install-recommends >/dev/null locales; \
	rm -rf /var/lib/apt/lists/*; \
	\
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LC_ALL en_US.utf8

# Enable additional repos
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get install -y --no-install-recommends >/dev/null \
		apt-transport-https \
		gnupg \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	# Distro repos
	sed -i 's/main/main contrib non-free/' /etc/apt/sources.list; \
	\
	# MSQSQL repo - msodbcsql17, pecl/sqlsrv and pecl/pdo_sqlsrv (PHP 7.0+ only)
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -; \
	echo 'deb https://packages.microsoft.com/debian/9/prod stretch main' | tee /etc/apt/sources.list.d/mssql.list

# Install additional packages
ARG SUPERCRONIC_VERSION=0.1.6
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get install -y --no-install-recommends >/dev/null \
		busybox \
		cron \
		ghostscript \
		# html2text binary - used for self-testing (php-fpm)
		html2text \
		imagemagick \
		# cgi-fcgi binary - used for self-testing (php-fpm)
		libfcgi-bin \
		msmtp \
		procps \
		webp \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	# Install supercronic - a docker/loggings friendly cron alternative
	curl -fsSL https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64 -o /usr/local/bin/supercronic; \
	chmod +x /usr/local/bin/supercronic

# Create a regular user/group "docker" (uid = 1000, gid = 1000 )
RUN set -xe; \
	groupadd docker -g 1000; \
	useradd -m -s /bin/bash -u 1000 -g 1000 -p docker docker

# PHP
RUN set -xe; \
	# Note: essential build tools (g++, gcc, make, etc) are included upstream as persistent packages.
	# See https://github.com/docker-library/php/blob/4af0a8734a48ab84ee96de513aabc45418b63dc5/7.2/stretch/fpm/Dockerfile#L18-L37
	buildDeps=" \
		git \
		libc-client2007e-dev \
		libfreetype6-dev \
		libgpgme11-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libmhash-dev \
		libpng-dev \
		libpq-dev \
		libwebp-dev \
		libssh2-1-dev \
		libxpm-dev \
		libxslt1-dev \
		libzip-dev \
		unixodbc-dev \
	"; \
	apt-get update >/dev/null; \
	# Necessary for msodbcsql17 (MSSQL)
	ACCEPT_EULA=Y \
	apt-get install -y --no-install-recommends >/dev/null \
		$buildDeps \
		libc-client2007e \
		libfreetype6 \
		libgpgme11 \
		libjpeg62-turbo \
		libldap-2.4-2 \
		libicu63 \
		libmagickcore-6.q16-6 \
		libmagickwand-6.q16-6 \
		libmcrypt4 \
		libmemcached11 \
		libmemcachedutil2 \
		libmhash2 \
		libpng16-16 \
		libpq5 \
		libssh2-1 \
		libxpm4 \
		libxslt1.1 \
		libzip4 \
		msodbcsql17 \
	; \
	# SSH2 must be installed from source for PHP 7.x
	git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2 && rm -rf /usr/src/php/ext/ssh2/.git; \
	\
	docker-php-ext-configure >/dev/null gd \
		--with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
		--with-webp-dir=/usr/include/ \
		--with-png-dir=/usr/include/ \
		--with-xpm-dir=/usr/include/; \
	docker-php-ext-configure >/dev/null imap --with-kerberos --with-imap-ssl; \
	docker-php-ext-configure >/dev/null ldap --with-libdir=lib/x86_64-linux-gnu/; \
	docker-php-ext-configure >/dev/null pgsql --with-pgsql=/usr/local/pgsql/; \
	docker-php-ext-configure >/dev/null zip --with-libzip; \
	\
	docker-php-ext-install >/dev/null -j$(nproc) \
		bcmath \
		bz2 \
		calendar\
		exif \
		gd \
		gettext \
		imap \
		intl \
		ldap \
		# mcrypt is deprecated in 7.1 and removed in 7.2. See Deprecated features.
		mcrypt \
		mysqli \
		opcache \
		pcntl \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		soap \
		sockets \
		ssh2 \
		xsl \
		zip \
	; \
	pecl update-channels; \
	pecl install >/dev/null </dev/null \
		apcu \
		gnupg \
		imagick \
		# Use memcached (not memcache) for PHP 7.x
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
	; \
	docker-php-ext-enable \
		apcu \
		gnupg \
		imagick \
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
	; \
	# Use default PHP settings (production)
	cp -f "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
	\
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	rm -rf /var/lib/apt/lists/*

COPY config/php/zzz-10-php.ini /usr/local/etc/php/conf.d/zzz-10-php.ini
COPY config/php/zzz-10-php-fpm.conf /usr/local/etc/php-fpm.d/zzz-10-php-fpm.conf
COPY config/docker-entrypoint.d /etc/docker-entrypoint.d
COPY config/docker-healthcheck.d /etc/docker-healthcheck.d
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/

ENV \
	# Allow PROJECT_ROOT to be universally used in fin custom commands inside a container
	PROJECT_ROOT=/var/www \
	# Default values for HOST_UID and HOST_GUI to match the default Ubuntu user. These are used in startup.sh
	HOST_UID=1000 \
	HOST_GID=1000

WORKDIR /var/www

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["php-fpm"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["docker-healthcheck.sh"]
