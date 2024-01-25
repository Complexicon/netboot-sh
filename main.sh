#!/bin/sh

while true
do
  SCRIPTS=$(curl --silent https://api.github.com/repos/Complexicon/netboot-sh/contents/scripts?ref=main | jq -r ". [] | select(.name|endswith(\"sh\")) | .name")
  echo "Choose which script to run"
  SCRIPT_TO_RUN=$(echo "$SCRIPTS" | gum choose)
  echo "Running '$SCRIPT_TO_RUN'..."
  sh <(curl -s -L git.cmplx.dev/netboot-sh/raw/main/scripts/${SCRIPT_TO_RUN})
done
