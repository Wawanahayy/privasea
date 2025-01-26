#!/bin/bash

wget -qO- https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

sudo apt update && sudo apt upgrade -y

echo -e "${INFO}${INFO_EMOJI} Checking Docker installation... ${NC}"
if ! command -v docker &> /dev/null
then
    echo -e "${ERROR}${ERROR_EMOJI} Docker not found, installing Docker... ${NC}"

    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt update

    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

    echo -e "${SUCCESS}${SUCCESS_EMOJI} Docker installed successfully! ${NC}"
else
    echo -e "${SUCCESS}${SUCCESS_EMOJI} Docker is already installed. ${NC}"
fi

echo -e "${INFO}${INFO_EMOJI} Cleaning up unnecessary packages... ${NC}"
sudo apt-get remove --purge -y docker.io
sudo apt-get autoremove -y
sudo apt-get clean
echo -e "${SUCCESS}${SUCCESS_EMOJI} Unnecessary packages removed. ${NC}"

echo -e "${INFO}${DOCKER_EMOJI} Pulling Docker image... ${NC}"
docker pull privasea/acceleration-node-beta:latest

echo -e "${INFO}${SETUP_EMOJI} Creating /privasea/config directory... ${NC}"
mkdir -p /privasea/config && cd /privasea

echo -e "${INFO}${INFO_EMOJI} Checking if keystore file already exists... ${NC}"
keystore_file="/privasea/config/wallet_keystore"

if [ -f "$keystore_file" ]; then
    echo -e "${SUCCESS}${SUCCESS_EMOJI} Keystore file found: ${keystore_file}. Using existing keystore. ${NC}"
else
    echo -e "${INFO}${INFO_EMOJI} Keystore file not found. Generating a new keystore... ${NC}"

    docker run -it -v "/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore


    cd /privasea/config
    keystore_file=$(ls | grep -E '^UTC--.*')

    if [ -z "$keystore_file" ]; then
        echo -e "${ERROR}${ERROR_EMOJI} Keystore file not found after generation. Something went wrong. ${NC}"
        exit 1
    fi

    echo -e "${CYAN}${KEY_EMOJI} Please enter a password for your keystore file: ${NC}"
    read -s -p "Keystore Password: " keystore_password
    echo 

    read -s -p "Confirm Password: " keystore_password_confirm
    echo # 

    if [ "$keystore_password" != "$keystore_password_confirm" ]; then
        echo -e "${ERROR}${ERROR_EMOJI} Passwords do not match! Exiting... ${NC}"
        exit 1
    fi

    mv "$keystore_file" ./wallet_keystore
    echo -e "${INFO}${INFO_EMOJI} Keystore renamed to 'wallet_keystore'. Verifying... ${NC}"
    ls /privasea/config
fi


echo -e "${CYAN}${SETUP_EMOJI} Ready to start the Privanetix (acceleration) node! ${NC}"
read -p "Press Enter to run the node... ${NC}"


echo -e "${INFO}${DOCKER_EMOJI} Starting the Privanetix node... ${NC}"
docker run -d -v "/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$keystore_password" --restart unless-stopped privasea/acceleration-node-beta:latest

echo -e "${SUCCESS}${SUCCESS_EMOJI} Node is now running. ${NC}"


LOGO_EMOJI="🏠"
SUCCESS_EMOJI="✅"
ERROR_EMOJI="❌"
INFO_EMOJI="ℹ️"
KEY_EMOJI="🔑"
DOCKER_EMOJI="💎"
SETUP_EMOJI="⌛"
WARNING_EMOJI="❗️"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
INFO="${YELLOW}INFO:${NC}"
SUCCESS="${GREEN}SUCCESS:${NC}"
ERROR="${RED}ERROR:${NC}"
