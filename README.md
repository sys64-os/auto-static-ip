# Auto-Static-IP & OVS Manager (v1.0)

Aplikasi pengelola jaringan portabel untuk *host* virtualisasi Ubuntu berbasis Open vSwitch (OVS). Aplikasi ini secara otomatis menangkap alokasi IP dinamis (DHCP) beserta rujukan DNS Domain Controller, lalu menguncinya menjadi IP statis pada OVS bridge (`ovsbr0`). 

Sangat ideal untuk *bare-metal server* yang sering berpindah jaringan, namun tetap membutuhkan kestabilan IP lokal untuk *container* (LXC/Incus), mesin virtual (KVM), dan layanan identitas terpusat (Keycloak, Samba, LDAP).

## Fitur Utama

1. **Otomatisasi Boot-time:** Dijalankan otomatis oleh *systemd* saat server menyala.
2. **Dukungan Hotplug (Udev):** Mendeteksi cabut-colok kabel LAN sumber internet dan menyesuaikan IP statis tanpa perlu *restart* server.
3. **Single Source of Truth (SSOT):** Semua pengaturan nama *interface* fisik dan domain terpusat di `/etc/interface.conf`.
4. **Generator Environment File:** Menghasilkan `/var/lib/auto-static-ip/network.env` yang bisa dikonsumsi langsung oleh Docker Compose, Incus, atau layanan Systemd lainnya.
5. **CLI Terpusat:** Alat command-line `auto-static-ip` untuk manajemen jaringan sehari-hari.

## Skema Direktori

```text
/ (Root)
├── etc/
│   ├── interface.conf                           [Pusat Variabel Jaringan]
│   ├── systemd/system/auto-static-ip.service    [Layanan Automasi]
│   └── udev/rules.d/99-network-hotplug.rules    [Sensor Hotplug]
├── usr/
│   ├── bin/auto-static-ip                       [CLI Loader]
│   └── local/share/auto-static-ip/
│       ├── auto-static-ip.sh                    [Mesin Utama]
│       ├── hotplug-trigger.sh                   [Filter Udev]
│       ├── sync-netplan.sh                      [Generator Netplan OVS]
│       ├── detect-network-system.sh             [Diagnostik Jaringan]
│       └── help.sh                              [Panduan CLI]
```

## Instalasi

Jika Anda menggunakan paket `auto-static-ip.zip`:
1. Ekstrak file zip di server target:
   ```bash
   unzip auto-static-ip.zip -d auto-static-ip
   cd auto-static-ip/auto-static-ip-v1.0
   ```
2. Jalankan skrip instalasi dengan hak akses root (sudo):
   ```bash
   sudo ./install.sh
   ```

## Konfigurasi Awal

Setelah instalasi, pastikan untuk menyesuaikan nama port fisik di file konfigurasi pusat:
```bash
sudo nano /etc/interface.conf
```

Atur variabel berikut sesuai dengan perangkat keras server Anda:
```ini
PHYSICAL_INTERFACE_IN="enp1s0"        # Port sumber internet/DHCP
PHYSICAL_INTERFACE_EXPAND="enp2s0"    # Port ekspansi (trunk ke switch lain)
OVS_BRIDGE="ovsbr0"                   # Nama Open vSwitch bridge
SEARCH_DOMAIN="meaningfrost.my.id"    # Domain resolusi lokal
```

## Panduan Penggunaan CLI

Gunakan perintah `auto-static-ip` dari terminal mana saja.

* **`auto-static-ip start`** : Menjalankan paksa proses pembaruan DHCP-ke-Statis dan menulis ulang ke `systemd-networkd` serta `/etc/hosts`.
* **`auto-static-ip sync`** : Menggerakkan generator untuk merakit ulang konfigurasi Netplan berdasarkan variabel di `interface.conf`.
* **`auto-static-ip info`** : Melakukan diagnostik sistem ("X-Ray" jaringan) untuk melihat status *Renderer*, OVS Bridge, Rute, dan DNS.
* **`auto-static-ip help`** : Menampilkan menu panduan singkat di terminal.

## Integrasi Layanan (Container & Aplikasi)

Aplikasi akan selalu menulis data jaringan terbaru ke dalam file `.env`. Anda bisa memanggil file ini untuk berbagai kebutuhan.

**Lokasi File:** `/var/lib/auto-static-ip/network.env`

**Contoh Penggunaan pada Docker Compose (misal: Technitium DNS):**
```yaml
services:
  technitium:
    image: technitium/dns-server
    network_mode: "host"
    env_file:
      - /var/lib/auto-static-ip/network.env
```

**Contoh Penggunaan di Bash Script Kustom:**
```bash
#!/bin/bash
source /var/lib/auto-static-ip/network.env
echo "Server saat ini berada di IP: $CURRENT_IP"
echo "IP Domain Controller adalah: $CURRENT_DC_IP"
```

---
*Dikembangkan untuk melengkapi arsitektur Ubuntu Server OVS & Identity Infrastructure.*
