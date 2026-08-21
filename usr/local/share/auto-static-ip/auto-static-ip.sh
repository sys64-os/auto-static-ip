#!/bin/bash
source /etc/interface.conf || { echo "Error: /etc/interface.conf tidak ditemukan!"; exit 1; }

INTERFACE=$OVS_BRIDGE
HOSTNAME=$(hostname)
FQDN_DC="dc.$SEARCH_DOMAIN"

systemctl stop systemd-networkd
systemctl stop NetworkManager 2>/dev/null
rm -f /var/lib/dhcp/dhclient*.leases
dhclient $INTERFACE
sleep 5

IP_CIDR=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -n 1)
IP_ADDRESS=$(echo $IP_CIDR | cut -d/ -f1)
GATEWAY=$(ip route show dev $INTERFACE | grep default | awk '{print $3}')

[ -z "$IP_ADDRESS" ] && { echo "Gagal mendapatkan IP DHCP di $INTERFACE."; exit 1; }

IP_DC=$(grep "domain-name-servers" /var/lib/dhcp/dhclient*.leases 2>/dev/null | tail -1 | awk '{print $3}' | tr -d ';' | cut -d',' -f1)
[ -z "$IP_DC" ] && IP_DC=$GATEWAY
DNS_SERVERS="$IP_DC 8.8.8.8"

dhclient -r $INTERFACE
ip addr flush dev $INTERFACE

sed -i "/$SEARCH_DOMAIN/d" /etc/hosts
sed -i "/$HOSTNAME/d" /etc/hosts
sed -i "/^127.0.0.1/a $IP_ADDRESS $HOSTNAME $SEARCH_DOMAIN" /etc/hosts
sed -i "/^127.0.0.1/a $IP_DC $FQDN_DC dc" /etc/hosts

cat <<EONET> /etc/systemd/network/10-static-$INTERFACE.network
[Match]
Name=$INTERFACE

[Network]
Address=$IP_CIDR
Gateway=$GATEWAY
DNS=$DNS_SERVERS
Domains=$SEARCH_DOMAIN
EONET

systemctl enable systemd-networkd
systemctl start systemd-networkd
systemctl start systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

mkdir -p /var/lib/auto-static-ip
ENV_FILE="/var/lib/auto-static-ip/network.env"
cat <<EOENV> $ENV_FILE
CURRENT_IP="$IP_ADDRESS"
CURRENT_CIDR="$IP_CIDR"
CURRENT_GATEWAY="$GATEWAY"
CURRENT_DC_IP="$IP_DC"
OVS_BRIDGE="$INTERFACE"
PHYSICAL_INTERFACE_IN="$PHYSICAL_INTERFACE_IN"
SEARCH_DOMAIN="$SEARCH_DOMAIN"
FQDN_DC="$FQDN_DC"
EOENV
chmod 644 $ENV_FILE
