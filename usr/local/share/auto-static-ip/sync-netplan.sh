#!/bin/bash
source /etc/interface.conf
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

# Tulis konfigurasi dasar dan port input utama
cat <<EOF > $NETPLAN_FILE
network:
  version: 2
  renderer: networkd
  ethernets:
    $PHYSICAL_INTERFACE_IN:
      dhcp4: false
      dhcp6: false
      optional: true
EOF

# Tambahkan konfigurasi port expand HANYA jika variabel terisi dan bukan "false"
if [ -n "$PHYSICAL_INTERFACE_EXPAND" ] && [ "$PHYSICAL_INTERFACE_EXPAND" != "false" ]; then
    cat <<EOF >> $NETPLAN_FILE
    $PHYSICAL_INTERFACE_EXPAND:
      dhcp4: false
      dhcp6: false
      optional: true
EOF
fi

chmod 600 $NETPLAN_FILE
netplan generate
netplan apply
echo "Netplan disinkronkan. Mode: $( [ -n "$PHYSICAL_INTERFACE_EXPAND" ] && [ "$PHYSICAL_INTERFACE_EXPAND" != "false" ] && echo 'Dual Port (Input + Expand)' || echo 'Single Port (Input Only)' )"