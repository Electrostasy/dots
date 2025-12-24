#!/usr/bin/env bash
# vim: set filetype=bash:

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

			# unset "${!ID_*}"
			# while read -r line; do
			# 	declare ${line/%=*}="${line/#*=}"
			# done < <(systemd-hwdb query "$(cat "$device_path/modalias")")
			# echo "$child_id $parent_id $device: $ID_VENDOR_FROM_DATABASE $ID_MODEL_FROM_DATABASE"

			# while read -r key value; do
			# 	if [ -n "$value" ]; then
			# 		declare ${key/%\:}="$value"
			# 	fi
			# done < <(lspci -vmm -s "$device")
			# echo "$child_id $parent_id $device: $Class - $Vendor $Device"

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

			# for block_device_path in /dev/disk/by-path/pci-"$device"*; do
			# 	if [ -d "$block_device_path" ] || [[ "$block_device_path" == *part* ]]; then
			# 		continue
			# 	fi
			#
			# 	(
			# 		source <(udevadm info --export "$block_device_path" --query=property)
			# 		echo "$child_id $subsystem_parent_id $ID_MODEL ($ID_SERIAL_SHORT)"
			# 	)
			# 	child_id=$((child_id+1))
			# done
		done
	done < <(printf '%s\n' /sys/kernel/iommu_groups/* | sort -V)
)
