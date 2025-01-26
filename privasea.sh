#!/bin/bash

# Define color codes for echo
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
INFO="${YELLOW}INFO:${NC}"
SUCCESS="${GREEN}SUCCESS:${NC}"
ERROR="${RED}ERROR:${NC}"

# Emojis
LOGO_EMOJI="🎨"
SUCCESS_EMOJI="✅"
ERROR_EMOJI="❌"
INFO_EMOJI="ℹ️"
KEY_EMOJI="🔑"
DOCKER_EMOJI="🐳"
SETUP_EMOJI="⚙️"
WARNING_EMOJI="⚠️"

# Display logo directly from URL
echo -e "${CYAN}${LOGO_EMOJI} Displaying logo... ${NC}"
wget -qO- https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

# Check for updates and upgrade system
echo -e "${INFO}${INFO_EMOJI} Checking for updates and upgrading system... ${NC}"
sudo apt update && sudo apt upgrade -y

# Check Docker installation
echo -e "${INFO}${INFO_EMOJI} Checking Docker installation... ${NC}"
if ! command -v docker &> /dev/null
then
    echo -e "${ERROR}${ERROR_EMOJI} Docker not found, installing Docker... ${NC}"

    # Install necessary dependencies
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Add Docker's official repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Update APT package index
    sudo apt update

    # Install Docker
    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

    echo -e "${SUCCESS}${SUCCESS_EMOJI} Docker installed successfully! ${NC}"
else
    echo -e "${SUCCESS}${SUCCESS_EMOJI} Docker is already installed. ${NC}"
fi

# Clean up unnecessary packages
echo -e "${INFO}${INFO_EMOJI} Cleaning up unnecessary packages... ${NC}"
sudo apt-get remove --purge -y docker.io
sudo apt-get autoremove -y
sudo apt-get clean
echo -e "${SUCCESS}${SUCCESS_EMOJI} Unnecessary packages removed. ${NC}"

# Pull Docker image
echo -e "${INFO}${DOCKER_EMOJI} Pulling Docker image... ${NC}"
docker pull privasea/acceleration-node-beta:latest

# Create necessary directories
echo -e "${INFO}${SETUP_EMOJI} Creating /privasea/config directory... ${NC}"
mkdir -p /privasea/config && cd /privasea

# Check if keystore file exists
echo -e "${INFO}${INFO_EMOJI} Checking if keystore file already exists... ${NC}"
keystore_file="/privasea/config/wallet_keystore"

if [ -f "$keystore_file" ]; then
    echo -e "${SUCCESS}${SUCCESS_EMOJI} Keystore file found: ${keystore_file}. Using existing keystore. ${NC}"
else
    echo -e "${INFO}${INFO_EMOJI} Keystore file not found. Generating a new keystore... ${NC}"

    # Run Docker container to generate new keystore
    docker run -it -v "/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore

    # List files in /privasea/config to find the generated keystore file
    cd /privasea/config
    keystore_file=$(ls | grep -E '^UTC--.*')

    if [ -z "$keystore_file" ]; then
        echo -e "${ERROR}${ERROR_EMOJI} Keystore file not found after generation. Something went wrong. ${NC}"
        exit 1
    fi

    # Prompt the user to input a password for the keystore
    echo -e "${CYAN}${KEY_EMOJI} Please enter a password for your keystore file: ${NC}"
    read -s -p "Keystore Password: " keystore_password
    echo # New line for better readability

    # Confirm password
    read -s -p "Confirm Password: " keystore_password_confirm
    echo # New line for better readability

    # Check if passwords match
    if [ "$keystore_password" != "$keystore_password_confirm" ]; then
        echo -e "${ERROR}${ERROR_EMOJI} Passwords do not match! Exiting... ${NC}"
        exit 1
    fi

    # Rename the keystore file to wallet_keystore
    mv "$keystore_file" ./wallet_keystore
    echo -e "${INFO}${INFO_EMOJI} Keystore renamed to 'wallet_keystore'. Verifying... ${NC}"
    ls /privasea/config
fi

# Prompt to run the node
echo -e "${CYAN}${SETUP_EMOJI} Ready to start the Privanetix (acceleration) node! ${NC}"
read -p "Press Enter to run the node... ${NC}"

# Run the node with Docker and --restart unless-stopped
echo -e "${INFO}${DOCKER_EMOJI} Starting the Privanetix node... ${NC}"
docker run -d -v "/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$keystore_password" --restart unless-stopped privasea/acceleration-node-beta:latest

echo -e "${SUCCESS}${SUCCESS_EMOJI} Node is now running. ${NC}"
