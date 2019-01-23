#!/bin/bash

# This script generates PHP and PHP-FPM settings overrides passed via environment variables.
# Settings are passed as a text blob. Individual lines should be separated with '; ' (semicolon-space).
#
# Example PHP_SETTINGS:
#
# PHP_SETTINGS='memory_limit=1000M; sendmail_path="/usr/bin/msmtp -t --host=example.com --port=25"'
#
# will be parsed and written to /usr/local/etc/php/conf.d/zzz-php.ini as
#
# memory_limit=1000M
# sendmail_path="/usr/bin/msmtp -t --host=example.com --port=25"
#
# Example PHP_FPM_SETTINGS:
#
# PHP_FPM_SETTINGS='php_admin_value[memory_limit]=500MB; php_value[max_execution_time]=500; php_flag[file_uploads]=Off'
#
# will be parsed and written to /usr/local/etc/php-fpm.d/zzz-php-fpm.conf as
#
# php_admin_value[memory_limit]=500MB
# php_value[max_execution_time]=500
# php_flag[file_uploads]=Off
#
# These settings overwrite the values previously defined in the php.ini. Directives are:
#   php_value/php_flag             - you can set classic ini defines which can
#                                    be overwritten from PHP call 'ini_set'.
#   php_admin_value/php_admin_flag - these directives won't be overwritten by
#                                     PHP call 'ini_set'
# For php_*flag, valid values are on, off, 1, 0, true, false, yes or no.

if [[ "${PHP_SETTINGS}" != "" ]]; then
	echo_debug "Applying custom PHP settings..."
	# Write php settings. '; ' is used as a line separator.
	echo -e "${PHP_SETTINGS}" | sed 's/; /\n/g' > /usr/local/etc/php/conf.d/zzz-php.ini
	echo_debug "\n---\n$(cat /usr/local/etc/php/conf.d/zzz-php.ini)\n---"
fi

if [[ "${PHP_FPM_SETTINGS}" != "" ]]; then
	echo_debug "Applying custom PHP-FPM settings..."
	# Write php-fpm settings. '; ' is used as a line separator.
	echo -e "${PHP_FPM_SETTINGS}" | sed 's/; /\n/g' > /usr/local/etc/php-fpm.d/zzz-php-fpm.conf
	echo_debug "\n---\n$(cat /usr/local/etc/php-fpm.d/zzz-php-fpm.conf)\n---"
fi
