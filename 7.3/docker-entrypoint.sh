#!/bin/bash

# This script is running as root by default.
# Switching to the docker user can be done via "su -l docker -c '<command>'".

set -eo pipefail
shopt -s nullglob

HOME_DIR='/home/docker'
DEBUG=${DEBUG:-0}

echo_debug ()
{
	if [[ "$DEBUG" != 0 ]]; then echo "$(date +"%F %H:%M:%S") | $@"; fi
}

# Sets docker user's uid/gid to the values passed via $HOST_UID and $HOST_GID environment variables
uid_gid_reset ()
{
	if [[ "$HOST_UID" != "$(id -u docker)" ]] || [[ "$HOST_GID" != "$(id -g docker)" ]]; then
		echo_debug "Updating docker user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		usermod -u "$HOST_UID" -o docker
		groupmod -g "$HOST_GID" -o "$(id -gn docker)"
	fi
}

# Sets ownership on a file/folder to docker:docker
owner_reset ()
{
	chown "${HOST_UID:-1000}:${HOST_GID:-1000}" "$@"
}

# Docker user uid/gid mapping to the host user uid/gid
if [[ "$HOST_UID" != "" ]] && [[ "$HOST_GID" != "" ]]; then uid_gid_reset; fi

# Make sure permissions are correct (after uid/gid change and COPY operations in Dockerfile)
# To not bloat the image size, permissions on the home folder are reset at runtime.
echo_debug "Resetting permissions on $HOME_DIR..."
owner_reset -R "$HOME_DIR"
# Docker resets the project root folder permissions to 0:0 when container is recreated (e.g. an env variable updated).
# We apply a fix/workaround for this at startup (non-recursive).
# TODO: Figure out why this happens and remove this workaround
#echo_debug "Resetting permissions on /var/www..."
#owner_reset /var/www

# Execute available init scripts
# This can be used by child images to run additional provisioning scripts at startup
ls /etc/docker-entrypoint.d/ > /dev/null
for script in /etc/docker-entrypoint.d/*.sh; do
	echo "$0: running ${script}"
	# Note: scripts are sourced (executed in the context of the parent script)
	. "${script}"
done
