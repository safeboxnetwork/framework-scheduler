#!/bin/sh

SERVICE_EXEC=$2
FIRST_INSTALL=$3
GLOBAL_VERSION=$4

edit_user_json() {

    if [ ! -f /etc/user/config/user.json ]; then
        install -m 664 -g 65534 /dev/null /etc/user/config/user.json
        echo '{}' >/etc/user/config/user.json

    else
        if [ -z $(cat /etc/user/config/user.json) ]; then
            echo '{}' >/etc/user/config/user.json
        fi
    fi

    TMP_FILE=$(mktemp)
    jq '
      if . == null or . == [] then 
        {"letsencrypt": { "EMAIL": "'$LETSENCRYPT_MAIL'", "LETSENCRYPT_SERVER": "'$LETSENCRYPT_SERVERNAME'" }}
      else 
        . + {"letsencrypt": { "EMAIL": "'$LETSENCRYPT_MAIL'", "LETSENCRYPT_SERVER": "'$LETSENCRYPT_SERVERNAME'" }}
      end
    ' /etc/user/config/user.json >$TMP_FILE
    cat $TMP_FILE >/etc/user/config/user.json
    rm $TMP_FILE

}

get_vpn_key() {

    if [ "$VPN_PASS" != "" ]; then
        dateFromServer=$(curl -v --silent $VPN_DOMAIN 2>&1 | grep -i '< date' | sed -e 's/< date: //gi')
        VPN_DATE=$(date +"%Y%m%d" -d "$dateFromServer")
        VPN_HASH=$(echo -n $(($VPN_PASS * $VPN_DATE)) | sha256sum | cut -d " " -f1)
        VPN_URL="$VPN_DOMAIN/$VPN_HASH/secret"
        echo "DEBUG: $VPN_DATE"
        echo "DEBUG: $VPN_URL"
        HTTP_CODE=$(curl -s -I -w "%{http_code}" $VPN_URL -o /dev/null)

        echo "DEBUG: $HTTP_CODE"
        if [ "$HTTP_CODE" == "200" ]; then
            # download VPN key
            VPN_KEY=$(curl -s $VPN_URL)
            echo $VPN_KEY

            $SUDO_CMD mkdir -p /etc/user/secret/vpn-proxy
            echo $VPN_KEY | base64 -d >/tmp/wg0.conf
            $SUDO_CMD mv /tmp/wg0.conf /etc/user/secret/vpn-proxy/
        else
            echo "Download of VPN KEY was unsuccessful from URL: $VPN_URL"
            echo "VPN proxy was skipped."
            VPN_PROXY="no"
        fi
    else
        echo "$VPN_PASS is empty"
    fi
}

discover_services() {
    if [ "$DISCOVERY" == "yes" ]; then
        if [ "$DISCOVERY_CONFIG_FILE" == "discovery.conf" ]; then
            DISCOVERY_CONFIG_FILE=$AUTO_START_SERVICES"/discovery.conf"
            if [ ! -f $DISCOVERY_CONFIG_FILE ]; then
                USE_SUDO=$(whoami)
                if [ "$USE_SUDO" == "root" ]; then
                    USE_SUDO=0
                else
                    USE_SUDO=1
                fi

                {
                    echo '#!/bin/bash'
                    echo 'SOURCE_DIRS="/etc/user/data/ /etc/user/config/"; # separator space or |'
                    echo 'DIRNAME="services misc"; # separator space or |'
                    echo 'FILENAME="service healthcheck"; # separator space or |'
                    echo 'KEYS="START_ON_BOOT"; # separator space or |'
                    echo 'DEST_FILE="results.txt";'
                    echo 'USE_SUDO='$USE_SUDO';'

                } >>$DISCOVERY_CONFIG_FILE
            fi
        fi
        DISCOVERY_CONFIG_DIR=$(dirname $DISCOVERY_CONFIG_FILE)
        if [ "$DISCOVERY_CONFIG_DIR" == "/root" ]; then
            DISCOVERY_CONFIG_DIR=""
        fi

    fi
}

# ─── Inlined from deploy.sh ───────────────────────────────────────────────────

version_update() {
    for JSON in $(ls /etc/user/config/services/*.json); do
        TMP_FILE=$(mktemp -p /tmp/)
        jq --arg registry "$DOCKER_REGISTRY_URL" --arg version "$GLOBAL_VERSION" '
            walk(
                if type == "string" and startswith($registry) then
                    (split(":")[0]) + ":" + $version
                else
                    .
                end
            )
        ' "$JSON" > "$TMP_FILE"
        mv "$TMP_FILE" "$JSON"
    done
}

toUpperCase() {
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

install_local_backend() {
    sed -i "s/DOMAIN_NAME/$DOMAIN/g" /tmp/$LOCAL_BACKEND_REPO/*.json
    cp -rv /tmp/$LOCAL_BACKEND_REPO/*.json $SERVICE_DIR/
}

install_core_dns() {
    cp -rv /tmp/$CORE_DNS/*.json $SERVICE_DIR/

    DNS_VOLUMES=$(jq -r '.containers[].VOLUMES[].SOURCE' $SERVICE_DIR/$CORE_DNS.json | grep -v '\.')
    for VOLUME in $DNS_VOLUMES; do
        mkdir -p $VOLUME
    done

    DNS_VOLUMES=$(jq -r --arg DEST "/etc/dnsmasq" \
        '.containers[0].VOLUMES[] | select(.DEST | startswith($DEST))' \
        $SERVICE_DIR/$CORE_DNS.json)
    DNS_DIR=$(echo $DNS_VOLUMES | jq -r .SOURCE)
    mkdir -p $DNS_DIR
    cp -rv /tmp/$CORE_DNS/dns.conf $DNS_DIR/

    if [ "$SMARTHOST_PROXY" == "YES" ] || [ "$SMARTHOST_PROXY" == "TRUE" ]; then
        EXISTS=$(grep -E 'smarthostloadbalancer|smarthostbackend' $DNS_DIR/hosts.local 2>/dev/null)
        if [ -z "$EXISTS" ]; then
            echo '172.18.254.254 letsencrypt
172.18.103.2 smarthostloadbalancer
172.18.104.2 smarthostbackend-1
172.18.105.2 smarthostbackend-2' >>$DNS_DIR/hosts.local
        fi
    fi
}

install_additionals_core() {

    install_core_dns

    if [ "$LOCAL_PROXY" == "YES" ] || [ "$LOCAL_PROXY" == "TRUE" ]; then
        cp -av /tmp/$LOCAL_PROXY_REPO/*.json $SERVICE_DIR/
        if [ "$LOCAL_BACKEND" == "YES" ] || [ "$LOCAL_BACKEND" == "TRUE" ]; then
            install_local_backend
        fi
    fi

    if [ "$VPN_PROXY" == "YES" ] || [ "$VPN_PROXY" == "TRUE" ]; then
        cp -av /tmp/$VPN_PROXY_REPO/*.json $SERVICE_DIR/
        VPN_VOLUME=$(jq -r '.containers[0].VOLUMES[0].SOURCE' $SERVICE_DIR/vpn-proxy.json)
        mkdir -p $(dirname $VPN_VOLUME)
    fi

    if [ "$CRON" == "YES" ] || [ "$CRON" == "TRUE" ]; then
        cp -av /tmp/$CRON_REPO/*.json $SERVICE_DIR/
        CRON_VOLUMES=$(jq -r '.containers[].VOLUMES[].SOURCE' $SERVICE_DIR/cron.json | grep -v '\.')
        for VOLUME in $CRON_VOLUMES; do
            mkdir -p $VOLUME
        done
    fi

    if [ "$DISCOVERY" == "YES" ]; then
        cp -av /tmp/$SERVICE_EXEC_REPO/scripts/service-discovery.sh $DISCOVERY_DIR
        cp -av /tmp/$SERVICE_EXEC_REPO/scripts/service-files.sh $DISCOVERY_DIR
        if [ ! -f $DISCOVERY_CONFIG_FILE ]; then
            cp -av /tmp/$SERVICE_EXEC_REPO/scripts/discovery.conf $DISCOVERY_CONFIG_FILE
        fi
    fi
}

deploy_core() {
    SMARTHOST_PROXY=$(toUpperCase $SMARTHOST_PROXY)
    LOCAL_PROXY=$(toUpperCase $LOCAL_PROXY)
    LOCAL_BACKEND=$(toUpperCase $LOCAL_BACKEND)
    VPN_PROXY_UPPER=$(toUpperCase $VPN_PROXY)
    CRON=$(toUpperCase $CRON)
    DISCOVERY=$(toUpperCase $DISCOVERY)

    GIT_REPO=${GIT_REPO:-git.format.hu}
    ORGANIZATION=${ORGANIZATION:-safebox}
    USER_CONFIG_PATH=${USER_CONFIG_PATH:-/etc/user/config/user.json}
    CORE_DNS=${CORE_DNS:-core-dns}
    LOCAL_PROXY_REPO=${LOCAL_PROXY_REPO:-local-proxy}
    VPN_PROXY_REPO=${VPN_PROXY_REPO:-wireguard-proxy-client}
    CRON_REPO=${CRON_REPO:-cron}
    LOCAL_BACKEND_REPO=${LOCAL_BACKEND_REPO:-local-backend}
    SERVICE_EXEC_REPO=${SERVICE_EXEC_REPO:-service-exec-new}

    if [ "$SMARTHOST_PROXY" == "YES" ] || [ "$SMARTHOST_PROXY" == "TRUE" ]; then
        PROXY_TYPE="$PROXY_TYPE smarthost-proxy"
    fi

    git clone https://$GIT_REPO/$ORGANIZATION/$CORE_DNS.git /tmp/$CORE_DNS

    if [ "$LOCAL_PROXY" == "YES" ] || [ "$LOCAL_PROXY" == "TRUE" ]; then
        git clone https://$GIT_REPO/$ORGANIZATION/$LOCAL_PROXY_REPO.git /tmp/$LOCAL_PROXY_REPO
        git clone https://$GIT_REPO/$ORGANIZATION/$LOCAL_BACKEND_REPO.git /tmp/$LOCAL_BACKEND_REPO
    fi

    if [ "$VPN_PROXY_UPPER" == "YES" ] || [ "$VPN_PROXY_UPPER" == "TRUE" ]; then
        git clone https://$GIT_REPO/$ORGANIZATION/$VPN_PROXY_REPO.git /tmp/$VPN_PROXY_REPO
    fi

    if [ "$CRON" == "YES" ] || [ "$CRON" == "TRUE" ]; then
        git clone https://$GIT_REPO/$ORGANIZATION/$CRON_REPO.git /tmp/$CRON_REPO
    fi

    for i in $PROXY_TYPE; do
        git clone https://$GIT_REPO/$ORGANIZATION/$i.git /tmp/$i

        if [ "$i" == "public-proxy" ]; then
            PROXY_SCHEDULER_FILE=proxy-scheduler.json
        else
            PROXY_SCHEDULER_FILE=smarthost-proxy-scheduler.json
        fi

        PROXY_SCHEDULER_NAME=$(jq -r '.containers[0].NAME' /tmp/$i/$PROXY_SCHEDULER_FILE | cut -d "-" -f1)
        PROXY_SERVICE_FILE=$(jq -r ".$PROXY_SCHEDULER_NAME.PROXY_SERVICE_FILE" /tmp/$i/proxy_config)
        SERVICE_DIR=$(jq -r '.containers[0].VOLUMES[].SOURCE' /tmp/$i/$PROXY_SCHEDULER_FILE \
            | grep $PROXY_SERVICE_FILE | sed "s/$PROXY_SERVICE_FILE//g")

        PROXY_CONFIG_DIR=$(jq -r ".$PROXY_SCHEDULER_NAME.PROXY_CONFIG_DIR" /tmp/$i/proxy_config)
        if [ "$PROXY_CONFIG_DIR" == "null" ]; then
            echo "WARNING: $PROXY_SCHEDULER_NAME.PROXY_CONFIG_DIR not found in /tmp/$i/proxy_config"
        fi

        PROXY_VOLUME=$(jq -r --arg DEST "$PROXY_CONFIG_DIR" \
            '.containers[0].VOLUMES[] | select(.DEST==$DEST)' /tmp/$i/$PROXY_SCHEDULER_FILE)
        PROXY_DIR=$(echo $PROXY_VOLUME | jq -r .SOURCE)

        DOMAIN_CONFIG_DIR=$(jq -r ".$PROXY_SCHEDULER_NAME.DOMAIN_DIR" /tmp/$i/proxy_config)
        DOMAIN_VOLUME=$(jq -r --arg DEST "$DOMAIN_CONFIG_DIR" \
            '.containers[0].VOLUMES[] | select(.DEST==$DEST)' /tmp/$i/$PROXY_SCHEDULER_FILE)
        DOMAIN_DIR=$(echo $DOMAIN_VOLUME | jq -r .SOURCE)

        mkdir -p $SERVICE_DIR
        cp -av /tmp/$i/*.json $SERVICE_DIR/

        install_additionals_core

        mkdir -p $PROXY_DIR
        mkdir -p $DOMAIN_DIR

        SPEC_PROXY_DIR=$PROXY_DIR/$i
        PROXY_VOLUMES=$(jq -r '.containers[].VOLUMES[].SOURCE' /tmp/$i/$i.json | grep -v '\.')
        for VOLUME in $PROXY_VOLUMES; do
            mkdir -p $VOLUME
        done

        SOURCE=$(cat /tmp/$i/proxy_config | tail -n+2 | head -n-2)
        TMP_FILE=$(mktemp -p /tmp/)
        if [ -f $PROXY_DIR/proxy.json ]; then
            TARGET=$(cat $PROXY_DIR/proxy.json | tail -n+2)
            { echo "{"; echo "$SOURCE"; echo "},"; echo "$TARGET"; } >"$TMP_FILE"
        else
            { echo "{"; echo "$SOURCE"; echo "}"; echo "}"; } >"$TMP_FILE"
        fi
        jq -r . $TMP_FILE >$PROXY_DIR/proxy.json
        rm $TMP_FILE

        mkdir -p $SPEC_PROXY_DIR/loadbalancer
        cp -av /tmp/$i/haproxy.cfg $SPEC_PROXY_DIR/loadbalancer/

        if [ "$i" == "smarthost-proxy" ]; then
            if [ "$LETSENCRYPT_MAIL" == "" ]; then
                echo "WARNING: No LETSENCRYPT_MAIL given — Let's Encrypt will not work properly."
            else
                TMP_FILE=$(mktemp -p /tmp/)
                LETS_CONTENT='"letsencrypt": {"EMAIL": "'$LETSENCRYPT_MAIL'","SERVERNAME": "'$LETSENCRYPT_SERVERNAME'","DOCKER_REGISTRY_URL": "'$DOCKER_REGISTRY_URL'"}'
                if [ -f $USER_CONFIG_PATH ]; then
                    TARGET=$(cat $USER_CONFIG_PATH | head -n-2)
                    if [ "$TARGET" != "" ]; then
                        { echo "$TARGET"; echo "},"; echo "$LETS_CONTENT"; echo "}"; } >>"$TMP_FILE"
                    else
                        { echo "{"; echo "$LETS_CONTENT"; echo "}"; } >>"$TMP_FILE"
                    fi
                else
                    { echo "{"; echo "$LETS_CONTENT"; echo "}"; } >>"$TMP_FILE"
                fi
                jq -r . $TMP_FILE >$USER_CONFIG_PATH
                rm $TMP_FILE
            fi
        fi
    done
}

# ─── Inlined from additional_install.sh ──────────────────────────────────────

deploy_additional_services() {

    SERVICE_DIR=${SERVICE_DIR:-/etc/user/config/services}
    GIT_REPO=${GIT_REPO:-git.format.hu}
    ORGANIZATION=${ORGANIZATION:-format}

    if [ "$NEXTCLOUD" == "yes" ]; then
        echo "Nextcloud install has started from ssh://$GIT_REPO/$ORGANIZATION/nextcloud.git"
        DB_MYSQL="$(echo $RANDOM | md5sum | head -c 8)"
        git clone ssh://$GIT_REPO/$ORGANIZATION/nextcloud.git /tmp/nextcloud
        sed -i "s/DOMAIN_NAME/$NEXTCLOUD_DOMAIN/g"         /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/USERNAME/$NEXTCLOUD_USERNAME/g"           /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/USER_PASSWORD/$NEXTCLOUD_PASSWORD/g"      /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/DB_MYSQL/$DB_MYSQL/g"                     /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/DB_USER/$DB_USER/g"                       /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/DB_PASSWORD/$DB_PASSWORD/g"               /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/DB_ROOT_PASSWORD/$DB_ROOT_PASSWORD/g"     /tmp/nextcloud/nextcloud-secret.json
        sed -i "s/DOMAIN_NAME/$NEXTCLOUD_DOMAIN/g"         /tmp/nextcloud/domain-nextcloud.json
        cp -rv /tmp/nextcloud/nextcloud-secret.json               /etc/user/secret/nextcloud.json
        cp -rv /tmp/nextcloud/nextcloud.json                      $SERVICE_DIR/nextcloud.json
        cp -rv /tmp/nextcloud/domain-nextcloud.json               $SERVICE_DIR/domain-nextcloud.json
        cp -rv /tmp/nextcloud/firewall-nextcloud.json             $SERVICE_DIR/firewall-nextcloud.json
        cp -rv /tmp/nextcloud/firewall-nextcloud-server-dns.json  $SERVICE_DIR/
        cp -rv /tmp/nextcloud/firewall-nextcloud-server-smtp.json $SERVICE_DIR/
    fi

    if [ "$BITWARDEN" == "yes" ]; then
        echo "Bitwarden install has started from ssh://$GIT_REPO/$ORGANIZATION/bitwarden.git"
        DB_MYSQL="$(echo $RANDOM | md5sum | head -c 8)"
        BITWARDEN_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 48)
        git clone ssh://$GIT_REPO/$ORGANIZATION/bitwarden.git /tmp/bitwarden
        sed -i "s/DOMAIN_NAME/$BITWARDEN_DOMAIN/g"          /tmp/bitwarden/domain-bitwarden.json
        BITWARDEN_DOMAIN="https://$BITWARDEN_DOMAIN"
        sed -i "s/DB_MYSQL/$DB_MYSQL/g"                      /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/DB_USER/$DB_USER/g"                        /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/DB_PASSWORD/$DB_PASSWORD/g"                /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/DB_ROOT_PASSWORD/$DB_ROOT_PASSWORD/g"      /tmp/bitwarden/bitwarden-secret.json
        sed -i "s#DOMAIN_NAME#$BITWARDEN_DOMAIN#g"           /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/BITWARDEN_TOKEN/$BITWARDEN_TOKEN/g"        /tmp/bitwarden/bitwarden-secret.json

        if [ "$SMTP_SERVER" == "1" ]; then
            SMTP_SECURITY="starttls"
        elif [ "$SMTP_SERVER" == "2" ]; then
            SMTP_AUTH_MECHANISM="Login"
        fi

        sed -i "s/SMTPHOST/$SMTP_HOST/g"                     /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/SMTPPORT/$SMTP_PORT/g"                     /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/SMTPSECURITY/$SMTP_SECURITY/g"             /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/SMTPFROM/$SMTP_FROM/g"                     /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/SMTPUSERNAME/$SMTP_USERNAME/g"             /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/SMTPPASSWORD/$SMTP_PASSWORD/g"             /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/SMTPAUTHMECHANISM/$SMTP_AUTH_MECHANISM/g"  /tmp/bitwarden/bitwarden-secret.json
        sed -i "s/DOMAINSWHITELIST/$DOMAINS_WHITELIST/g"     /tmp/bitwarden/bitwarden-secret.json
        cp -rv /tmp/bitwarden/bitwarden-secret.json  /etc/user/secret/bitwarden.json
        cp -rv /tmp/bitwarden/bitwarden.json         $SERVICE_DIR/bitwarden.json
        cp -rv /tmp/bitwarden/domain-bitwarden.json  $SERVICE_DIR/domain-bitwarden.json
        cp -rv /tmp/bitwarden/firewall-bitwarden.json $SERVICE_DIR/firewall-bitwarden.json
    fi

    if [ "$GUACAMOLE" == "yes" ]; then
        echo "Guacamole install has started from ssh://$GIT_REPO/$ORGANIZATION/guacamole.git"
        DB_MYSQL="$(echo $RANDOM | md5sum | head -c 8)"
        git clone ssh://$GIT_REPO/$ORGANIZATION/guacamole.git /tmp/guacamole
        sed -i "s/DOMAIN_NAME/$GUACAMOLE_DOMAIN/g"                     /tmp/guacamole/guacamole-secret.json
        sed -i "s/GUACAMOLE_ADMIN_NAME/$GUACAMOLE_ADMIN_NAME/g"         /tmp/guacamole/guacamole-secret.json
        sed -i "s/GUACAMOLE_ADMIN_PASSWORD/$GUACAMOLE_ADMIN_PASSWORD/g" /tmp/guacamole/guacamole-secret.json
        sed -i "s/TOTP_USE/$TOTP_USE/g"                                 /tmp/guacamole/guacamole-secret.json
        sed -i "s/BAN_DURATION/$BAN_DURATION/g"                         /tmp/guacamole/guacamole-secret.json
        sed -i "s/DB_MYSQL/$DB_MYSQL/g"                                 /tmp/guacamole/guacamole-secret.json
        sed -i "s/DB_USER/$DB_USER/g"                                   /tmp/guacamole/guacamole-secret.json
        sed -i "s/DB_PASSWORD/$DB_PASSWORD/g"                           /tmp/guacamole/guacamole-secret.json
        sed -i "s/DB_ROOT_PASSWORD/$DB_ROOT_PASSWORD/g"                 /tmp/guacamole/guacamole-secret.json
        sed -i "s/DOMAIN_NAME/$GUACAMOLE_DOMAIN/g"                     /tmp/guacamole/domain-guacamole.json
        cp -rv /tmp/guacamole/guacamole-secret.json   /etc/user/secret/guacamole.json
        cp -rv /tmp/guacamole/guacamole.json          $SERVICE_DIR/guacamole.json
        cp -rv /tmp/guacamole/domain-guacamole.json   $SERVICE_DIR/domain-guacamole.json
        cp -rv /tmp/guacamole/firewall-guacamole.json $SERVICE_DIR/firewall-guacamole.json
    fi

    if [ "$SMTP" == "yes" ]; then
        git clone ssh://$GIT_REPO/$ORGANIZATION/smtp.git /tmp/smtp
        cp -rv /tmp/smtp/firewall-smtp.json $SERVICE_DIR/firewall-smtp.json
    fi

    if [ "$ROUNDCUBE" == "yes" ]; then
        git clone ssh://$GIT_REPO/$ORGANIZATION/roundcube.git /tmp/roundcube
    fi
}

#@@@@@@
# START
#@@@@@@

JSON="$(echo $1 | base64 -d)"

# Loop through each key in the JSON and create a variable
for key in $(echo "$JSON" | jq -r 'keys[]'); do
    value=$(echo "$JSON" | jq -r --arg k "$key" '.[$k]')
    eval "$key=$value"
done

SUDO_CMD=""

# first install - TODEL ??
if [ "$FIRST_INSTALL" == "true" ]; then

    INIT="true"

    if [ "$VPN_PROXY" == "yes" ]; then
        if [ "$LETSENCRYPT_SERVERNAME" = "" ]; then
            LETSENCRYPT_SERVERNAME="letsencrypt"
        fi
    fi

	if [[ "$SMARTHOST_PROXY" == "YES" || "$SMARTHOST_PROXY" == "TRUE" ]]; then 
		PROXY_TYPE=smarthost-proxy" "$PROXY_TYPE; 
	fi 

	if [ "$PROXY_TYPE" == "" ] ; then
		echo "No proxy type deployment defined, exiting."
		exit;
	fi

    deploy_core
	version_update;

	echo "Successfully deployed $PROXY_TYPE"


elif [ "$FIRST_INSTALL" == "vpn" ]; then

    INIT_SERVICE_PATH=/etc/user/config/services
    AUTO_START_SERVICES="/etc/system/data/"

    get_vpn_key

    if [ "$VPN_PROXY" != "no" ]; then

	    edit_user_json $LETSENCRYPT_MAIL $LETSENCRYPT_SERVERNAME

	    $SERVICE_EXEC vpn-proxy stop force
	    $SERVICE_EXEC vpn-proxy start
	    echo "$INIT_SERVICE_PATH/vpn-proxy.json" >>$AUTO_START_SERVICES/.init_services
	    echo "$INIT_SERVICE_PATH/firewall-vpn-smarthost-loadbalancer" >>$AUTO_START_SERVICES/.init_services
	    echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-postrouting" >>$AUTO_START_SERVICES/.init_services
	    echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-prerouting" >>$AUTO_START_SERVICES/.init_services

    fi;

    exit

#else
    #$SUDO_CMD docker pull $DOCKER_REGISTRY_URL/installer-tool
    #$SUDO_CMD docker pull $DOCKER_REGISTRY_URL/setup
fi

# # test - alias doesn't work inside a function
# # must be outside of if
# shopt -s expand_aliases
# source $HOME/.bash_aliases

if [ "$INIT" == "true" ]; then

    INIT_SERVICE_PATH=/etc/user/config/services
    AUTO_START_SERVICES="/etc/system/data/"

    # type -a $SERVICE-EXEC

    $SERVICE_EXEC core-dns start
    echo "$INIT_SERVICE_PATH/core-dns.json" >>$AUTO_START_SERVICES/.init_services

    if [ "$CRON" == "yes" ]; then
        $SERVICE_EXEC cron start
        echo "$INIT_SERVICE_PATH/cron.json" >>$AUTO_START_SERVICES/.init_services
    fi

    if [ "$VPN_PROXY" == "yes" ]; then

        get_vpn_key

        $SERVICE_EXEC vpn-proxy start
        echo "$INIT_SERVICE_PATH/vpn-proxy.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-vpn-smarthost-loadbalancer" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-postrouting" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-prerouting" >>$AUTO_START_SERVICES/.init_services

    fi

    if [ "$SMARTHOST_PROXY" == "yes" ]; then
        $SERVICE_EXEC smarthost-proxy start
        $SERVICE_EXEC smarthost-proxy-scheduler start
        $SERVICE_EXEC local-loadbalancer start

        echo "$INIT_SERVICE_PATH/smarthost-proxy.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-smarthost-loadbalancer-dns.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-letsencrypt.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-smarthostloadbalancer-from-publicbackend.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-smarthost-backend-dns.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-smarthost-to-backend.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/smarthost-proxy-scheduler.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/local-loadbalancer.json" >>$AUTO_START_SERVICES/.init_services

        if [ "$LOCAL_BACKEND" == "yes" ]; then
            $SERVICE_EXEC local-backend start
            echo "$INIT_SERVICE_PATH/local-backend.json" >>$AUTO_START_SERVICES/.init_services
            echo "$INIT_SERVICE_PATH/firewall-local-backend.json" >>$AUTO_START_SERVICES/.init_services
            echo "$INIT_SERVICE_PATH/domain-local-backend.json" >>$AUTO_START_SERVICES/.init_services
        fi
    fi

fi

ADDITIONAL_SERVICES=""

# install additionals
if [ "$ADDITIONALS" == "yes" ]; then

    deploy_additional_services

    if [ "$NEXTCLOUD" == "yes" ]; then
        if [ ! -d "/etc/user/data/nextcloud" ]; then
            for DIR in data apps config; do
                $SUDO_CMD mkdir -p "/etc/user/data/nextcloud/$DIR"
                $SUDO_CMD chown -R 82:82 "/etc/user/data/nextcloud/$DIR"
            done
        fi

        echo "Would you like to run Nextcloud after install? (Y/n)"
        read -r ANSWER
        if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then
            ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES nextcloud"
        fi
    fi

    if [ "$BITWARDEN" == "yes" ]; then
        echo "                                                                                      "
        echo "######################################################################################"
        echo "# You can access your bitwarden admin page here: https://$BITWARDEN_DOMAIN/admin #"
        echo "# You will find ADMIN TOKEN in this file: /etc/user/secret/bitwarden.json            #"
        echo "######################################################################################"
        echo "                                                                                      "
        echo "Would you like to run Bitwarden after install? (Y/n)"

        read -r ANSWER
        if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then
            ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES bitwarden"
        fi
    fi

    if [ "$GUACAMOLE" == "yes" ]; then
        echo "Would you like to run Guacamole after install? (Y/n)"
        read -r ANSWER
        if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then
            ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES guacamole"
        fi
    fi

    if [ "$SMTP" == "yes" ]; then
        echo "Would you like to run SMTP after install? (Y/n)"
        read -r ANSWER
        if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then
            ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES smtp"
        fi
    fi

    if [ "$ROUNDCUBE" == "yes" ]; then
        echo "Would you like to run roundcube after install? (Y/n)"
        read -r ANSWER
        if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then
            ADDITIONAL_SERVICES="$ADDITIONAL_SERVICES roundcube"
        fi
    fi

fi

#shopt -s expand_aliases
#source $HOME/.bash_aliases

if [ "$ADDITIONAL_SERVICES" != "" ]; then
    for ADDITIONAL_SERVICE in $(echo $ADDITIONAL_SERVICES); do
        $SERVICE_EXEC $ADDITIONAL_SERVICE start
        echo "$INIT_SERVICE_PATH/$ADDITIONAL_SERVICE.json" >>$AUTO_START_SERVICES/.init_services
    done
fi

if [ "$DISCOVERY" != "yes" ]; then
    discover_services
fi

if [ "$DISCOVERY" == "yes" ]; then
    $SUDO_CMD chmod a+x $DISCOVERY_DIR/service-discovery.sh
    $DISCOVERY_DIR/service-discovery.sh $DISCOVERY_CONFIG_FILE
    source $DISCOVERY_CONFIG_FILE
    cat $DEST_FILE

    echo "Would you like to run discovered services? (Y/n)"
    read -r ANSWER
    if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then
        $SUDO_CMD chmod a+x $DISCOVERY_DIR/service-files.sh
        $DISCOVERY_DIR/service-files.sh $DEST_FILE &
    fi
fi

if [ "$DEBIAN" == "true" ] || [ "$GENTOO" == "true" ]; then

    echo "Do you want to start the discovered and actually started services at the next time when your system restarting? (Y/n)"
    read -r ANSWER
    if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "Y" ] || [ "$ANSWER" == "" ]; then

        cp $DISCOVERY_CONFIG_FILE $DISCOVERY_CONFIG_FILE".copy"
        cp $DEST_FILE $DEST_FILE".copy"

        DISCOVERY_CONFIG_FILENAME=$(basename $DISCOVERY_CONFIG_FILE)
        source $DISCOVERY_CONFIG_FILE
        {
            echo '#!/bin/bash'
            echo 'SOURCE_DIRS="'$SOURCE_DIRS'"; # separator space or |'
            echo 'DIRNAME="'$DIRNAME'"; # separator space or |'
            echo 'FILENAME="'$FILENAME'"; # separator space or |'
            echo 'KEYS="'$KEYS'"; # separator space or |'
            echo 'DEST_FILE="/usr/local/etc/results.txt";'
            echo 'USE_SUDO=0;'
        } >/tmp/$DISCOVERY_CONFIG_FILENAME

        $SUDO_CMD mkdir -p /usr/local/etc

        $SUDO_CMD mv /tmp/$DISCOVERY_CONFIG_FILENAME /usr/local/etc/$DISCOVERY_CONFIG_FILENAME

        {
            cat $AUTO_START_SERVICES/.init_services
            cat $DEST_FILE
        } >/tmp/$DEST_FILE

        $SUDO_CMD mv /tmp/$DEST_FILE /usr/local/etc/$DEST_FILE

        if [ "$DEBIAN" == "true" ]; then
            {
                echo "
[Unit]
Description=Discover services

[Service]
Type=oneshot
ExecStart=/usr/local/bin/service-files.sh /usr/local/etc/results.txt restart

[Install]
WantedBy=multi-user.target
"

            } >/tmp/discovery.service
            $SUDO_CMD mv /tmp/discovery.service /etc/systemd/system/discovery.service
            $SUDO_CMD systemctl enable discovery.service

        elif [ "$GENTOO" == "true" ]; then
            $SUDO_CMD echo "/usr/local/bin/service-files.sh /usr/local/etc/results.txt restart" >/etc/local.d/service-file.start
            $SUDO_CMD chmod a+x /etc/local.d/service-file.start
        fi
    fi
fi

rm $AUTO_START_SERVICES/.init_services
