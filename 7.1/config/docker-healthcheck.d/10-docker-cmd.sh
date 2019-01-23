#!/bin/bash

# Get the name of the process with pid=1
docker_cmd=$(ps -p 1 -o comm=)

# Check php config if running php-fpm
if [[ "${docker_cmd}" == "php-fpm" ]]; then
	php-fpm -t
fi

# Check crontab if running crond/supercronic
if [[ "${docker_cmd}" == "cron" ]] || [[ "${docker_cmd}" == "supercronic" ]]; then
	crontab -u docker -l
fi
