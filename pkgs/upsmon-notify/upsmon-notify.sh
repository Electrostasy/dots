#!/usr/bin/env bash

export PATH="@notify-send-all@/bin:@util-linux@/bin:$PATH"

function notify-send {
	# upsmon is run as an unprivileged user, full path to the executable is
	# useful for sudo rules.
	"$(command -v notify-send-all)" -a 'upsmon' -i 'uninterruptible-power-supply' -c 'device' "$@"
}

mfr="$(upsc "$UPSNAME" 'ups.mfr')"
model="$(upsc "$UPSNAME" 'ups.model')"

# Aliases for long manufacturer names.
case "$mfr" in
	'American Power Conversion') mfr='APC' ;;
	*) ;;
esac

body="$mfr $model reported <i>$NOTIFYTYPE</i>."

# See subsection 'NOTIFYMSG' under section 'CONFIGURATION DIRECTIVES' in
# upsmon.conf(5) for the list of events.
case "$NOTIFYTYPE" in
	'ONLINE')
		notify-send -u 'normal' "$UPSNAME: On line power" "$body" ;;
	'ONBATT')
		notify-send -u 'normal' "$UPSNAME: On battery" "$body" ;;
	'LOWBATT')
		charge="$(upsc "$UPSNAME" 'battery.charge')"
		notify-send -u 'critical' "$UPSNAME: Battery is low at $charge%" "$body" ;;
	'REPLBATT')
		notify-send -u 'critical' "$UPSNAME: Battery needs to be replaced" "$body" ;;
	'FSD')
		notify-send -u 'critical' "$UPSNAME: Forced shutdown in progress" "$body" ;;
	'SHUTDOWN')
		notify-send -u 'critical' "$UPSNAME: Auto logout and shutdown proceeding" "$body" ;;
	'COMMOK')
		notify-send -u 'normal' "$UPSNAME: Communications (re-)established" "$body" ;;
	'COMMBAD')
		notify-send -u 'normal' "$UPSNAME: Communications lost" "$body" ;;
	'NOCOMM')
		notify-send -u 'critical' "$UPSNAME: Not available" "$body" ;;
	'NOPARENT')
		notify-send -u 'critical' "upsmon parent dead, shutdown impossible" "$body" ;;
	'SUSPEND_STARTING')
		notify-send -u 'normal' "$UPSNAME: System is entering suspension" "$body" ;;
	'SUSPEND_FINISHED')
		notify-send -u 'normal' "$UPSNAME: System has left suspension" "$body" ;;
	*)
		echo "Unhandled message $NOTIFYTYPE for UPS $UPSNAME!" | logger -t upsmon-notify -p err ;;
esac
