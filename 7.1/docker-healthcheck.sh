#!/usr/bin/env bash

# Fail if any of the healthchecks failed
set -e

# Execute available healthcheck scripts
# This can be used by child images to run additional provisioning scripts at startup
ls /etc/docker-healthcheck.d/ > /dev/null
for script in /etc/docker-healthcheck.d/*.sh; do
	echo "$0: running ${script}"
	# Note: scripts are sourced (executed in the context of the parent script)
	. "${script}"
done
