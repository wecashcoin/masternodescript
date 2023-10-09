#!/bin/bash

PORT=38244
RPCPORT=38245
CONF_DIR=~/.wch
COINZIP='https://github.com/wecashcoin/WCH/releases/download/v1.0/linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/wch.service
[Unit]
Description=WeCash Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/wchd
ExecStop=-/usr/local/bin/wch-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable wch.service
  systemctl start wch.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  rm wch-qt wch-tx wch-linux.zip
  chmod +x wch*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> wch.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> wch.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> wch.conf_TEMP
  echo "rpcport=$RPCPORT" >> wch.conf_TEMP
  echo "listen=1" >> wch.conf_TEMP
  echo "server=1" >> wch.conf_TEMP
  echo "daemon=1" >> wch.conf_TEMP
  echo "maxconnections=250" >> wch.conf_TEMP
  echo "masternode=1" >> wch.conf_TEMP
  echo "" >> wch.conf_TEMP
  echo "port=$PORT" >> wch.conf_TEMP
  echo "externalip=$IP:$PORT" >> wch.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> wch.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> wch.conf_TEMP
  mv wch.conf_TEMP wch.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start WeCash Service: ${GREEN}systemctl start wch${NC}"
echo -e "Check WeCash Status Service: ${GREEN}systemctl status wch${NC}"
echo -e "Stop WeCash Service: ${GREEN}systemctl stop wch${NC}"
echo -e "Check Masternode Status: ${GREEN}wch-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}WeCash Masternode Installation Done${NC}"
exec bash
exit
