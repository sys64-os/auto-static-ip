#!/bin/bash
source /etc/interface.conf
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
cat <<EONET> $NETPLAN_FILE
network:
  version: 2
  renderer: networkd
  ethernets:
    $PHYSICAL_INTERFACE_IN:
      dhcp4: false
      dhcp6: false
      optional: true
    $PHYSICAL_INTERFACE_EXPAND:
      dhcp4: false
      dhcp6: false
      optional: true
EONET
chmod 600 $NETPLAN_FILE
netplan generate
netplan apply
