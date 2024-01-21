#!/bin/sh
# skip 84 bytes to keep ntfs BPB and eBPB intact
# this hack allows ntfs partition created with ntfs-3g to be bootble in legacy bios
dd if=ntldr.bin of=$1 bs=1 skip=84 seek=84
