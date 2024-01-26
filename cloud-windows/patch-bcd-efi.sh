#!/bin/sh
TO_PATCH="\xC1\x6E\x42\x4A\x9D\xC8\xD3\x48\x8E\xA0\x7A\x85\x9A\x82\x6C\x85\x00\x00\x00\x00\x00\x00\x00\x00\x8F\x62\x5E\x6A\x8C\x8B\x03\x42\x87\x49\x8D\x34\xE3\x8E\xCC\xC0"
MATCHES=$(LANG=C grep --only-matching --byte-offset --binary --text --perl-regexp "$TO_PATCH" BCD_reference_efi | cut -d: -f1)

DISK_UUID=$(sfdisk --disk-id $1)
PART_UUID=$(sfdisk --part-uuid $1 $2)

printf "{disk=%s,part=%s}\n" $DISK_UUID $PART_UUID

./uuid2bin.sh "$DISK_UUID" DISK.bin
./uuid2bin.sh "$PART_UUID" PART.bin

cp BCD_reference_efi BCD_patched_efi

for x in $MATCHES
do
    echo "patching at [$x]"
    dd if=PART.bin of=BCD_patched_efi bs=1 seek=$x conv=notrunc status=none
    dd if=DISK.bin of=BCD_patched_efi bs=1 seek=$(($x + 24)) conv=notrunc status=none
done
