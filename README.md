Berikut adalah pembaruan file `README.md` yang telah disesuaikan dengan versi **0.0.0.1-beta**, termasuk penjelasan mengenai fleksibilitas *port* tunggal/ganda (Single/Dual NIC) dan pembaruan perintah bantuan (Help).

Anda dapat langsung menyalin isi di bawah ini dan menyimpannya sebagai file `README.md` di dalam proyek Anda.

```markdown
# Auto-Static-IP & OVS Manager (v0.0.0.1-beta)

Aplikasi pengelola jaringan portabel untuk *host* virtualisasi Ubuntu berbasis Open vSwitch (OVS). Aplikasi ini secara otomatis menangkap alokasi IP dinamis (DHCP) beserta rujukan DNS Domain Controller, lalu menguncinya menjadi IP statis pada OVS bridge (`ovsbr0`). 

Versi **0.0.0.1-beta** menghadirkan pembaruan logika generator Netplan yang mendukung fleksibilitas antarmuka (*Single NIC* maupun *Dual NIC*). Sangat ideal untuk *bare-metal server* besar, PC mini, maupun *Virtual Machine* yang sering berpindah jaringan, namun tetap membutuhkan kestabilan IP lokal untuk layanan terpusat (Keycloak, Samba, LXC/Incus).

## Fitur Utama

1. **Fleksibilitas Port (Hybrid Mode):** Dapat berjalan di server dengan satu antarmuka fisik (hanya input) maupun dua antarmuka (input + trunk expand).
2. **Otomatisasi Boot-time:** Dijalankan otomatis oleh *systemd* saat server menyala.
3. **Dukungan Hotplug (Udev):** Mendeteksi cabut-colok kabel LAN sumber internet dan menyesuaikan IP statis tanpa perlu *restart* server.
4. **Single Source of Truth (SSOT):** Semua pengaturan port dan domain terpusat di `/etc/interface.conf`.
5. **Generator Environment File:** Menghasilkan file `/var/lib/auto-static-ip/network.env` yang siap dikonsumsi oleh Docker Compose atau layanan Systemd lainnya.

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

Jika Anda menggunakan paket `auto-static-ip-v0.0.0.1-beta.zip`:

1. Ekstrak file zip di server target:
```bash
unzip auto-static-ip-v0.0.0.1-beta.zip -d auto-static-ip
cd auto-static-ip/auto-static-ip-v0.0.0.1-beta

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

Atur variabel berikut sesuai dengan perangkat keras server Anda. **Jika server Anda hanya memiliki satu port LAN, kosongkan variabel expand atau isi dengan "false"**.

```ini
PHYSICAL_INTERFACE_IN="enp1s0"        # Port sumber internet/DHCP
PHYSICAL_INTERFACE_EXPAND=""          # Kosongkan atau isi "false" jika hanya 1 port LAN
OVS_BRIDGE="ovsbr0"                   # Nama Open vSwitch bridge
SEARCH_DOMAIN="meaningfrost.my.id"    # Domain resolusi lokal

```

Setelah mengubah konfigurasi, selalu jalankan sinkronisasi Netplan:

```bash
sudo auto-static-ip sync

```

## Panduan Penggunaan CLI

Gunakan perintah `auto-static-ip` dari terminal mana saja.

* **`auto-static-ip start`** : Menjalankan paksa proses pembaruan DHCP-ke-Statis dan menulis ulang ke `systemd-networkd` serta `/etc/hosts`.
* **`auto-static-ip sync`** : Merakit ulang konfigurasi Netplan berdasarkan mode *Single* atau *Dual Port* di `interface.conf`.
* **`auto-static-ip info`** : Melakukan diagnostik sistem ("X-Ray" jaringan) untuk melihat status *Renderer*, OVS Bridge, Rute, dan DNS.
* **`auto-static-ip help`** : Menampilkan menu panduan singkat (Bisa juga dipanggil dengan `--help`, `-h`, atau dibiarkan kosong).

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

---

*Dikembangkan untuk melengkapi arsitektur Ubuntu Server OVS & Identity Infrastructure.*

```

```