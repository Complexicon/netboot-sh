#!/bin/sh
FIRST=$(echo "$1" | cut -d- -f1)
SECOND=$(echo "$1" | cut -d- -f2)
THIRD=$(echo "$1" | cut -d- -f3)
FOURTH=$(echo "$1" | cut -d- -f4)
FIFTH=$(echo "$1" | cut -d- -f5)

function byteswap() {
  echo $(echo "$1" | sed -e 's/\(..\)\{0,1\}\(..\)\{0,1\}\(..\)\(..\)/\4\3\2\1/')
}

BYTESWAP=$(byteswap $FIRST)$(byteswap $SECOND)$(byteswap $THIRD)
KEEP=$FOURTH$FIFTH

echo "ref: $FIRST $SECOND $THIRD $FOURTH $FIFTH"
printf "0: %x%x\n" $((0x$BYTESWAP)) $((0x$KEEP)) | xxd -r -g0 > $2
