#!/bin/bash
source /etc/interface.conf
echo "=== DIAGNOSTIK JARINGAN SERVER (v0.0.0.2-beta) ==="
systemctl is-active --quiet systemd-networkd && echo "[+] systemd-networkd : AKTIF"
systemctl is-active --quiet systemd-resolved && echo "[+] systemd-resolved : AKTIF"
echo "[*] DNS Rujukan:" && grep '^nameserver' /etc/resolv.conf
echo "[*] Status Interface:" && ip -4 -br addr show

echo -e "\n[*] STATUS MODE JARINGAN:"
if [ -z "$OVS_BRIDGE" ] || [ "$OVS_BRIDGE" == "false" ]; then
    echo "  -> OVS BYPASSED: Jaringan dikelola langsung di $PHYSICAL_INTERFACE_IN"
else
    echo "  -> OVS ENABLED: Jaringan dikelola pada bridge $OVS_BRIDGE"
    command -v ovs-vsctl &> /dev/null && ovs-vsctl show | grep -E 'Bridge|Port'
fi
