#!/bin/bash
echo "Menginstal Auto-Static-IP..."
cp -r etc/* /etc/
cp -r usr/* /usr/
chmod +x /usr/bin/auto-static-ip
chmod +x /usr/local/share/auto-static-ip/*.sh
systemctl daemon-reload
systemctl enable auto-static-ip.service
udevadm control --reload-rules
udevadm trigger
echo "Instalasi Selesai! Ketik 'auto-static-ip help' untuk mulai."
