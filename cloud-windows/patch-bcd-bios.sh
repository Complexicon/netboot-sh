#!/bin/sh
TO_PATCH="\x00\x00\x50\x1F\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x16\x13\x2B\x32\x00\x00\x00\x00"
MATCHES=$(LANG=C grep --only-matching --byte-offset --binary --text --perl-regexp "$TO_PATCH" BCD_reference_bios | cut -d: -f1)

NEW_UUID=$(partx --show $1 -o UUID -g | cut -d- -f1)
NEW_UUID=$((0x$NEW_UUID))
NEW_START=$(partx --show $1 -o START -g)
NEW_START=$(($NEW_START * 512))

printf "new: {disk=%x,partition=%x}\n" $NEW_UUID $NEW_START

printf "0: %.8x" $NEW_UUID  | sed -e 's/0\: \(..\)\(..\)\(..\)\(..\)/0\: \4\3\2\1/' | xxd -r -g0 > UUID
printf "0: %.8x" $NEW_START | sed -e 's/0\: \(..\)\(..\)\(..\)\(..\)/0\: \4\3\2\1/' | xxd -r -g0 > OFFSET

cp BCD_reference_bios BCD_patched_bios

for x in $MATCHES
do
    echo "patching at [$x]"
    dd if=OFFSET of=BCD_patched_bios bs=1 seek=$x
    dd if=UUID of=BCD_patched_bios bs=1 seek=$(($x + 24))
done
