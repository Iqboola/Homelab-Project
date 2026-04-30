# HOME-LAB / SERVER CLUSTER
**System Version: 2025.1**
**Category: Infrastructure / DevOps**

A high-availability mini-rack server cluster engineered for near-maximum uptime, running a containerized microservice architecture. This project focuses on reliability, safe failover, and secure remote access.

## OVERVIEW
The primary objective was the construction of a robust hardware and software environment capable of hosting various self-hosted services. The architecture prioritizes data integrity and service availability, specifically for remote file storage, media hosting, and video game servers. Unfortunately, due to hardware limitations, this server was forced to retire

## CORE ARCHITECTURE
- **Orchestration:** Docker / Containerized environment
- **Networking:** TCP/IP, Tailscale Mesh VPN
- **Automation:** Bash Scripting / Shell Automation
- **Storage:** 3TB+ Redundant Array
- **Resilience:** APC UPS Integration via `apcupsd`

## TECHNICAL IMPLEMENTATION

### 01: UPS IMPLEMENTATION
The foundation of the cluster's reliability is a dedicated Uninterruptible Power Supply. Configured via `apcupsd` to handle power fluctuations and execute graceful system shutdowns during extended outages, preventing file system corruption.

### 02: CONTAINER ALLOCATION
Microservices are isolated and managed through Docker. This allows for rapid deployment, resource capping, and independent scaling of services including:
- Remote File Storage (NAS)
- Media Streaming Servers
- Dedicated Minecraft Instances
- Monitoring Dashboards

### 03: SECURE ACCESS
Network security is handled through Tailscale, providing a zero-config mesh VPN. This enables secure, encrypted tunneling to the cluster from any remote location without exposing ports to the public internet.

## PERFORMANCE METRICS
| Metric | Value |
| :--- | :--- |
| **Availability** | 99.99% Uptime |
| **Storage** | 3.0+ TBs |
| **Service Density** | 10+ Microservices |
| **Throughput** | 550+ Mbps (Avg) |

## SERVER AUTOMATION
The following script manages the lifecycle of the Minecraft service, handling graceful shutdowns, versioned backups, and automated updates. Feel free to edit and use this script however you see fit. All things considered, it works pretty well, especially since it doesn't require docker. I am not responsible for any hardware failures from this script.

```bash
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
```

---
*Homelab Documentation / 2025*
