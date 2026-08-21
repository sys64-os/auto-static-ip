#!/bin/bash
source /etc/interface.conf
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

cat <<EONET > $NETPLAN_FILE
network:
  version: 2
  renderer: networkd
  ethernets:
    $PHYSICAL_INTERFACE_IN:
      dhcp4: false
      dhcp6: false
      optional: true
EONET

if [ -n "$PHYSICAL_INTERFACE_EXPAND" ] && [ "$PHYSICAL_INTERFACE_EXPAND" != "false" ]; then
    cat <<EONET_EXPAND >> $NETPLAN_FILE
    $PHYSICAL_INTERFACE_EXPAND:
      dhcp4: false
      dhcp6: false
      optional: true
EONET_EXPAND
fi

chmod 600 $NETPLAN_FILE
netplan generate
netplan apply
echo "Netplan disinkronkan. Mode: $( [ -n "$PHYSICAL_INTERFACE_EXPAND" ] && [ "$PHYSICAL_INTERFACE_EXPAND" != "false" ] && echo 'Dual Port (Input + Expand)' || echo 'Single Port (Input Only)' )"
