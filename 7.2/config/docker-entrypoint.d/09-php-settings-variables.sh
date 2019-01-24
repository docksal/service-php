#!/bin/bash

# This script generates PHP and PHP-FPM settings overrides passed via environment variables.
#
# Example PHP_SETTINGS:
#
# PHP_SETTINGS='
# memory_limit=1000M
# sendmail_path="/usr/bin/msmtp -t --host=example.com --port=25"
# '
#
# will be to /usr/local/etc/php/conf.d/zzz-php.ini as
#
# memory_limit=1000M
# sendmail_path="/usr/bin/msmtp -t --host=example.com --port=25"
#
# Example PHP_FPM_SETTINGS:
#
# PHP_FPM_SETTINGS='
# php_value[memory_limit]=500M
# php_value[max_execution_time]=500
# '
#
# will be written to /usr/local/etc/php-fpm.d/zzz-php-fpm.conf as
#
# php_value[memory_limit]=500M
# php_value[max_execution_time]=500
#
# These settings overwrite the values previously defined in the php.ini. Directives are:
#   php_value/php_flag             - you can set classic ini defines which can
#                                    be overwritten from PHP call 'ini_set'.
#   php_admin_value/php_admin_flag - these directives won't be overwritten by
#                                     PHP call 'ini_set'
# For php_*flag, valid values are on, off, 1, 0, true, false, yes or no.

# Write php settings from PHP_SETTINGS env variable
if [[ "${PHP_SETTINGS}" != "" ]]; then
	dst_file='/usr/local/etc/php/conf.d/zzz-30-php.ini'
	echo_debug "Applying custom PHP settings from PHP_SETTINGS environment variable..."
	echo "${PHP_SETTINGS}" > ${dst_file}
	# Print settings for verification
	echo_debug "\n---\n$(cat ${dst_file})\n---"
	unset dst_file
fi

# Write php-fpm settings from PHP_FPM_SETTINGS env variable
if [[ "${PHP_FPM_SETTINGS}" != "" ]]; then
	dst_file='/usr/local/etc/php-fpm.d/zzz-30-php-fpm.conf'
	echo_debug "Applying custom PHP-FPM settings from PHP_FPM_SETTINGS environment variable..."
	echo "${PHP_FPM_SETTINGS}" > ${dst_file}
	# Print settings for verification
	echo_debug "\n---\n$(cat ${dst_file})\n---"
fi
