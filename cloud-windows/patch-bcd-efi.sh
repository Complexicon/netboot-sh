#!/bin/sh
TO_PATCH="\x00\x00\x50\x1F\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x16\x13\x2B\x32\x00\x00\x00\x00"
MATCHES=$(LANG=C grep --only-matching --byte-offset --binary --text --perl-regexp "$TO_PATCH" BCD_reference_bios | cut -d: -f1)

DISK_UUID=$(sfdisk --disk-id $1)
PART_UUID=$(sfdisk --part-uuid $1 $2)

printf "{disk=%s,part=%s}\n" $DISK_UUID $PART_UUID

./uuid2bin.sh "$DISK_UUID" DISK.bin
./uuid2bin.sh "$PART_UUID" PART.bin

for x in $MATCHES
do
    echo "patching at [$x]"
    dd if=PART.bin of=BCD_patched_bios bs=1 seek=$x conv=notrunc
    dd if=DISK.bin of=BCD_patched_bios bs=1 seek=$(($x + 24)) conv=notrunc
done
