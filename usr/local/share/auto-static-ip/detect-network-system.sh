#!/bin/bash
echo "=== DIAGNOSTIK JARINGAN SERVER (v0.0.0.1-beta) ==="
systemctl is-active --quiet systemd-networkd && echo "[+] systemd-networkd : AKTIF"
systemctl is-active --quiet systemd-resolved && echo "[+] systemd-resolved : AKTIF"
echo "[*] DNS Rujukan:" && grep '^nameserver' /etc/resolv.conf
echo "[*] Status Interface:" && ip -4 -br addr show
echo "[*] OVS Bridge:" && command -v ovs-vsctl &> /dev/null && ovs-vsctl show | grep -E 'Bridge|Port'
