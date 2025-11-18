#!/bin/bash

OS_TYPE=$(grep -w "ID" /etc/os-release | cut -d "=" -f 2 | tr -d '"')

# Check if the OS is manjaro, if so, change it to arch
if [ "$OS_TYPE" = "manjaro" ] || [ "$OS_TYPE" = "manjaro-arm" ]; then
    OS_TYPE="arch"
fi

# Check if the OS is Endeavour OS, if so, change it to arch
if [ "$OS_TYPE" = "endeavouros" ]; then
    OS_TYPE="arch"
fi

# Check if the OS is Cachy OS, if so, change it to arch
if [ "$OS_TYPE" = "cachyos" ]; then
    OS_TYPE="arch"
fi

# Check if the OS is Asahi Linux, if so, change it to fedora
if [ "$OS_TYPE" = "fedora-asahi-remix" ]; then
    OS_TYPE="fedora"
fi

# Check if the OS is popOS, if so, change it to ubuntu
if [ "$OS_TYPE" = "pop" ]; then
    OS_TYPE="ubuntu"
fi

# Check if the OS is linuxmint, if so, change it to ubuntu
if [ "$OS_TYPE" = "linuxmint" ]; then
    OS_TYPE="ubuntu"
fi

#Check if the OS is zorin, if so, change it to ubuntu
if [ "$OS_TYPE" = "zorin" ]; then
    OS_TYPE="ubuntu"
fi

if [ "$OS_TYPE" = "arch" ] || [ "$OS_TYPE" = "archarm" ]; then
    OS_VERSION="rolling"
else
    OS_VERSION=$(grep -w "VERSION_ID" /etc/os-release | cut -d "=" -f 2 | tr -d '"')
fi

# Install xargs on Amazon Linux 2023 - lol
if [ "$OS_TYPE" = 'amzn' ]; then
    $SUDO_CMD dnf install -y findutils >/dev/null
fi

case "$OS_TYPE" in
arch | ubuntu | debian | raspbian | centos | fedora | rhel | ol | rocky | sles | opensuse-leap | opensuse-tumbleweed | almalinux | amzn | alpine) ;;
*)
    echo "This script only supports Debian, Redhat, Arch Linux, Alpine Linux, or SLES based operating systems for now."
    exit
    ;;
esac

USER=$(whoami);
SUDO_CMD="";

if [ "$USER" != "root" ] ; then
	echo "You are not logged in as root."
# 	echo "Do you want to continue and run script as "$USER" user using sudo? (Y/n)";
# 	read -r ANSWER;
# 	if [ "$ANSWER" == "n" ] || [ "$ANSWER" == "N" ]; then
# 		echo "Bye."
# 		exit;
# 	else
# 		SUDO_CMD="sudo ";
# 	fi;
fi;

echo -e "Check Docker Installation."
if ! [ -x "$(command -v docker)" ]; then
    echo " - Docker is not installed. Installing Docker. It may take a while."

    case "$OS_TYPE" in
    "almalinux")
        $SUDO_CMD dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
        $SUDO_CMD dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
        if ! [ -x "$(command -v docker)" ]; then
            echo " - Docker could not be installed automatically. Please visit https://docs.docker.com/engine/install/ and install Docker manually to continue."
            exit 1
        fi
        $SUDO_CMD systemctl start docker >/dev/null 2>&1
        $SUDO_CMD systemctl enable docker >/dev/null 2>&1
        ;;
    "alpine")
        $SUDO_CMD apk add docker docker-cli-compose >/dev/null 2>&1
        $SUDO_CMD rc-update add docker default >/dev/null 2>&1
        $SUDO_CMD service docker start >/dev/null 2>&1
        if ! [ -x "$(command -v docker)" ]; then
            echo " - Failed to install Docker with apk. Try to install it manually."
            echo "   Please visit https://wiki.alpinelinux.org/wiki/Docker for more information."
            exit 1
        fi
        ;;
    "arch")
        $SUDO_CMD pacman -Sy docker --noconfirm >/dev/null 2>&1
        $SUDO_CMD systemctl enable docker.service >/dev/null 2>&1
        if ! [ -x "$(command -v docker)" ]; then
            echo " - Failed to install Docker with pacman. Try to install it manually."
            echo "   Please visit https://wiki.archlinux.org/title/docker for more information."
            exit 1
        fi
        ;;
    "amzn")
        $SUDO_CMD dnf install docker -y >/dev/null 2>&1
        DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
        $SUDO_CMD mkdir -p $DOCKER_CONFIG/cli-plugins >/dev/null 2>&1

        $SUDO_CMD systemctl start docker >/dev/null 2>&1
        $SUDO_CMD systemctl enable docker >/dev/null 2>&1
        if ! [ -x "$(command -v docker)" ]; then
            echo " - Failed to install Docker with dnf. Try to install it manually."
            echo "   Please visit https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/ for more information."
            exit 1
        fi
        ;;
    "centos" | "fedora" | "rhel")
        if [ -x "$(command -v dnf5)" ]; then
            # dnf5 is available
            $SUDO_CMD dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/$OS_TYPE/docker-ce.repo --overwrite >/dev/null 2>&1
        else
            # dnf5 is not available, use dnf
            $SUDO_CMD dnf config-manager --add-repo=https://download.docker.com/linux/$OS_TYPE/docker-ce.repo >/dev/null 2>&1
        fi
        $SUDO_CMD dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
        if ! [ -x "$(command -v docker)" ]; then
            echo " - Docker could not be installed automatically. Please visit https://docs.docker.com/engine/install/ and install Docker manually to continue."
            exit 1
        fi
        $SUDO_CMD systemctl start docker >/dev/null 2>&1
        $SUDO_CMD systemctl enable docker >/dev/null 2>&1
        ;;
    "ubuntu" | "debian" | "raspbian")
        if ! [ -x "$(command -v docker)" ]; then

            echo " - Automated Docker installation failed. Trying manual installation."
            echo exit 101 > /tmp/p-rc; $SUDO_CMD mv /tmp/p-rc /usr/sbin/policy-rc.d
            $SUDO_CMD chmod +x /usr/sbin/policy-rc.d
            export DEBIAN_FRONTEND=noninteractive
            $SUDO_CMD apt-get update -y
            $SUDO_CMD apt-get install ca-certificates curl gnupg -y
            $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
            $SUDO_CMD curl -fsSL https://download.docker.com/linux/debian/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg

            . ./etc/os-release
            DOCKER_SOURCE=$(cat /etc/apt/sources.list.d/docker.list 2> /dev/null | grep stable | wc -l)

            if [ "$DOCKER_SOURCE" == "0" ]; then 
                # add docker source to the source list
                $SUDO_CMD echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian "$VERSION_CODENAME" stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
                $SUDO_CMD apt-get update -y
            fi

            $SUDO_CMD apt-get install --no-install-recommends docker-ce docker-ce-cli containerd.io -y

        fi
        $SUDO_CMD systemctl restart docker >/dev/null 2>&1
        $SUDO_CMD systemctl enable docker >/dev/null 2>&1

        echo "Debian installation complete."
        ;;
    *)
        echo " - Your OS is detected as $OS_TYPE which is not supported by this installer script for automatic Docker installation."
        echo "   Please visit https://docs.docker.com/engine/install/ and install Docker manually to continue."
        exit 1
        ;;
    esac
    echo " - Docker installed successfully."
else
    echo " - Docker is installed."
fi

echo "Starting deploy Safebox containers"

$SUDO_CMD docker run --rm -e RUN_FORCE=true -v /var/run/docker.sock:/var/run/docker.sock safebox/framework-scheduler:latest