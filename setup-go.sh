printf "Checking latest Go version...\n";
LATEST_GO_VERSION="$(curl --silent https://go.dev/VERSION?m=text | head -n 1)";

PLATFORM=$(uname -m)

case $PLATFORM in
    "aarch64")
        PLATFORM="arm64";;
    *)
        PLATFORM="amd64";;
esac

LATEST_GO_DOWNLOAD_URL="https://go.dev/dl/${LATEST_GO_VERSION}.linux-$PLATFORM.tar.gz"

printf "cd to home ($USER) directory \n"
cd $HOME

printf "Downloading ${LATEST_GO_DOWNLOAD_URL}\n\n";
curl -OJ -L --progress-bar $LATEST_GO_DOWNLOAD_URL

printf "Extracting file...\n"
tar -xf ${LATEST_GO_VERSION}.linux-$PLATFORM.tar.gz

export GOROOT="$HOME/go"
export GOPATH="$HOME/go/packages"
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

printf 'ADD THIS TO YOUR ~/.bashrc

export GOROOT="$HOME/go"
export GOPATH="$HOME/go/packages"
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
\n'

printf "You are ready to Go!";
go version
