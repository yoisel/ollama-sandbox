#!/bin/bash

# Podman Setup Script for Ubuntu/Debian systems
# This script installs Podman with Docker compatibility, podman-compose, and enables the Podman socket.

# Detect if run with sudo and set user variables
if [ "$EUID" -eq 0 ]; then
    if [ -n "$SUDO_USER" ]; then
        ACTUAL_USER=$SUDO_USER
        USER_CMD="sudo -u $ACTUAL_USER"
        USER_HOME=$(eval echo ~$ACTUAL_USER)
    else
        ACTUAL_USER=root
        USER_CMD=""
        USER_HOME=$HOME
    fi
else
    ACTUAL_USER=$USER
    USER_CMD=""
    USER_HOME=$HOME
fi

# Update package list
echo "Updating package list..."
sudo apt update

# Install Podman and Docker compatibility package
echo "Installing Podman and podman-docker..."
sudo apt install -y podman podman-docker

# Install docker-compose
echo "Installing docker-compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Enable and start the Podman socket (system-wide)
echo "Enabling and starting Podman socket..."
sudo systemctl enable --now podman.socket

# Enable and start the user-level Podman socket for rootless operation
echo "Enabling and starting user-level Podman socket for $ACTUAL_USER..."

# Kill any existing podman system service for this user
$USER_CMD pkill -f "podman system service" 2>/dev/null || true
sleep 1

# Start podman system service as the actual user (not root)
echo "Starting Podman API service..."
$USER_CMD podman system service --time 0 > /tmp/podman-$ACTUAL_USER.log 2>&1 &
SERVICE_PID=$!
echo "Service PID: $SERVICE_PID"

# Wait for socket to be created
echo "Waiting for socket to be ready..."
max_attempts=20
for i in $(seq 1 $max_attempts); do
    if $USER_CMD [ -S /run/user/$($USER_CMD id -u)/podman/podman.sock ]; then
        echo "✓ Podman socket created successfully"
        break
    fi
    sleep 0.5
done

# Create docker.sock symlink for docker-compose compatibility
USER_UID=$($USER_CMD id -u)
PODMAN_SOCKET="/run/user/$USER_UID/podman/podman.sock"
DOCKER_SOCKET="/run/user/$USER_UID/docker.sock"

rm -f "$DOCKER_SOCKET" 2>/dev/null || true
ln -sf "$PODMAN_SOCKET" "$DOCKER_SOCKET"
echo "✓ Docker socket symlink created at $DOCKER_SOCKET"

# Add DOCKER_HOST to ~/.bashrc for persistence
echo "Adding DOCKER_HOST to ~/.bashrc..."
DOCKER_HOST_LINE='export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock'

# Only add if not already present
if ! grep -q "DOCKER_HOST" $USER_HOME/.bashrc; then
    echo "$DOCKER_HOST_LINE" >> $USER_HOME/.bashrc
    echo "✓ Added DOCKER_HOST to $USER_HOME/.bashrc"
else
    echo "✓ DOCKER_HOST already in $USER_HOME/.bashrc"
fi

echo ""
echo "============================================"
echo "✓ Podman setup complete!"
echo "============================================"
echo ""

# Start containers in detached mode
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    echo "Starting docker-compose containers in detached mode..."
    cd "$SCRIPT_DIR"
    
    # Export DOCKER_HOST for the current session
    export DOCKER_HOST="unix:///run/user/$USER_UID/docker.sock"
    
    # Run docker-compose as the actual user
    $USER_CMD bash -c "cd '$SCRIPT_DIR' && export DOCKER_HOST='unix:///run/user/$($USER_CMD id -u)/docker.sock' && docker-compose up -d"
    
    if [ $? -eq 0 ]; then
        echo "✓ Containers started successfully"
        echo ""
        echo "Useful commands:"
        echo "  docker-compose logs -f                 # View live logs"
        echo "  docker-compose ps                      # Check container status"
        echo "  docker-compose down                    # Stop containers"
        echo "  docker-compose down -v                 # Stop and remove volumes"
    else
        echo "⚠ Failed to start containers. Run manually with:"
        echo "  export DOCKER_HOST='unix:///run/user/\$(id -u)/docker.sock'"
        echo "  cd $SCRIPT_DIR && docker-compose up -d"
    fi
else
    echo "⚠ docker-compose.yml not found in $SCRIPT_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Reload your shell configuration:"
    echo "   source ~/.bashrc"
    echo ""
    echo "2. Test the setup:"
    echo "   docker ps"
    echo ""
    echo "3. Start containers:"
    echo "   export DOCKER_HOST='unix:///run/user/\$(id -u)/docker.sock'"
    echo "   docker-compose up -d"
fi