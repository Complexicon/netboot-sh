#!/bin/sh
WINBASE="/mnt/win"
NTLDR_SRC="$WINBASE/Windows/System32/autofmt.exe"
NTLDR_MAGIC="\xEB\x52\x90\x4E\x54\x46\x53\x20\x20\x20\x20"
OFFSET=$(LANG=C grep --only-matching --byte-offset --binary --text --perl-regexp "$NTLDR_MAGIC" "$NTLDR_SRC" | cut -d: -f1)
echo "Found NTLDR at $OFFSET"
dd if="$NTLDR_SRC" of=ntldr.bin bs=1 skip=$OFFSET count=8192
