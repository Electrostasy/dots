#!/usr/bin/env bash

while getopts "i:p:s" opt; do
  case $opt in
    i)
      IMAGE="$OPTARG"
      ;;
    p)
      PARTITION="$OPTARG"
      ;;
    s)
      # Spawn a specific shell at the mountpoint instead of the user login shell.
      SHELL="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# If partition is not provided, interactively select partition to mount.
if [[ -v PARTITION && -n "$PARTITION" ]]; then
  OFFSET=$(sfdisk -J "$IMAGE" | jq ".partitiontable | .sectorsize * .partitions[$((PARTITION-1))].start")
else
  # Process the list of partition types for mapping to partition IDs.
  declare -A PARTTYPES
  while IFS=' ' read -r ID NAME; do
    PARTTYPES["$ID"]="$NAME"
  done < <(STR=$(sfdisk -T); echo "${STR:10}")

  # Process the list of partitions.
  # shellcheck disable=SC2155
  declare -A PARTITIONS="($(
    sfdisk -J "$IMAGE" | jq -r '
      .partitiontable
      | .sectorsize as $sectorsize
      | .partitions
      | to_entries
      | map(@sh "[\(.key)]=\(.value | "\(.start * $sectorsize) \(.size * $sectorsize) \(.type) \(.bootable == true)")").[]
    '
  ))"

  # Process options list for interactive selection.
  declare -A OPTIONS
  for IDX in "${!PARTITIONS[@]}"; do
    while IFS=' ' read -ra VALUES; do
      read -r START SIZE TYPE BOOTABLE < <(echo "${VALUES[@]}")

      if [[ "$BOOTABLE" == 'true' ]]; then
        BOOTABLE=' (bootable)'
      else
        BOOTABLE=''
      fi

      OPTIONS["$(numfmt --to iec --format '%8.2f' "$SIZE") ${PARTTYPES[$TYPE]} partition$BOOTABLE"]="$START"
    done <<< "${PARTITIONS[$IDX]}"
  done

  # Select a partition and get its offset.
  PS3='Select a partition: '
  select OPT in "${!OPTIONS[@]}"; do
    case $OPT in
      *)
        OFFSET="${OPTIONS[$OPT]}"
        break ;;
    esac
  done
fi

if [ -z "$OFFSET" ]; then
  echo "No partition offset found for image '$IMAGE', aborting"
  exit 1
else
  echo "Mounting image '$IMAGE' partition at offset $OFFSET"
fi

LOOP_SETUP=$(udisksctl loop-setup -f "$IMAGE" -o "$OFFSET")
LOOP_DEVPATH=${LOOP_SETUP:16+${#IMAGE}:-1}
MOUNT_MSG=$(udisksctl mount -b "$LOOP_DEVPATH")

# We cannot `cd` to the mounted directory, because that messes with unmounting
# after we leave the shell. `pushd` and `popd` work, but should be silenced.
pushd "${MOUNT_MSG##* }" > /dev/null
$SHELL
popd > /dev/null

udisksctl unmount -b "$LOOP_DEVPATH" && udisksctl loop-delete -b "$LOOP_DEVPATH"
