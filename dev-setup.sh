#!/bin/bash -i
CURR_DIR=$(dirname $(readlink -f "$0"))

source $CURR_DIR/functions.sh

if [ -z "${UPDATE_CHECKSUM}" ]; then
if [ -z $IN_DOCKER ]; then

cat << EOF | sudo tee /etc/sudoers.d/$USER
$USER ALL=(ALL) NOPASSWD:ALL

EOF
else
    export DEBIAN_FRONTEND="noninteractive"
    apt update
    apt install -y sudo wget apt-utils
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
fi
fi

if [ -z "${UPDATE_CHECKSUM}" ]; then

    # Git
    apt_install "git"
    if [ -z "$GIT_USER" -o -z "$GIT_EMAIL" ]; then
        echo "Specify GIT_USER and GIT_EMAIL"
    else
        git config --global user.name "${GIT_USER}"
        git config --global user.email "${GIT_EMAIL}"
    fi
fi

#Curl
apt_install "curl"

# Snap
apt_install "snap"

#Zip
apt_install "zip" "unzip"

#Docker buildx
apt_install "docker-buildx"

#Docker-clean
apt_install "docker-clean"

#Docker-compose-v2
apt_install "docker-compose-v2"

#Docker.io
apt_install "docker.io"

if [ -z "$IN_DOCKER" ] && [ -z "${UPDATE_CHECKSUM}" ]; then
sudo groupadd -f docker
sudo usermod -aG docker $USER
#newgrp docker
fi

# ssh client
apt_install "openssh-client"

# snap package system
apt_install "snapd"

# Jdk Versjon 11, 17, 21
apt_install openjdk-11-jdk openjdk-17-jdk openjdk-21-jdk

# direnv
apt_install "direnv"

# ssh server
#apt_install "openssh-server"

# zsh
apt_install "zsh"

# SDK man
install_remote_sh sdk ~/.sdkman https://get.sdkman.io

# OhMyzsh
install_remote_sh omz ~/.oh-my-zsh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/3151c9c1a330cdea66dd7d1a24810fe805298711/tools/install.sh

# libfuse2 necessary for jetbrains toolbox
apt_install "libfuse2"

# Jetbrains Toolbox
jetbrains_toolbox_install "2.8.1.52155"

# Chrome
google_install

# Maven
sdk_install "maven"

# Visual studio code + dependencies
snap_install "code --classic"

# Slack
snap_install "slack"

# Azure Client
install_remote_sh az-cli /usr/bin/az https://aka.ms/InstallAzureCLIDeb sudo

# Github CLI
install_gh_apt

# P4Merge
install_p4merge "r25.1"

# NVM
install_remote_sh nvm ~/.nvm https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh

if [ -z "${UPDATE_CHECKSUM}" ]; then

    # Enable and make ssh possible
    sudo systemctl enable ssh
    sudo ufw allow ssh

    # Display the installation summary
    display_summary

fi


