# BTRFS RAID Maintenance

For maintenance on the BTRFS RAID array, when a disk fails or is near failing
in the array, we need to swap the disk out.

> [!CAUTION]
> You can only mount the array in degraded mode once or your data is lost!

If the disk is still visible in the system, we need to mount it degraded
(because btrfs tools work with mounted filesystems) in recovery mode and issue
a replace command:
```sh
mkdir -p /mnt/array
mount -t btrfs -o degraded /dev/disk/by-label/array /mnt/array
btrfs replace start /dev/disk/by-id/$FAILED /dev/disk/by-id/$NEW /mnt/array
```

If the disk is not visible in the system, we need to identify the missing disk
by its ID and provide it to the replace command:
```sh
btrfs filesystem show # check if there are missing devices.
btrfs device usage /mnt/array # identified by `missing, ID: $FAILED_ID`.
btrfs replace start $FAILED_ID /dev/disk/by-id/$NEW /mnt/array
```

Check the status of the replace operation:
```sh
btrfs replace status /mnt/array
```

After the replace operation finishes, balance the filesystem to ensure data is
evenly distributed between drives in the array:
```sh
btrfs balance start /mnt/array
```
