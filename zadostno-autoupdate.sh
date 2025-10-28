#!/bin/bash
# Setup script for git pull systemd service
# Automatically detect repository directory and user

TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 || echo "/home/$TARGET_USER")"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Creating systemd service and timer to auto-update repository..."

# 1. Create the service file (expand variables in the here-doc so the resolved paths/users are written)
sudo tee /etc/systemd/system/zadostno-update.service > /dev/null <<EOF
[Unit]
Description=Git pull for zadostno repository
After=network.target

[Service]
Type=oneshot
WorkingDirectory=$REPO_DIR
ExecStart=/usr/bin/git -C $REPO_DIR pull origin main
User=$TARGET_USER
Environment=HOME=$TARGET_USER_HOME
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 2. Create the timer file
sudo tee /etc/systemd/system/zadostno-update.timer > /dev/null <<EOF
[Unit]
Description=Run git pull every minute for zadostno
Requires=zadostno-update.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=zadostno-update.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable zadostno-update.timer
sudo systemctl start zadostno-update.timer

sudo systemctl status zadostno-update.timer || true
