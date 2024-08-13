#!/bin/bash

ask_envs() {
	echo "VPN proxy? (Y/n)";
	read -r ANSWER;
	if [ "$ANSWER" == "n" ] || [ "$ANSWER" == "N" ]; then
		VPN_PROXY="no";
	else
		VPN_PROXY="yes";


			if [ "$VPN_PASS" != "" ]; then
				dateFromServer=$(curl -v --silent https://demo.format.hu/ 2>&1 | grep -i '< date' | sed -e 's/< date: //gi')
				VPN_DATE=$(date +"%Y%m%d" -d "$dateFromServer");
				VPN_HASH=$(echo -n $(( $VPN_PASS * $VPN_DATE )) | sha256sum | cut -d " " -f1);
				VPN_URL="$VPN_DOMAIN/$VPN_HASH/secret";
				echo "DEBUG: $VPN_DATE";
				echo "DEBUG: $VPN_URL";
				HTTP_CODE=$(curl -s -I -w "%{http_code}" $VPN_URL -o /dev/null);
				break;
			fi;

			echo "DEBUG: $HTTP_CODE";
			if [ "$HTTP_CODE" == "200" ]; then
				# download VPN key
				VPN_KEY=$(curl -s $VPN_URL);
				echo $VPN_KEY;

				$SUDO_CMD mkdir -p /etc/user/secret/vpn-proxy;
				echo $VPN_KEY | base64 -d > /tmp/wg0.conf;
				$SUDO_CMD mv /tmp/wg0.conf /etc/user/secret/vpn-proxy/;
				break;
			else
				echo "Download of VPN KEY was unsuccessful from URL: $VPN_URL";

				echo "Do you want to retry? (Y/n)";
				read -r VPN_RETRY;
				if [ "$VPN_RETRY" == "n" ] || [ "$VPN_RETRY" == "N" ]; then
					VPN_PROXY="no";
					echo "VPN proxy was skipped.";
					break;
				fi
			fi;

		if [ "$VPN_PROXY" == "yes" ]; then
			if [ "$LETSENCRYPT_SERVERNAME" = "" ]; then
				LETSENCRYPT_SERVERNAME="letsencrypt";
			fi;
		fi;
	fi
}

discover_services() {
	if [ "$DISCOVERY" == "yes" ]; then
		if [ "$DISCOVERY_CONFIG_FILE" == "discovery.conf" ] ; then
			DISCOVERY_CONFIG_FILE=$PWD"/discovery.conf";
			if [ ! -f $DISCOVERY_CONFIG_FILE ]; then
				USE_SUDO=$(whoami);
				if [ "$USE_SUDO" == "root" ]; then
					USE_SUDO=0;
				else
					USE_SUDO=1;
				fi

				{
					echo '#!/bin/bash';
					echo 'SOURCE_DIRS="/etc/user/data/ /etc/user/config/"; # separator space or |';
					echo 'DIRNAME="services misc"; # separator space or |';
					echo 'FILENAME="service healthcheck"; # separator space or |';
					echo 'KEYS="START_ON_BOOT"; # separator space or |';
					echo 'DEST_FILE="results.txt";';
					echo 'USE_SUDO='$USE_SUDO';';

				} >> $DISCOVERY_CONFIG_FILE;
			fi
		fi
		DISCOVERY_CONFIG_DIR=$(dirname $DISCOVERY_CONFIG_FILE)
		if [ "$DISCOVERY_CONFIG_DIR" == "/root" ]; then
			DISCOVERY_CONFIG_DIR="";
		fi
		 	
	fi
}

check_dirs_and_files() { # TODO?

	if [ ! -f "$HOME/.ssh/installer" ]; then
		echo "No ssh key files found. Please paste base64 content of the installer private key: ";
		while read -r INSTALLER; do
			if [ "$INSTALLER" != "" ]; then
				break;
			fi;
		done
		echo $INSTALLER > $HOME/.ssh/installer;
	fi;
	chmod 0600 $HOME/.ssh/installer;

	if [ ! -d "/etc/user/config" ]; then
		$SUDO_CMD mkdir -p "/etc/user/config"
	fi;
	if [ ! -d "/etc/system" ]; then
		$SUDO_CMD mkdir "/etc/system"
	fi;
	if [ ! -d "/etc/user/secret" ]; then
		$SUDO_CMD mkdir -p "/etc/user/secret"
	fi;

	if [ ! -f "/etc/user/config/system.json" ]; then
		{
			echo '
{
	"NETWORK": {
		"IP_POOL_START": "172.19.0.0",
		"IP_POOL_END": "172.19.254.0",
		"IP_SUBNET": "24"
	}
}
';
		} > /tmp/system.json

		$SUDO_CMD mv /tmp/system.json /etc/user/config/system.json
	fi;

	{
		echo "alias service-debian='$SUDO_CMD docker run --rm \
 -w /services/ \
 -e DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL \
 -e USER_INIT_PATH=/etc/user/config \
 -e CA_PATH=/etc/ssl/certs \
 -e DNS_DIR=/etc/system/data/dns \
 -e HOST_FILE=/etc/dns/hosts.local \
 -v /etc/system/data/dns:/etc/dns:rw \
 -v /etc/ssl/certs:/etc/ssl/certs:ro \
 -v /etc/user/config/user.json:/etc/user/config/user.json:ro \
 -v /etc/user/config/system.json:/etc/user/config/system.json:ro \
 -v /etc/user/config/services/:/services/:ro \
 -v /etc/user/config/services/tmp:/services/tmp:rw \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v /usr/bin/docker:/usr/bin/docker:ro \
 $DOCKER_REGISTRY_URL/setup'";
	} > $HOME/.bash_aliases

}

check_running() {

	DOCKERD_STATUS="0";

	### From Redis
	# bridge check
	BRIDGE_NUM=$($SUDO_CMD docker network ls | grep bridge | awk '{print $2":"$3}' | sort | uniq | wc -l);

	CONTAINER_NUM=$($SUDO_CMD docker ps -a | wc -l);

	if [ "$BRIDGE_NUM" != "1" ] && [ "$CONTAINER_NUM" != "1" ]; then

		echo "There are existing containers and/or networks.";
		echo "Please select from the following options (1/2/3):";

		echo "1 - Delete all existing containers and networks before installation";
		echo "2 - Stop the installation process";
		echo "3 - Just continue on my own risk";
		
		read -r ANSWER;

		if [ "$ANSWER" == "1" ]; then
			echo "1 - Removing exising containers and networks";
			# delete and continue
			$SUDO_CMD docker stop $($SUDO_CMD docker ps |grep Up | awk '{print $1}')
			$SUDO_CMD docker system prune -a

		elif [ "$ANSWER" == "3" ]; then
			echo "3 - You have chosen to continue installation process."

		else # default: 2 - stop installastion
			echo "2 - Installation process was stopped";
			exit;
		fi;

	fi;
	# visszairni redis - ha redisbol minden 1, akkor manager mode
}

#@@@@@@
# START
#@@@@@@

JSON="$(echo $1 | base64 -d)"

# Loop through each key in the JSON and create a variable
for key in $(echo "$JSON" | jq -r 'keys[]'); do
  value=$(echo "$JSON" | jq -r --arg k "$key" '.[$k]')
  declare "$key=$value"
done


SUDO_CMD="";

# first install
if [ ! -f "/etc/user/config/system.json" ]; then

	INIT="true";

	check_running;

	check_dirs_and_files;

	discover_services;

	# base variables

	if [ "$DOCKER_REGISTRY_URL" != "" ]; then
		VAR_DOCKER_REGISTRY_URL="--env DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL";
	fi

	if [ "$SMARTHOST_PROXY" != "" ]; then
		VAR_SMARTHOST_PROXY="--env SMARTHOST_PROXY=$SMARTHOST_PROXY";
	fi

	if [ "$LOCAL_PROXY" != "" ]; then
		VAR_LOCAL_PROXY="--env LOCAL_PROXY=$LOCAL_PROXY";
	fi

	if [ "$VPN_PROXY" != "" ]; then
		VAR_VPN_PROXY="--env VPN_PROXY=$VPN_PROXY";
	fi

	if [ "$DOMAIN" != "" ]; then
		VAR_DOMAIN="--env DOMAIN=$DOMAIN";
	fi

	if [ "$CRON" != "" ]; then
		VAR_CRON="--env CRON=$CRON";
	fi

	# discovery

	if [ "$DISCOVERY" != "" ]; then
		VAR_DISCOVERY="--env DISCOVERY=$DISCOVERY";
	fi

	if [ "$DISCOVERY_DIR" != "" ]; then
		VAR_DISCOVERY_DIR="--env DISCOVERY_DIR=$DISCOVERY_DIR";
		VAR_DISCOVERY_DIRECTORY="--volume $DISCOVERY_DIR/:$DISCOVERY_DIR/";
	fi

	if [ "$DISCOVERY_CONFIG_FILE" != "" ]; then
		VAR_DISCOVERY_CONFIG_FILE="--env DISCOVERY_CONFIG_FILE=$DISCOVERY_CONFIG_FILE";
		if [ "$DISCOVERY_CONFIG_DIR" != "" ]; then
			VAR_DISCOVERY_CONFIG_DIRECTORY="--volume $DISCOVERY_CONFIG_DIR/:$DISCOVERY_CONFIG_DIR/";
		fi
	fi

	# Run installer tool

	$SUDO_CMD docker run \
	$VAR_DOCKER_REGISTRY_URL \
	$VAR_SMARTHOST_PROXY \
	$VAR_LOCAL_PROXY \
	$VAR_VPN_PROXY \
	$VAR_DOMAIN \
	$VAR_CRON \
	$VAR_DISCOVERY \
	$VAR_DISCOVERY_DIR \
	$VAR_DISCOVERY_DIRECTORY \
	$VAR_DISCOVERY_CONFIG_FILE \
	$VAR_DISCOVERY_CONFIG_DIRECTORY \
	--volume $HOME/.ssh/installer:/root/.ssh/id_rsa \
	--volume /etc/user/:/etc/user/ \
	--volume /etc/system/:/etc/system/ \
	--env LETSENCRYPT_MAIL=$LETSENCRYPT_MAIL \
	--env LETSENCRYPT_SERVERNAME=$LETSENCRYPT_SERVERNAME \
	$DOCKER_REGISTRY_URL/installer-tool
else

	$SUDO_CMD docker pull $DOCKER_REGISTRY_URL/installer-tool
	$SUDO_CMD docker pull $DOCKER_REGISTRY_URL/setup

fi;

	# test - alias doesn't work inside a function
	# must be outside of if
	shopt -s expand_aliases
	source $HOME/.bash_aliases

if [ "$INIT" == "true" ]; then

	INIT_SERVICE_PATH=/etc/user/config/services

	type -a service-debian

	service-debian core-dns start
	echo "$INIT_SERVICE_PATH/core-dns.json" >> $PWD/.init_services

	if [ "$CRON" == "yes" ]; then
		service-debian cron start
		echo "$INIT_SERVICE_PATH/cron.json" >> $PWD/.init_services
	fi

	if [ "$VPN_PROXY" == "yes" ]; then
		service-debian vpn-proxy start
		echo "$INIT_SERVICE_PATH/vpn-proxy.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-vpn-smarthost-loadbalancer" >> $PWD/.init_services 
		echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-postrouting" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-prerouting" >> $PWD/.init_services

	fi

	if [ "$SMARTHOST_PROXY" == "yes" ]; then
		service-debian smarthost-proxy start
		service-debian smarthost-proxy-scheduler start
		service-debian local-proxy start

		echo "$INIT_SERVICE_PATH/smarthost-proxy.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-smarthost-loadbalancer-dns.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-letsencrypt.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-smarthostloadbalancer-from-publicbackend.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-smarthost-backend-dns.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/firewall-smarthost-to-backend.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/smarthost-proxy-scheduler.json" >> $PWD/.init_services
		echo "$INIT_SERVICE_PATH/local-proxy.json" >> $PWD/.init_services
		
		echo "Would you like to run local backend? (Y/n)";
		read -r ANSWER;
		if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
			service-debian local-backend start
			echo "$INIT_SERVICE_PATH/local-backend.json" >> $PWD/.init_services
			echo "$INIT_SERVICE_PATH/firewall-local-backend.json" >> $PWD/.init_services
			echo "$INIT_SERVICE_PATH/domain-local-backend.json" >> $PWD/.init_services
		fi
	fi

fi;

# install additionals - run installer-tool again but additional_install.sh instead of deploy.sh
if [ "$ADDITIONALS" == "yes" ]; then

	ADDITIONAL_SERVICES="";

	if [ "$NEXTCLOUD" == "yes" ]; then
		VAR_NEXTCLOUD="--env NEXTCLOUD=$NEXTCLOUD";
		VAR_NEXTCLOUD="$VAR_NEXTCLOUD --env NEXTCLOUD_DOMAIN=$NEXTCLOUD_DOMAIN";
		VAR_NEXTCLOUD="$VAR_NEXTCLOUD --env NEXTCLOUD_USERNAME=$NEXTCLOUD_USERNAME";
		VAR_NEXTCLOUD="$VAR_NEXTCLOUD --env NEXTCLOUD_PASSWORD=$NEXTCLOUD_PASSWORD";

		if [ ! -d "/etc/user/data/nextcloud" ]; then
			for DIR in data apps config ; do
				$SUDO_CMD mkdir -p "/etc/user/data/nextcloud/$DIR"
				$SUDO_CMD chown -R 82:82 "/etc/user/data/nextcloud/$DIR"
			done
		fi;
	
		echo "Would you like to run Nextcloud after install? (Y/n)";
		read -r ANSWER;
		if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
			ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES nextcloud";
		fi
	fi
	
	if [ "$BITWARDEN" == "yes" ]; then
		VAR_BITWARDEN="--env BITWARDEN=$BITWARDEN";
		VAR_BITWARDEN="$VAR_BITWARDEN --env BITWARDEN_DOMAIN=$BITWARDEN_DOMAIN";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_SERVER=$SMTP_SERVER";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_HOST=$SMTP_HOST";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_PORT=$SMTP_PORT";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_SECURITY=$SMTP_SECURITY";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_FROM=$SMTP_FROM";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_USERNAME=$SMTP_USERNAME";
		VAR_BITWARDEN="$VAR_BITWARDEN --env SMTP_PASSWORD=$SMTP_PASSWORD";
		VAR_BITWARDEN="$VAR_BITWARDEN --env DOMAINS_WHITELIST=$DOMAINS_WHITELIST";
		
		echo "                                                                                      ";
		echo "######################################################################################";
		echo "# You can access your bitwarden admin page here: https://$BITWARDEN_DOMAIN/admin #";
		echo "# You will find ADMIN TOKEN in this file: /etc/user/secret/bitwarden.json            #";
		echo "######################################################################################";
		echo "                                                                                      ";
		echo "Would you like to run Bitwarden after install? (Y/n)";
		
		read -r ANSWER;
		if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
			ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES bitwarden";
		fi
	fi

	if [ "$GUACAMOLE" == "yes" ]; then
		VAR_GUACAMOLE="--env GUACAMOLE=$GUACAMOLE";
		VAR_GUACAMOLE="$VAR_GUACAMOLE --env GUACAMOLE_DOMAIN=$GUACAMOLE_DOMAIN";
		VAR_GUACAMOLE="$VAR_GUACAMOLE --env GUACAMOLE_ADMIN_NAME=$GUACAMOLE_ADMIN_NAME";
		VAR_GUACAMOLE="$VAR_GUACAMOLE --env GUACAMOLE_ADMIN_PASSWORD=$GUACAMOLE_ADMIN_PASSWORD";
		VAR_GUACAMOLE="$VAR_GUACAMOLE --env TOTP_USE=$TOTP_USE";
		VAR_GUACAMOLE="$VAR_GUACAMOLE --env BAN_DURATION=$BAN_DURATION";

		echo "Would you like to run Guacamole after install? (Y/n)";
		read -r ANSWER;
		if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
			ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES guacamole";
		fi
	fi
	
	if [ "$SMTP" == "yes" ]; then
		VAR_SMTP="--env SMTP=$SMTP";

		echo "Would you like to run SMTP after install? (Y/n)";
		read -r ANSWER;
		if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
			ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES smtp";
		fi
	fi

	if [ "$ROUNDCUBE" == "yes" ]; then
		VAR_ROUNDCUBE="--env ROUNDCUBE=$ROUNDCUBE";
		VAR_ROUNDCUBE="$VAR_ROUNDCUBE --env ROUNDCUBE_IMAP_HOST=$ROUNDCUBE_IMAP_HOST";
		VAR_ROUNDCUBE="$VAR_ROUNDCUBE --env ROUNDCUBE_IMAP_PORT=$ROUNDCUBE_IMAP_PORT";
		VAR_ROUNDCUBE="$VAR_ROUNDCUBE --env ROUNDCUBE_SMTP_HOST=$ROUNDCUBE_SMTP_HOST";
		VAR_ROUNDCUBE="$VAR_ROUNDCUBE --env ROUNDCUBE_SMTP_PORT=$ROUNDCUBE_SMTP_PORT";
		VAR_ROUNDCUBE="$VAR_ROUNDCUBE --env ROUNDCUBE_UPLOAD_MAX_FILESIZE=$ROUNDCUBE_UPLOAD_MAX_FILESIZE";
		VAR_ROUNDCUBE="$VAR_ROUNDCUBE --env ROUNDCUBE_DOMAIN=$ROUNDCUBE_DOMAIN";

		echo "Would you like to run roundcube after install? (Y/n)";
		read -r ANSWER;
		if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
			ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES roundcube";
		fi
	fi

	# Run installer tool
	$SUDO_CMD docker run \
	--env ADDITIONALS=true \
	--env SERVICE_DIR=$SERVICE_DIR\
	$VAR_NEXTCLOUD \
	$VAR_BITWARDEN \
	$VAR_GUACAMOLE \
	$VAR_SMTP \
	$VAR_ROUNDCUBE \
	--volume $HOME/.ssh/installer:/root/.ssh/id_rsa \
	--volume /etc/user/:/etc/user/ \
	--volume /etc/system/:/etc/system/ \
	$DOCKER_REGISTRY_URL/installer-tool
fi

shopt -s expand_aliases
source $HOME/.bash_aliases

if [ "$ADDITIONAL_SERVICES" != "" ]; then 
	for ADDITIONAL_SERVICE in $(echo $ADDITIONAL_SERVICES); do
		service-debian $ADDITIONAL_SERVICE start
		echo "$INIT_SERVICE_PATH/$ADDITIONAL_SERVICE.json" >> $PWD/.init_services
	done
fi

if [ "$DISCOVERY" != "yes" ] ; then
	discover_services;
fi;

if [ "$DISCOVERY" == "yes" ] ; then
	$SUDO_CMD chmod a+x $DISCOVERY_DIR/service-discovery.sh
	$DISCOVERY_DIR/service-discovery.sh $DISCOVERY_CONFIG_FILE;
	source $DISCOVERY_CONFIG_FILE;
	cat $DEST_FILE;

	echo "Would you like to run discovered services? (Y/n)";
	read -r ANSWER;
	if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then
		$SUDO_CMD chmod a+x $DISCOVERY_DIR/service-files.sh
		$DISCOVERY_DIR/service-files.sh $DEST_FILE &
	fi;
fi;

if [ "$DEBIAN" == "true" ] || [ "$GENTOO" == "true" ] ; then

	echo "Do you want to start the discovered and actually started services at the next time when your system restarting? (Y/n)";
	read -r ANSWER;
	if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ] ; then

		cp $DISCOVERY_CONFIG_FILE $DISCOVERY_CONFIG_FILE".copy";
		cp $DEST_FILE $DEST_FILE".copy";

		DISCOVERY_CONFIG_FILENAME=$(basename $DISCOVERY_CONFIG_FILE);
		source $DISCOVERY_CONFIG_FILE;
		{
			echo '#!/bin/bash';
			echo 'SOURCE_DIRS="'$SOURCE_DIRS'"; # separator space or |';
			echo 'DIRNAME="'$DIRNAME'"; # separator space or |';
			echo 'FILENAME="'$FILENAME'"; # separator space or |';
			echo 'KEYS="'$KEYS'"; # separator space or |';
			echo 'DEST_FILE="/usr/local/etc/results.txt";';
			echo 'USE_SUDO=0;';
		} > /tmp/$DISCOVERY_CONFIG_FILENAME

		$SUDO_CMD mkdir -p /usr/local/etc;

		$SUDO_CMD mv /tmp/$DISCOVERY_CONFIG_FILENAME /usr/local/etc/$DISCOVERY_CONFIG_FILENAME

		{
			cat $PWD/.init_services;
			cat $DEST_FILE;
		} > /tmp/$DEST_FILE

		$SUDO_CMD mv /tmp/$DEST_FILE /usr/local/etc/$DEST_FILE


		if [ "$DEBIAN" == "true" ] ; then
			{
				echo "
[Unit]
Description=Discover services

[Service]
Type=oneshot
ExecStart=/usr/local/bin/service-files.sh /usr/local/etc/results.txt restart

[Install]
WantedBy=multi-user.target
";

			} > /tmp/discovery.service
			$SUDO_CMD mv /tmp/discovery.service /etc/systemd/system/discovery.service
			$SUDO_CMD systemctl enable discovery.service

		elif [ "$GENTOO" == "true" ] ; then
			$SUDO_CMD echo "/usr/local/bin/service-files.sh /usr/local/etc/results.txt restart" > /etc/local.d/service-file.start;
			$SUDO_CMD chmod a+x /etc/local.d/service-file.start;
		fi;
	fi;
fi;

rm $PWD/.init_services

