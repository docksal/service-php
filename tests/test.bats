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
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		"$IMAGE"
	docker cp $(pwd)/../tests/scripts "$NAME:/var/www/"

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHP FPM and settings
	run docker exec -u docker "$NAME" /var/www/scripts/test-php-fpm.sh index.php
	# sed below is used to normalize the web output of phpinfo
	# It will transforms "memory_limit                256M                                         256M" into
	# "memory_limit => 256M => 256M", which is much easier to parse
	output=$(echo "$output" | sed -E 's/[[:space:]]{2,}/ => /g')
	echo "$output" | grep "memory_limit => 256M => 256M"
	# sendmail_path, being long, gets printed on two lines. We grep the first line only
	echo "$output" | grep "sendmail_path => /usr/bin/msmtp -t --host=mail -- /usr/bin/msmtp -t --host=mail --"
	# Cleanup output after each "run"
	unset output

	run docker exec -u docker "$NAME" /var/www/scripts/test-php-fpm.sh nonsense.php
	echo "$output" | grep "Status: 404 Not Found"
	unset output

	# Check PHP CLI and settings
	phpInfo=$(docker exec -u docker "$NAME" php -i)

	output=$(echo "$phpInfo" | grep "PHP Version")
	echo "$output" | grep "${VERSION}"
	unset output

	# Confirm WebP support enabled for GD
	output=$(echo "$phpInfo" | grep "WebP Support")
	echo "$output" | grep "enabled"
	unset output

	output=$(echo "$phpInfo" | grep "memory_limit")
	echo "$output" | grep "memory_limit => 1024M => 1024M"
	unset output

	output=$(echo "$phpInfo" | grep "sendmail_path")
	echo "$output" | grep "sendmail_path => /usr/bin/msmtp -t --host=mail --port=1025 => /usr/bin/msmtp -t --host=mail --port=1025"
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
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHP FPM settings overrides
	run make exec -e CMD='/var/www/scripts/test-php-fpm.sh index.php'
	echo "$output" | grep "memory_limit" | grep "512M"
	unset output

	# Check PHP CLI overrides
	run make exec -e CMD='php -i'
	echo "$output" | grep "memory_limit => 128M => 128M"
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

#@test "Check cron" {
#	[[ $SKIP == 1 ]] && skip
#
#	### Setup ###
#	make start
#
#	run _healthcheck_wait
#	unset output
#
#	### Tests ###
#	# Confirm output from cron is working
#
#	# Create tmp date file and confirm it's empty
#	docker exec -u docker "$NAME" bash -lc 'touch /tmp/date.txt'
#	run docker exec -u docker "$NAME" bash -lc 'cat /tmp/date.txt'
#	[[ "${output}" == "" ]]
#	unset output
#
#	# Sleep for 60+1 seconds so cron can run again.
#	sleep 61
#
#	# Confirm cron has ran and file contents has changed
#	run docker exec -u docker "$NAME" bash -lc 'tail -1 /tmp/date.txt'
#	[[ "${output}" =~ "The current date is " ]]
#	unset output
#
#	### Cleanup ###
#	make clean
#}
