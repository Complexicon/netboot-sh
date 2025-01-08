#!/bin/sh

## setup vscode for user

PLATFORM=$(uname -m)

case $PLATFORM in
    "aarch64")
        PLATFORM="arm64";;
    *)
        PLATFORM="x64";;
esac

DOWNLOAD_URL=$(curl -s https://api.github.com/repos/gitpod-io/openvscode-server/releases/latest | grep "/openvscode-server-v.*-linux-$PLATFORM.tar.gz" | cut -d : -f 2,3 | tr -d \")

if [ "$(id -u)" -ne "0" ] ; then
    echo "This script must be executed with root privileges."
    exit 1
fi

read -p "Enter username for which to create a vscode instance: " username
read -p "Enter port for vscode to listen to: " port

mkdir -p /opt/vscode
cd /opt/vscode
wget -q --show-progress --progress=dot -c $DOWNLOAD_URL -O - | tar -xz --strip-components 1


cat > /etc/systemd/system/vscode-$username.service << EOF
[Service]
User=$username
ExecStart=/opt/vscode/bin/openvscode-server --without-connection-token --port $port --host 0.0.0.0
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Enable: systemctl enable vscode-$username.service"
echo "Enable: systemctl start vscode-$username.service"
