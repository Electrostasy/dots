#!/usr/bin/env bash
# vim: set filetype=bash:

while [[ $# -gt 0 ]]; do
	case "$1" in
		'-h'|'--help')
			echo 'Lists the IOMMU groups in your system in tree format with identified PCI and USB devices'
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			exit 1
	esac
done

if [ -z "$(ls -A /sys/kernel/iommu_groups)" ]; then
	echo 'No IOMMU groups found!' >&2
	exit 1
fi

column --tree-id 1 --tree-parent 2 --tree 3 --table-hide 1,2 --table-columns-limit 3 <(
	shopt -s nullglob

	child_id=0
	echo "-1 -2 IOMMU Groups"
	while read -r group_path; do
		iommu_group="$(basename "$group_path")"

		echo "$child_id -1 Group $iommu_group"
		parent_id="$child_id"
		child_id=$((child_id+1))

		for device_path in "$group_path"/devices/*; do
			device="$(basename "$device_path")"

			echo "$child_id $parent_id $(lspci -nn -s "$device")"
			subsystem_parent_id="$child_id"
			child_id=$((child_id+1))

			for usb_device_path in "$device_path"/usb*/*-*; do
				if ! [ -e "$usb_device_path/busnum" ] || ! [ -e "$usb_device_path/devnum" ]; then
					continue
				fi
				bus_num="$(cat "$usb_device_path/busnum")"
				dev_num="$(cat "$usb_device_path/devnum")"

				echo "$child_id $subsystem_parent_id $(lsusb -s "$bus_num:$dev_num")"
				child_id=$((child_id+1))
			done
		done
	done < <(printf '%s\n' /sys/kernel/iommu_groups/* | sort -V)
)
