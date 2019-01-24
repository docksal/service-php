#!/bin/bash

# Support project level PHP and PHP-FPM settings overrides via configuration files.

# Symlink project level PHP settings
src_file='/var/www/.docksal/etc/php/php.ini'
dst_file='/usr/local/etc/php/conf.d/zzz-20-php.ini'
if [[ -f ${src_file} ]]; then
	echo_debug "Applying custom PHP settings from ${src_file}..."
	ln -s ${src_file} ${dst_file}
	echo_debug "\n---\n$(cat ${dst_file})\n---"
fi
unset src_file dst_file

# Symlink project level PHP-FPM settings
src_file='/var/www/.docksal/etc/php/php-fpm.conf'
dst_file='/usr/local/etc/php-fpm.d/zzz-20-php-fpm.conf'
if [[ -f ${src_file} ]]; then
	echo_debug "Applying custom PHP settings from ${src_file}..."
	ln -s ${src_file} ${dst_file}
	echo_debug "\n---\n$(cat ${dst_file})\n---"
fi
unset src_file dst_file
