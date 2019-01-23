#!/usr/bin/env bats

# Debugging
teardown () {
	echo
	echo "Output:"
	echo "================================================================"
	echo "${output}"
	echo "================================================================"
}

# Checks container health status (if available)
# @param $1 container id/name
_healthcheck ()
{
	local health_status
	health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$1" 2>/dev/null)

	# Wait for 5s then exit with 0 if a container does not have a health status property
	# Necessary for backward compatibility with images that do not support health checks
	if [[ $? != 0 ]]; then
		echo "Waiting 10s for container to start..."
		sleep 10
		return 0
	fi

	# If it does, check the status
	echo $health_status | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
_healthcheck_wait ()
{
	# Wait for container to become ready by watching its health status
	local container_name="${NAME}"
	local delay=5
	local timeout=30
	local elapsed=0

	until _healthcheck "$container_name"; do
		echo "Waiting for $container_name to become ready..."
		sleep "$delay";

		# Give the container 30s to become ready
		elapsed=$((elapsed + delay))
		if ((elapsed > timeout)); then
			echo "$container_name heathcheck failed"
			exit 1
		fi
	done

	return 0
}

# To work on a specific test:
# run `export SKIP=1` locally, then comment skip in the test you want to debug

@test "Essential binaries" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# List of binaries to check
	binaries='\
		cat \
		convert \
		curl \
		g++ \
		ghostscript \
		gcc \
		html2text \
		make \
		more \
		msmtp \
	'

	# Check all binaries in a single shot
	run make exec -e CMD="type $(echo ${binaries} | xargs)"
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Bare service" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHP-CLI settings defaults
	php_cli_info=$(make exec -e CMD="php -r 'phpinfo(INFO_ALL);'")

	output=$(echo "${php_cli_info}" | egrep "^PHP Version" | head -1)
	[[ "${output}" =~ "${VERSION}" ]]
	unset output

	output=$(echo "${php_cli_info}" | egrep "^memory_limit")
	[[ "${output}" ==  "memory_limit => 256M => 256M" ]]
	unset output

	output=$(echo "${php_cli_info}" | egrep "^sendmail_path")
	[[ "${output}" == "sendmail_path => /bin/false => /bin/false" ]]
	unset output

	# Check PHP-FPM settings defaults
	php_fpm_info=$(make exec -e CMD='/var/www/scripts/test-php-fpm.sh index.php')
	# sed below is used to normalize the web output of phpinfo
	# It will transforms "memory_limit                256M                                         256M" into
	# "memory_limit => 256M => 256M", which is much easier to parse
	php_fpm_info=$(echo "${php_fpm_info}" | sed -E 's/[[:space:]]{2,}/ => /g')

	output=$(echo "${php_fpm_info}" | egrep "^memory_limit")
	[[ "${output}" == "memory_limit => 256M => 256M" ]]
	unset output

	# Cleanup output after each "run"
	unset output

	run make exec -e CMD='/var/www/scripts/test-php-fpm.sh nonsense.php'
	[[ "${output}" =~  "Status: 404 Not Found" ]]
	unset output

	# Check PHP modules
	run bash -lc "docker exec -u docker '${NAME}' php -m | diff php-modules.txt -"
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

# Examples of using Makefile commands
# make start, make exec, make clean
@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	DOCKSAL_ENVIRONMENT=php-settings \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHP-CLI settings overrides
	php_cli_info=$(make exec -e CMD="php -r 'phpinfo(INFO_CONFIGURATION);'")

	output=$(echo "${php_cli_info}" | egrep "^memory_limit")
	echo "${output}" | grep "memory_limit => 1000M => 1000M"
	unset output

	output=$(echo "${php_cli_info}" | egrep "^sendmail_path")
	[[ "${output}" == "sendmail_path => /usr/bin/msmtp -t --host=example.com --port=25 => /usr/bin/msmtp -t --host=example.com --port=25" ]]
	unset output

	# Check PHP-FPM settings overrides
	php_fpm_info=$(make exec -e CMD='/var/www/scripts/test-php-fpm.sh index.php')
	# sed below is used to normalize the web output of phpinfo
	# It will transforms "memory_limit                256M                                         256M" into
	# "memory_limit => 256M => 256M", which is much easier to parse
	php_fpm_info=$(echo "${php_fpm_info}" | sed -E 's/[[:space:]]{2,}/ => /g')

	output=$(echo "${php_fpm_info}" | egrep "^memory_limit")
	[[ "${output}" == "memory_limit => 500MB => 500MB" ]]
	unset output

	output=$(echo "${php_fpm_info}" | egrep "^max_execution_time")
	[[ "${output}" == "max_execution_time => 500 => 500" ]]
	unset output

	output=$(echo "${php_fpm_info}" | egrep "^file_uploads")
	[[ "${output}" == "file_uploads => Off => Off" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check cron" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	DOCKSAL_ENVIRONMENT=cron \
	CMD='cron -f' \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###
	# Confirm output from cron is working

	# Give cron 60s to invoke the scheduled test job
	sleep 60
	# Confirm cron has run and file contents has changed
	run docker exec -u docker "$NAME" bash -lc 'cat /tmp/dummy.txt'
	[[ "${output}" =~ "I run every minute" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check supercronic" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	DOCKSAL_ENVIRONMENT=cron \
	CMD='supercronic /var/spool/cron/crontabs/docker' \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###
	# Confirm output from cron is working

	# Give cron 60s to invoke the scheduled test job
	sleep 60
	# Confirm cron has run and file contents has changed
	run docker exec -u docker "$NAME" bash -lc 'cat /tmp/dummy.txt'
	[[ "${output}" =~ "I run every minute" ]]
	unset output

	### Cleanup ###
	make clean
}

#@test "Check custom startup script" {
#	[[ $SKIP == 1 ]] && skip
#
#	make start
#
#	run _healthcheck_wait
#	unset output
#
#	run docker exec -u docker "${NAME}" cat /tmp/test-startup.txt
#	[[ ${status} == 0 ]]
#	[[ "${output}" =~ "I ran properly" ]]
#	unset output
#
#	### Cleanup ###
#	make clean
#}
