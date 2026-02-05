#!/usr/bin/env bash
# vim: set filetype=bash:

if (( EUID != 0 )); then
	echo "notify-send-all requires root privileges in order to access another user's D-Bus session bus!" >&2
	exit 1
fi

for bus in /run/user/*/bus; do
	if [ ! -S "$bus" ]; then
		continue
	fi

	uid="$(stat -c '%u' "$bus")"
	gid="$(stat -c '%g' "$bus")"

	if ! DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" setpriv --reuid "$uid" --regid "$gid" --init-groups notify-send "$@"; then
		code=$?
		echo "notify-send for user $uid failed with exit code: $code" >&2
		exit $code
	fi
done
