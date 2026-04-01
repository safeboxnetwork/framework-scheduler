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


# ─── Inlined from deploy.sh ───────────────────────────────────────────────────

toUpperCase() {
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

json_update() {
    REGISTRY_URL=$(jq -r '.DOCKER_REGISTRY_URL' /etc/user/config/user.json)
    OLD_REGISTRY_URL="${REGISTRY_URL:-safebox}"
    echo "Current registry URL: $OLDREGISTRY_URL"
    for JSON_FILE in $(find /etc/user/config/ /etc/system/config -type f -name "*.json" -exec grep -l "DOCKER_REGISTRY_URL" {} +) ; do
        ls -l $JSON_FILE
      #version_update $OLD_REGISTRY_URL
      registry_update $DOCKER_REGISTRY_URL $OLD_REGISTRY_URL
    done
}

version_update() {

    OLD_REGISTRY_URL=$1
    GLOBAL_VERSION=$(jq -r '.GLOBAL_VERSION' /etc/user/config/user.json)
    GLOBAL_VERSION="${GLOBAL_VERSION:-latest}"

    TMP_FILE=$(mktemp -p /tmp/)

    jq --arg registry "$OLD_REGISTRY_URL" --arg version "$GLOBAL_VERSION" '
        walk(
            if type == "object" then
                with_entries(
                    if .key == "IMAGE" and (.value | type == "string") and (.value | startswith($registry)) then
                        .value = (.value | split(":")[0]) + ":" + $version
                    else
                        .
                    end
                )
            else
                .
            end
        )
    ' "$JSON_FILE" > "$TMP_FILE"
    mv "$TMP_FILE" "$JSON_FILE"
}

registry_update() {
    
    NEW_REGISTRY_URL=$1
    OLD_REGISTRY_URL=$2

        TMP_FILE=$(mktemp -p /tmp/)
        jq --arg old_registry "$OLD_REGISTRY_URL" --arg new_registry "$NEW_REGISTRY_URL" '
            walk(
                if type == "object" then
                    with_entries(
                        if (.key == "IMAGE" or .key == "DOCKER_REGISTRY_URL") and (.value | type == "string") and (.value | startswith($old_registry)) then
                            .value = $new_registry + (.value | ltrimstr($old_registry))
                        else
                            .
                        end
                    )
                else
                    .
                end
            )
        ' "$JSON_FILE" > "$TMP_FILE"
        mv "$TMP_FILE" "$JSON_FILE"
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

    echo "starting core services installation"

    if [ "$LOCAL_PROXY" == "YES" ] || [ "$LOCAL_PROXY" == "TRUE" ]; then
        cp -av /tmp/$LOCAL_PROXY_REPO/*.json $SERVICE_DIR/
        if [ "$LOCAL_BACKEND" == "YES" ] || [ "$LOCAL_BACKEND" == "TRUE" ]; then
            install_local_backend
        fi
    fi

    if [ "$VPN_PROXY" == "YES" ] || [ "$VPN_PROXY" == "TRUE" ]; then
        cp -av /tmp/$VPN_PROXY_REPO/*.json $SERVICE_DIR/
        VPN_VOLUME=$(jq -r '.containers[0].VOLUMES[0].SOURCE' $SERVICE_DIR/vpn-proxy.json)
        mkdir -p "$(dirname "$VPN_VOLUME")"
    fi

    if [ "$CRON" == "YES" ] || [ "$CRON" == "TRUE" ]; then
        cp -av /tmp/$CRON_REPO/*.json $SERVICE_DIR/
        CRON_VOLUMES=$(jq -r '[.containers[].VOLUMES[].SOURCE | select(type == "string" and length > 0 and (test("\\.") | not) and (test("^\\s+$") | not))] | unique[]' "$SERVICE_DIR/cron.json")
        for VOLUME in $CRON_VOLUMES; do
            mkdir -p "$VOLUME"
        done
    fi

}

deploy_core() {
    SMARTHOST_PROXY=$(toUpperCase $SMARTHOST_PROXY)
    LOCAL_PROXY=$(toUpperCase $LOCAL_PROXY)
    LOCAL_BACKEND=$(toUpperCase $LOCAL_BACKEND)
    VPN_PROXY=$(toUpperCase $VPN_PROXY)
    CRON=$(toUpperCase $CRON)

    #PROXY_TYPE="${PROXY_TYPE:-smarthost-proxy}"
    PROXY_TYPE=""

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

	if [ "$PROXY_TYPE" == "" ] ; then
	 	echo "No proxy type deployment defined."
	fi

    git clone https://$GIT_REPO/$ORGANIZATION/$CORE_DNS.git /tmp/$CORE_DNS

    if [ "$LOCAL_PROXY" == "YES" ] || [ "$LOCAL_PROXY" == "TRUE" ]; then
        git clone https://$GIT_REPO/$ORGANIZATION/$LOCAL_PROXY_REPO.git /tmp/$LOCAL_PROXY_REPO
        git clone https://$GIT_REPO/$ORGANIZATION/$LOCAL_BACKEND_REPO.git /tmp/$LOCAL_BACKEND_REPO
    fi

    if [ "$VPN_PROXY" == "YES" ] || [ "$VPN_PROXY" == "TRUE" ]; then
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
        PROXY_DIR=$(dirname $PROXY_DIR | sed s/$i//g)

        DOMAIN_CONFIG_DIR=$(jq -r ".$PROXY_SCHEDULER_NAME.DOMAIN_DIR" /tmp/$i/proxy_config)
        DOMAIN_VOLUME=$(jq -r --arg DEST "$DOMAIN_CONFIG_DIR" \
            '.containers[0].VOLUMES[] | select(.DEST==$DEST)' /tmp/$i/$PROXY_SCHEDULER_FILE)
        DOMAIN_DIR=$(echo $DOMAIN_VOLUME | jq -r .SOURCE)

        mkdir -p $SERVICE_DIR
        cp -av /tmp/$i/*.json $SERVICE_DIR/

        mkdir -p $PROXY_DIR
        mkdir -p $DOMAIN_DIR

        SPEC_PROXY_DIR=$PROXY_DIR/$i
        PROXY_VOLUMES=$(jq -r '.containers[].VOLUMES[].SOURCE' /tmp/$i/$i.json | grep -v '\.')
        for VOLUME in $PROXY_VOLUMES; do
            mkdir -p $VOLUME
        done

        SOURCE=$(cat /tmp/$i/proxy_config)
        # If the target file exists, merge; else, just use the new object
        if [ -f "$PROXY_DIR/proxy.json" ]; then
            jq -s '.[0] * .[1]' <(echo "$SOURCE") "$PROXY_DIR/proxy.json" > "$PROXY_DIR/proxy.json.tmp"
            mv "$PROXY_DIR/proxy.json.tmp" "$PROXY_DIR/proxy.json"
        else
            echo "$SOURCE" > "$PROXY_DIR/proxy.json"
        fi

        mkdir -p $SPEC_PROXY_DIR/loadbalancer
        cp -av /tmp/$i/haproxy.cfg $SPEC_PROXY_DIR/loadbalancer/

        if [ "$i" == "smarthost-proxy" ]; then
            if [ "$LETSENCRYPT_MAIL" == "" ]; then
                echo "WARNING: No LETSENCRYPT_MAIL given — Let's Encrypt will not work properly."
            else
                TMP_FILE=$(mktemp -p /tmp/)
                if [ -f "$USER_CONFIG_PATH" ] && [ -s "$USER_CONFIG_PATH" ]; then
                    jq --arg email "$LETSENCRYPT_MAIL" \
                       --arg servername "$LETSENCRYPT_SERVERNAME" \
                       --arg registry "$DOCKER_REGISTRY_URL" \
                       '. + {"letsencrypt": {"EMAIL": $email, "SERVERNAME": $servername, "DOCKER_REGISTRY_URL": $registry}}' \
                       "$USER_CONFIG_PATH" > "$TMP_FILE"
                else
                    jq -n \
                       --arg email "$LETSENCRYPT_MAIL" \
                       --arg servername "$LETSENCRYPT_SERVERNAME" \
                       --arg registry "$DOCKER_REGISTRY_URL" \
                       '{"letsencrypt": {"EMAIL": $email, "SERVERNAME": $servername, "DOCKER_REGISTRY_URL": $registry}}' \
                       > "$TMP_FILE"
                fi
                mv "$TMP_FILE" "$USER_CONFIG_PATH"
            fi
        fi
    done

    install_additionals_core
}

# ─── Inlined from additional_install.sh ──────────────────────────────────────

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

    deploy_core
	json_update

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

fi

if [ "$INIT" == "true" ]; then

    INIT_SERVICE_PATH=/etc/user/config/services
    AUTO_START_SERVICES="/etc/system/data/"

    # type -a $SERVICE-EXEC

    $SERVICE_EXEC core-dns start
    echo "$INIT_SERVICE_PATH/core-dns.json" >>$AUTO_START_SERVICES/.init_services

    if [ "$CRON" == "YES" ]; then
        $SERVICE_EXEC cron start
        echo "$INIT_SERVICE_PATH/cron.json" >>$AUTO_START_SERVICES/.init_services
    fi

    if [ "$VPN_PROXY" == "YES" ]; then

        get_vpn_key

        $SERVICE_EXEC vpn-proxy start
        echo "$INIT_SERVICE_PATH/vpn-proxy.json" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-vpn-smarthost-loadbalancer" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-postrouting" >>$AUTO_START_SERVICES/.init_services
        echo "$INIT_SERVICE_PATH/firewall-vpn-proxy-prerouting" >>$AUTO_START_SERVICES/.init_services

    fi

    if [ "$SMARTHOST_PROXY" == "YES" ]; then
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

        if [ "$LOCAL_BACKEND" == "YES" ]; then
            $SERVICE_EXEC local-backend start
            echo "$INIT_SERVICE_PATH/local-backend.json" >>$AUTO_START_SERVICES/.init_services
            echo "$INIT_SERVICE_PATH/firewall-local-backend.json" >>$AUTO_START_SERVICES/.init_services
            echo "$INIT_SERVICE_PATH/domain-local-backend.json" >>$AUTO_START_SERVICES/.init_services
        fi
    fi

fi


