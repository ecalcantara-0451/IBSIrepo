#!/bin/bash

# Tenable Agent version and download URL
AGENT_VERSION="8.4.1"
AGENT_FILE="TenableAgent-${AGENT_VERSION}-ubuntu1110_amd64.deb"
DOWNLOAD_URL="https://downloads.tenable.com/agent/${AGENT_FILE}"

# Linux group name for Tenable Agent
GROUP_NAME="FGEN-AWS"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)."
  exit 1
fi

# Ensure the group exists
if ! getent group "$GROUP_NAME" > /dev/null; then
  echo "👥 Creating group '$GROUP_NAME'..."
  groupadd "$GROUP_NAME"
fi

echo "📦 Downloading Tenable Agent..."
wget -q --show-progress "$DOWNLOAD_URL" -O "/tmp/${AGENT_FILE}"

if [ $? -ne 0 ]; then
  echo "❌ Download failed. Please check the URL or your network."
  exit 2
fi

echo "📥 Installing Tenable Agent..."
dpkg -i "/tmp/${AGENT_FILE}" || apt-get install -f -y

echo "👥 Assigning agent binaries to group '$GROUP_NAME'..."
chown root:"$GROUP_NAME" /opt/tenable/agent/bin/*
chmod 750 /opt/tenable/agent/bin/*

echo "🔧 Registering Agent (replace values below)..."
/opt/tenable/agent/bin/tenable-core -m register \
  --key=0108ea830a4c81a43cc824da2968d94e5cbf9ce7d9320cb34d9061da4d30531d \
  --host=sensor.cloud.tenable.com \
  --port=443

echo "🚀 Starting and enabling Tenable Agent service..."
systemctl start tenable-agent
systemctl enable tenable-agent

echo "✅ Tenable Agent installation complete!"
