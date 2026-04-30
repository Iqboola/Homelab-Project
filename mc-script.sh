#!/bin/bash

# MC-Server
# CONFIGURATION
SESSION_NAME="server-name"
WORLD_NAME="world-name"
SERVER_DIR="/server/directory"
BACKUP_DIR="/backup/directory"

# PART 1: STOP SERVER
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Sending '/stop' command to Minecraft server in tmux session: $SESSION_NAME"
    tmux send-keys -t "$SESSION_NAME" '/stop' C-m
    echo "Waiting 10 seconds for the server to save the world and shut down..."
    sleep 10

    echo "Killing tmux session: $SESSION_NAME"
    tmux kill-session -t "$SESSION_NAME"
    echo "Server stopped and session killed successfully"
else
    echo "Server session: '$SESSION_NAME' not found. Assuming it's already stopped"
fi

# PART 2: CREATE A DATED & VERSIONED BACKUP
cd "$SERVER_DIR"
MC_VERSION=$(unzip -p server.jar version.json | jq -r '.name')
echo "Zipping server folder (Version: $MC_VERSION)..."
zip -r "$BACKUP_DIR/$WORLD_NAME-ver.${MC_VERSION}"-$(date +%m.%d.%Y_%T).zip .

echo "Backup Complete"

# PART 3: FETCH LATEST SERVER VERSION & DOWNLOAD server.jar FILE
LATEST_VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
VERSION_MANIFEST_URL=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r --arg ver "$LATEST_VERSION" '.versions[] | select(.id == $ver) | .url')
PACKAGE_URL=$(curl -s "$VERSION_MANIFEST_URL" | jq -r '.downloads.server.url')
echo "Fetching latest server version from Mojang..."
echo "Downloading latest server.jar from: $PACKAGE_URL"
rm server.jar
wget -O server.jar "$PACKAGE_URL"
echo "New server.jar file downloaded successfully"

# PART 4: MAKE NEW tmux SESSION AND RUN server.jar FILE
echo "Starting tmux session..."
tmux new-session -d -s "$SESSION_NAME"
chmod +x start.sh
tmux send-keys -t "$SESSION_NAME" './start.sh' C-m
