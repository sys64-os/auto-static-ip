#!/bin/bash
# ==========================================================
# GENERATOR ZIP: AUTO-STATIC-IP APPLIANCE (v0.0.0.1-beta)
# ==========================================================

echo "Memulai pembuatan direktori paket..."
PKG_DIR="auto-static-ip-v0.0.0.1-beta"
mkdir -p $PKG_DIR/etc/systemd/system
mkdir -p $PKG_DIR/etc/udev/rules.d
mkdir -p $PKG_DIR/usr/bin
mkdir -p $PKG_DIR/usr/local/share/auto-static-ip

# 1. /etc/interface.conf (Dukungan Fleksibel)
cat << 'EOF' > $PKG_DIR/etc/interface.conf
# KONFIGURASI JARINGAN & INTERFACE OVS
PHYSICAL_INTERFACE_IN="enp1s0"
# Biarkan kosong ("") atau isi "false" jika server hanya memiliki 1 port LAN
PHYSICAL_INTERFACE_EXPAND=""
OVS_BRIDGE="ovsbr0"
SEARCH_DOMAIN="meaningfrost.my.id"
EOF

# 2. /usr/bin/auto-static-ip (CLI Loader dengan perintah Help)
cat << 'EOF' > $PKG_DIR/usr/bin/auto-static-ip
#!/bin/bash
BASE_DIR="/usr/local/share/auto-static-ip"
case "$1" in
    start)    $BASE_DIR/auto-static-ip.sh ;;
    trigger)  $BASE_DIR/hotplug-trigger.sh "$2" ;;
    sync)     $BASE_DIR/sync-netplan.sh ;;
    info)     $BASE_DIR/detect-network-system.sh ;;
    help|--help|-h|"") $BASE_DIR/help.sh ;;
    *)
        echo "Perintah tidak dikenali: $1"
        echo "Ketik 'auto-static-ip help' untuk melihat panduan."
        exit 1
        ;;
esac
EOF

# 3. auto-static-ip.sh
cat << 'EOF' > $PKG_DIR/usr/local/share/auto-static-ip/auto-static-ip.sh
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

cat <<EONET > /etc/systemd/network/10-static-$INTERFACE.network
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
cat <<EOENV > $ENV_FILE
CURRENT_IP="$IP_ADDRESS"
CURRENT_CIDR="$IP_CIDR"
CURRENT_GATEWAY="$GATEWAY"
CURRENT_DC_IP="$IP_DC"
OVS_BRIDGE="$INTERFACE"
PHYSICAL_INTERFACE_IN="$PHYSICAL_INTERFACE_IN"
PHYSICAL_INTERFACE_EXPAND="$PHYSICAL_INTERFACE_EXPAND"
SEARCH_DOMAIN="$SEARCH_DOMAIN"
FQDN_DC="$FQDN_DC"
EOENV
chmod 644 $ENV_FILE
EOF

# 4. sync-netplan.sh (Logika Fleksibel Single/Dual Port)
cat << 'EOF' > $PKG_DIR/usr/local/share/auto-static-ip/sync-netplan.sh
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
EOF

# 5. hotplug-trigger.sh
cat << 'EOF' > $PKG_DIR/usr/local/share/auto-static-ip/hotplug-trigger.sh
#!/bin/bash
source /etc/interface.conf
if [ "$1" == "$PHYSICAL_INTERFACE_IN" ]; then
    /usr/bin/systemctl --no-block restart auto-static-ip.service
fi
EOF

# 6. detect-network-system.sh
cat << 'EOF' > $PKG_DIR/usr/local/share/auto-static-ip/detect-network-system.sh
#!/bin/bash
echo "=== DIAGNOSTIK JARINGAN SERVER (v0.0.0.1-beta) ==="
systemctl is-active --quiet systemd-networkd && echo "[+] systemd-networkd : AKTIF"
systemctl is-active --quiet systemd-resolved && echo "[+] systemd-resolved : AKTIF"
echo "[*] DNS Rujukan:" && grep '^nameserver' /etc/resolv.conf
echo "[*] Status Interface:" && ip -4 -br addr show
echo "[*] OVS Bridge:" && command -v ovs-vsctl &> /dev/null && ovs-vsctl show | grep -E 'Bridge|Port'
EOF

# 7. help.sh (Tampilan Versi Baru)
cat << 'EOF' > $PKG_DIR/usr/local/share/auto-static-ip/help.sh
#!/bin/bash
echo "================================================================="
echo "       AUTO-STATIC-IP & OVS MANAGER (v0.0.0.1-beta)"
echo "================================================================="
echo "Aplikasi pengelola DHCP-ke-Statis untuk Node/Host Ubuntu."
echo ""
echo "PENGGUNAAN:"
echo "  auto-static-ip [perintah]"
echo ""
echo "PERINTAH YANG TERSEDIA:"
echo "  start     : Menangkap IP dari DHCP ke systemd-networkd."
echo "  trigger   : Digunakan oleh udev untuk event hot-plug."
echo "  sync      : Menyelaraskan ulang Netplan dari interface.conf."
echo "  info      : Menampilkan diagnostik jaringan secara lengkap."
echo "  help      : Menampilkan layar panduan ini."
echo "================================================================="
EOF

# 8. auto-static-ip.service
cat << 'EOF' > $PKG_DIR/etc/systemd/system/auto-static-ip.service
[Unit]
Description=Konfigurasi DHCP-to-Static Open vSwitch
Wants=network-pre.target
After=local-fs.target openvswitch-switch.service
Before=network-pre.target systemd-networkd.service

[Service]
Type=oneshot
ExecStart=/usr/bin/auto-static-ip start
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 9. 99-network-hotplug.rules
cat << 'EOF' > $PKG_DIR/etc/udev/rules.d/99-network-hotplug.rules
SUBSYSTEM=="net", ACTION=="change", KERNEL=="eth*|en*", ATTR{carrier}=="1", RUN+="/usr/bin/auto-static-ip trigger %k"
EOF

# 10. install.sh
cat << 'EOF' > $PKG_DIR/install.sh
#!/bin/bash
echo "Menginstal Auto-Static-IP (v0.0.0.1-beta)..."
cp -r etc/* /etc/
cp -r usr/* /usr/
chmod +x /usr/bin/auto-static-ip
chmod +x /usr/local/share/auto-static-ip/*.sh
systemctl daemon-reload
systemctl enable auto-static-ip.service
udevadm control --reload-rules
udevadm trigger
echo "Instalasi Selesai! Ketik 'auto-static-ip help' untuk panduan."
EOF
chmod +x $PKG_DIR/install.sh

# Bungkus menjadi ZIP
echo "Mengompresi ke format ZIP..."
if ! command -v zip &> /dev/null; then
    sudo apt-get install zip -y
fi
zip -r auto-static-ip-v0.0.0.1-beta.zip $PKG_DIR

# Bersihkan folder sementara
rm -rf $PKG_DIR

echo "================================================================="
echo " SELESAI! File 'auto-static-ip-v0.0.0.1-beta.zip' berhasil dibuat."
echo "================================================================="