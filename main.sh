#!/bin/sh

_source_from_git() {
  source <(curl -s -L git.cmplx.dev/netboot-sh/raw/main/$1)
}

load_script() {
  _source_from_git scripts/$1
}

load_util(){
  _source_from_git utils/$1
}

while true
do
  SCRIPTS=$(curl --silent https://api.github.com/repos/Complexicon/netboot-sh/contents/scripts?ref=main | jq -r ". [] | select(.name|endswith(\"sh\")) | .name")
  echo "Choose which script to run"
  SCRIPT_TO_RUN=$(echo "$SCRIPTS" | gum choose)
  echo "Running '$SCRIPT_TO_RUN'..."
  load_script $SCRIPT_TO_RUN
done
