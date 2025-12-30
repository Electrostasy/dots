#!/usr/bin/env bash
# vim: set filetype=bash:

set -o errexit

if [ $# -eq 0 ]; then
	# Print the default error if no arguments are supplied.
	notify-send
fi

for user_runtime_dir in /run/user/*; do
	bus="$user_runtime_dir/bus"
	if ! [ -S "$bus" ]; then
		continue
	fi

	uid="${user_runtime_dir##*/}"
	gid="$(id -g "$uid")"

	# We need to convince notify-send that we are this user so notify-send
	# can connect to the user's D-Bus bus. D-Bus checks the caller UID, and
	# this is more lightweight than using sudo to switch users temporarily.
	if ! DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" setpriv --reuid "$uid" --regid "$gid" --init-groups notify-send "$@"; then
		echo "notify-send for user $uid failed with exit code: $?" >&2
	fi
done
