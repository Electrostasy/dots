#!/usr/bin/env bash
# vim: set filetype=bash:

if ! command -v sudo &> /dev/null; then
	echo 'sudo is not found!'
	exit 1
fi

for user_runtime_dir in /run/user/*; do
	user_id="$(basename "$user_runtime_dir")"
	if [ "$user_id" = 0 ] ; then
		echo 'Detected root user, skipping...' >&2
		continue
	fi

	user_name="$(id -un "$user_id")"

	if sudo -u "$user_name" DBUS_SESSION_BUS_ADDRESS="unix:path=$user_runtime_dir/bus" notify-send "$@"; then
		echo "Notification dispatched to user $user_name successfully." >&2
	else
		status=$?
		echo "Notification dispatched to user $user_name unsuccessfully, error code: $status" >&2
	fi
done
