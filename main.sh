#!/bin/sh
SCRIPTS=$(curl --silent https://api.github.com/repos/Complexicon/netboot-sh/contents/scripts?ref=main | jq -r ". [] | select(.name|endswith(\"sh\")) | .name")
echo "Choose which script to run"
SCRIPT_TO_RUN=$(echo "$SCRIPTS" | gum choose)
sh <(curl -s -L git.cmplx.dev/netboot-sh/raw/main/${SCRIPT_TO_RUN})
