#!/bin/sh
SCRIPTS=$(curl https://api.github.com/repos/Complexicon/netboot-sh/contents | jq . [] \| select(.name\|endswith("sh")) \| .name)
echo $SCRIPTS
#sh <(curl -s -L git.cmplx.dev/netboot-sh/raw/main/test.sh) #edit this
