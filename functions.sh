#!/bin/bash -i

# Initialize an associative array to track installation statuses
declare -A status

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 14)
white=$(tput setaf 7)
link=$(tput setaf 14)
reset=$(tput sgr0)
underline=$(tput smul)
no_underline=$(tput rmul)

apt_install () {
    if [ -n "${UPDATE_CHECKSUM}" ]; then
        return
    fi
    for pkg in $* ; do
        if [ "$(dpkg-query --show --showformat='${db:Status-Status}\n' $pkg)" != 'installed' ] ; then
            if sudo apt install -y $pkg ; then
                echo "$pkg ${green}Installed successfully ${reset}"
                status["$pkg"]="Success"
            else
                echo "$pkg ${red}Failed to install${reset}"
                status["$pkg"]="Failed"
            fi
        else
            echo "$pkg ${yellow}Already installed ${reset}"
            status["$pkg"]="Already Installed"
        fi
    done
}

snap_install () {
    if [ -n "${UPDATE_CHECKSUM}" ]; then
        return
    fi

    if ! command -v $1 > /dev/null; then
        if sudo snap install $1; then
            echo "$1 ${green}Installed successfully ${reset}"
            status["$1"]="Success"
        else
            echo "$1 ${red}Failed to install${reset}"
            status["$1"]="Failed"
        fi
    else
        echo "$1 ${yellow}Already installed ${reset}"
        status["$1"]="Already Installed"
    fi
}

sdk_install () {
    if [ -n "${UPDATE_CHECKSUM}" ]; then
        return
    fi

    if [ ! -d ~/.sdkman ] ; then
        echo "$1 ${red}SDK Man required${reset}"
        status["$1"]="Failed"
    else 
        . ~/.sdkman/bin/sdkman-init.sh
        if [ ! -d $SDKMAN_CANDIDATES_DIR/$1 ] ; then
            if sdk install $1; then
                echo "$1 ${green}Installed successfully ${reset}"
                status["$1"]="Success"
            else
                echo "$1 ${red}Failed to install ${reset}"
                status["$1"]="Failed"
            fi
        else
            echo "$1 ${yellow}Already installed ${reset}"
            status["$1"]="Already Installed"
        fi
    fi
}

jetbrains_toolbox_install () {
    # Tool box is updated in-place, we keep only one version of it
    TOOLBOX_VERSION=$1
    if [ -n "${UPDATE_CHECKSUM}" ]; then
        local CURRDIR=$(dirname $(readlink -f "$0"))
        wget -q https://download.jetbrains.com/toolbox/jetbrains-toolbox-$TOOLBOX_VERSION.tar.gz -O jetbrains-toolbox.tgz
        sha512sum jetbrains-toolbox.tgz > $CURRDIR/hash/jetbrains-sha512sums.txt
        return
    fi
    if [ ! -d ~/opt/jetbrains-toolbox ] ; then
        local CURRDIR=$(dirname $(readlink -f "$0"))
        mkdir -p ~/Downloads
        cd ~/Downloads
        wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-$TOOLBOX_VERSION.tar.gz -O jetbrains-toolbox.tgz

        if sha512sum -c $CURRDIR/hash/jetbrains-sha512sums.txt; then
            mkdir -p ~/opt \
            && tar -xzf ~/Downloads/jetbrains-toolbox.tgz -C ~/opt/ \
            && mv ~/opt/jetbrains-toolbox-$TOOLBOX_VERSION ~/opt/jetbrains-toolbox
            
            if [ $? -eq 0 ] ; then
                echo "Jetbrains Toolbox ${green}Installed successfully${reset}"
                status["jetbrains-toolbox"]="Success"
            else
                echo "Jetbrains Toolbox ${red}Failed${reset}"
                status["jetbrains-toolbox"]="Failed"
            fi
        else
            echo "Jetbrains Toolbox ${red}Hash mismatch${reset}"
            status["jetbrains-toolbox"]="Hash Mismatch"
        fi
        rm -rf ~/Downloads/jetbrains-toolbox.tgz
        cd $CURRDIR
    else
        echo "Jetbrains Toolbox ${yellow}Already installed${reset}"
        status["jetbrains-toolbox"]="Already Installed"
    fi
}

install_p4merge () {
    P4M_VERSION=$1

    if [ -n "${UPDATE_CHECKSUM}" ]; then
        local CURRDIR=$(dirname $(readlink -f "$0"))
        wget -q https://cdist2.perforce.com/perforce/${P4M_VERSION}/bin.linux26x86_64/p4v.tgz -O p4v.tgz
        sha512sum p4v.tgz > $CURRDIR/hash/p4v-sha512sums.txt
        return
    fi

    if [ ! -x ~/bin/p4merge ] ; then
        local CURRDIR=$(dirname $(readlink -f "$0"))
        wget https://cdist2.perforce.com/perforce/${P4M_VERSION}/bin.linux26x86_64/p4v.tgz -O p4v.tgz
        if sha512sum -c $CURRDIR/hash/p4v-sha512sums.txt ; then
            mkdir -p ~/opt/ \
            && tar xzf p4v.tgz -C ~/opt/ \
            && mkdir -p ~/bin/ \
            && ln -sf ~/opt/$(tar tzf p4v.tgz | head -1)/bin/p4merge ~/bin/ \
            && rm -rf p4v.tgz
            if [ $? -eq 0 ] ; then
                git config --global merge.tool p4merge
                git config --global mergetool.prompt false
                git config --global mergetool.p4merge.cmd 'p4merge $BASE $LOCAL $REMOTE $MERGED'
                git config --global mergetool.p4merge.keeptemporaries false
                git config --global mergetool.p4merge.trustexitcode false
                git config --global mergetool.keepbackup false
                git config --global diff.tool p4merge
                git config --global difftool.prompt false
                git config --global difftool.p4merge.cmd 'p4merge $LOCAL $REMOTE'
                git config --global difftool.p4merge.keeptemporaries false
                git config --global difftool.p4merge.trustexitcode false
                git config --global difftool.p4merge.keepbackup false
                echo "p4merge ${green}Installed successfully${reset}"
                status["p4merge"]="Success"
            else 
                echo "p4merge ${red}Failed${reset}"
                status["p4merge"]="Failed"
            fi
        else
            echo "p4merge ${red}Hash mismatch${reset}"
            status["p4merge"]="Hash Mismatch"
        fi
    else
        echo "p4merge ${yellow}Already installed ${reset}"
        status["p4merge"]="Already Installed"
    fi
}

google_install () {
    if [ -n "${UPDATE_CHECKSUM}" ]; then
        return
    fi

    if ! command -v google-chrome > /dev/null; then
        local CURRDIR=$(pwd)
        mkdir -p ~/Downloads
        cd ~/Downloads
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        if sudo apt install ./google-chrome-stable_current_amd64.deb; then
            echo "Google Chrome ${green}Installed successfully${reset}"
            status["google-chrome"]="Success"
        else
            echo "Google Chrome ${red}Failed to install${reset}"
            #sudo apt --fix-broken install -y
            status["google-chrome"]="Failed"
        fi
        rm -rf google-chrome-stable_current_amd64.deb
        cd $CURRDIR
    else
        echo "Google Chrome ${yellow}Already installed${reset}"
        status["google-chrome"]="Already Installed"
    fi
}

install_remote_sh () {
    PROGRAM_NAME=$1
    EXPECTED_FOLDER=$2
    DOWNLOAD_URL=$3
    COMMAND_PREFIX=$4

    if [ -n "${UPDATE_CHECKSUM}" ]; then
        local CURRDIR=$(dirname $(readlink -f "$BASH_SOURCE"))
        wget -q "$DOWNLOAD_URL" -O ${PROGRAM_NAME}-install.sh
        sha512sum ${PROGRAM_NAME}-install.sh > $CURRDIR/hash/$PROGRAM_NAME-sha512sums.txt
        return
    fi

    if [ ! -e $EXPECTED_FOLDER ]; then
        local CURRDIR=$(dirname $(readlink -f "$BASH_SOURCE"))
        mkdir -p ~/Downloads
        cd ~/Downloads
        wget "$DOWNLOAD_URL" -O ${PROGRAM_NAME}-install.sh
        if sha512sum -c $CURRDIR/hash/$PROGRAM_NAME-sha512sums.txt; then
            $COMMAND_PREFIX bash ${PROGRAM_NAME}-install.sh --unattended
            echo "$PROGRAM_NAME ${green}Installed successfully${reset}"
            status["$PROGRAM_NAME"]="Success"
        else 
            echo "$PROGRAM_NAME ${red}Hash mismatch${reset}"
            status["$PROGRAM_NAME"]="Hash Mismatch"
        fi
        rm -rf ${PROGRAM_NAME}-install.sh
        cd $CURRDIR
    else
        echo "$PROGRAM_NAME ${yellow}Already installed${reset}"
        status["$PROGRAM_NAME"]="Already Installed"
    fi
}

install_gh_apt () {
    if [ -n "${UPDATE_CHECKSUM}" ]; then
        return
    fi
    if [ ! -f /usr/bin/gh ] ; then
        # See https://github.com/cli/cli/blob/trunk/docs/install_linux.md
        (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
            && sudo mkdir -p -m 755 /etc/apt/keyrings \
            && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && sudo apt update \
            && sudo apt install gh -y
        if [ $? -eq 0 ] ; then
            echo "GH CLI ${green}Installed successfully${reset}"
            status["gh"]="Success"
        else
            echo "gh ${red}Failed to install${reset}"
            status["gh"]="Failed"
        fi
    else
        echo "gh ${yellow}Already installed ${reset}"
        status["gh"]="Already Installed"
    fi
}

display_summary () {
    echo
    echo "${cyan}###########################################${reset}"
    echo "${white}           Installation Summary            ${reset}"
    echo "${cyan}###########################################${reset}"
    for program in "${!status[@]}"; do
        case ${status[$program]} in
            "Success")
                printf "%-20s: ${green}Success${reset}\n" "$program"
                ;;
            "Failed")
                printf "%-20s: ${red}Failed${reset}\n" "$program"
                ;;
            "Already Installed")
                printf "%-20s: ${yellow}Already Installed${reset}\n" "$program"
                ;;
            "Hash Mismatch")
                printf "%-20s: ${red}Hash Mismatch${reset} Program might have been updated\n" "$program"
                ;;
            *)
                printf "%-20s: ${status[$program]}\n" "$program"
                ;;
        esac
    done

    sudo chsh -s $(which zsh) $USER
    echo "${cyan}###########################################${reset}"
    echo
    tput smam # activate line breaks again
    echo "To run docker without sudo, run"
    echo "    newgrp docker"
}
