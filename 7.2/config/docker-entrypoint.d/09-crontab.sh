#!/bin/bash

# This script generates crontab settings for the docker user from the CRONTAB environment variable.
#
# Example:
#
# CRONTAB='
# */1 * * * * echo "$(date): I run every minute" >> /tmp/dummy.txt
# */2 * * * * echo "$(date): I run every two minutes" >> /tmp/dummy.txt
# '
#

# Configure crontabs
if [[ "${CRONTAB}" != "" ]]; then
	echo_debug "Applying crontab settings..."
	echo -e "${CRONTAB}" | crontab -u docker -
	# Print crontab for verification
	echo_debug "\n---\n$(crontab -l -u docker)\n---"
fi
