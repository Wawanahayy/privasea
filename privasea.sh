#!/bin/bash


CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'
INFO="${YELLOW}INFO:${NC}"
SUCCESS="${GREEN}BERHASIL:${NC}"
ERROR="${RED}GAGAL:${NC}"

LOGO="LOGO"
BERHASIL="OK"
GAGAL="X"
INFO_ICON="INFO"
KUNCI="KUNCI"
DOCKER="DOCKER"
PENGATURAN="SETUP"
PERINGATAN="!"

echo -e "${CYAN}${LOGO} Menampilkan logo... ${NC}"
curl -s https://raw.githubusercontent.com/Wawanahayy/JawaPride-all.sh/refs/heads/main/display.sh | bash

echo -e "${INFO}${INFO_ICON} Memeriksa pembaruan dan meningkatkan sistem... ${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${INFO}${INFO_ICON} Memeriksa instalasi Docker... ${NC}"
if ! command -v docker &> /dev/null
then
    echo -e "${ERROR}${GAGAL} Docker tidak ditemukan, menginstal Docker... ${NC}"
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${SUCCESS}${BERHASIL} Docker berhasil diinstal! ${NC}"
else
    echo -e "${SUCCESS}${BERHASIL} Docker sudah terinstal. ${NC}"
fi

echo -e "${INFO}${INFO_ICON} Membersihkan paket yang tidak diperlukan... ${NC}"
sudo apt-get remove --purge -y docker.io
sudo apt-get autoremove -y
sudo apt-get clean
echo -e "${SUCCESS}${BERHASIL} Paket yang tidak diperlukan telah dihapus. ${NC}"

echo -e "${INFO}${DOCKER} Menarik gambar Docker... ${NC}"
docker pull privasea/acceleration-node-beta:latest

echo -e "${INFO}${PENGATURAN} Membuat direktori /privasea/config... ${NC}"
mkdir -p /privasea/config && cd /privasea

echo -e "${INFO}${INFO_ICON} Memeriksa apakah file keystore sudah ada... ${NC}"
keystore_file="/privasea/config/wallet_keystore"

if [ -f "$keystore_file" ]; then
    echo -e "${SUCCESS}${BERHASIL} File keystore ditemukan: ${keystore_file}. Menggunakan keystore yang ada. ${NC}"
else
    echo -e "${INFO}${INFO_ICON} File keystore tidak ditemukan. Membuat keystore baru... ${NC}"
    docker run -it -v "/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore
    cd /privasea/config
    keystore_file=$(ls | grep -E '^UTC--.*')

    if [ -z "$keystore_file" ]; then
        echo -e "${ERROR}${GAGAL} File keystore tidak ditemukan setelah dibuat. Ada yang salah. ${NC}"
        exit 1
    fi

    echo -e "${CYAN}${KUNCI} Masukkan kata sandi untuk file keystore Anda: ${NC}"
    read -s -p "Kata Sandi Keystore: " keystore_password
    echo
    read -s -p "Konfirmasi Kata Sandi: " keystore_password_confirm
    echo

    if [ "$keystore_password" != "$keystore_password_confirm" ]; then
        echo -e "${ERROR}${GAGAL} Kata sandi tidak cocok! Keluar... ${NC}"
        exit 1
    fi

    mv "$keystore_file" ./wallet_keystore
    echo -e "${INFO}${INFO_ICON} File keystore diubah nama menjadi 'wallet_keystore'. Memverifikasi... ${NC}"
    ls /privasea/config
fi

echo -e "${CYAN}${PENGATURAN} Siap menjalankan node Privanetix (akselerasi)! ${NC}"
read -p "Tekan Enter untuk menjalankan node... ${NC}"

echo -e "${INFO}${DOCKER} Menjalankan node Privanetix... ${NC}"
docker run -d -v "/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$keystore_password" --restart unless-stopped privasea/acceleration-node-beta:latest

echo -e "${SUCCESS}${BERHASIL} Node sedang berjalan. ${NC}"
