# Get MY IP

# Get VPN network if exists

# Define port

# Define local IP range

# Define VPN IP range

# Store results


scan_network(){
        MyIP=$(ifconfig ${Interface}|grep inet |awk '{ print $2 }');
        TargetIP=$(echo $MyIP|cut -d . -f1-3);
        X=0
	OpenIP=""
        for i in $(seq 1 255); do
                nc -w 1 -z $TargetIP.$i 60022;
                if [ $? -eq 0 ]
                then
			if [ $MyIP != $TargetIP.$i ]
                        then
                                if [ $X = 1 ]
                                then
                                        # tobb nyitott IP
					echo "Found more than one IP addresses"
                                        echo "MAILKULDES"
					echo "">OpenIP.txt;
					# TODO mailkuldes ahova kell
					exit 1;
				else
					OpenIP=$TargetIP.$i;
                                fi
				X=1;
                        fi
                fi
	done
	if [ $X = 1  ]
	then
		echo $OpenIP>OpenIP.txt;
		echo "start LVM SYNC";
		echo "OpenIP mukodik = "$OpenIP;
		lvm_sync_create $OpenIP;
	else
		echo "No available local IP address found!"
		try_target_VPN;
	fi


}

try_target_IP(){
	MyIP=$(ifconfig ${Interface}|grep inet |awk '{ print $2 }');
 	nc -w 1 -z $OpenIP 60022;
        if [ $? -eq 0 ] 
                then
			if [ $MyIP = $OpenIP ]
				then	
				echo "Only own IP address found = "$OpenIP
				scan_network;
			fi
	else
	scan_network;
	fi
}

try_target_VPN(){
	nc -w 1 -z $VPN 60022;
        if [ $? -eq 0 ]
		then
		for i in {0..99}; do
		MyVPN=$(ifconfig tun$i 2>/dev/null |grep inet |awk '{ print $2 }');
			echo "My VPN="$MyVPN;
			echo "Found VPN="$VPN;
			if [ $VPN != $MyVPN ]
				then
				echo "VPN accessible="$VPN;
				lvm_sync_create $VPN;
					else
					echo "Only own VPN accessible="$VPN;
					exit 1;
			fi
		done
		else
		echo "No available server"
	fi
}
