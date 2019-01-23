#!/bin/bash

# This script generates crontab settings passed the CRONTAB environment variable.
# Settings are passed as a text blob. Individual lines should be separated '; ' (semicolon-space).
#
# Example:
#
# CRONTAB='*/1 * * * * echo "$(date): I run every minute" >> /tmp/dummy.txt; */2 * * * * echo "$(date): I run every two minutes" >> /tmp/dummy.txt'
#
# will parsed and written to docker user's crontab as
#
# */1 * * * * touch /tmp/dummy.txt; echo "$(date): I run every minute" >> /tmp/dummy.txt
# */2 * * * * touch /tmp/dummy.txt; echo "$(date): I run every two minutes" >> /tmp/dummy.txt
#

if [[ "${CRONTAB}" != "" ]]; then
	echo_debug "Applying crontab settings..."
	# Configure crontabs. '; ' is used as a line separator
	echo -e "${CRONTAB}" | sed 's/; /\n/g' | crontab -u docker -
	# List configured crontabs
	echo_debug "\n---\n$(crontab -l -u docker)\n---"
fi
