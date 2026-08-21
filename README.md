# Auto-Static-IP Manager (v0.0.0.2-beta)

Aplikasi pengelola jaringan universal dan portabel untuk *host* Ubuntu. Aplikasi ini secara otomatis menangkap alokasi IP dinamis (DHCP) beserta rujukan DNS Domain Controller, lalu menguncinya menjadi IP statis (*DHCP-to-Static*).

Versi **0.0.0.2-beta** menghadirkan fitur **OVS Bypass**. Anda kini dapat menggunakan aplikasi ini pada server yang memiliki virtualisasi (membutuhkan Open vSwitch) maupun pada *server node* biasa (langsung menggunakan *interface* fisik via `systemd-networkd`).

## Fitur Utama

1. **OVS Bypass Mode:** Kosongkan variabel `OVS_BRIDGE` di pengaturan, dan sistem akan langsung menjadikan IP fisik utama Anda sebagai target IP statis.
2. **Hybrid Port Mode:** Mendukung server dengan satu antarmuka fisik (*Single NIC*) maupun dua antarmuka (*Dual NIC/Expand*).
3. **Otomatisasi Boot-time & Hotplug:** Dijalankan otomatis oleh *systemd* saat menyala dan mendeteksi cabut-colok kabel LAN via *Udev* tanpa perlu *restart*.
4. **Single Source of Truth (SSOT):** Semua pengaturan port dan domain terpusat di `/etc/interface.conf`.
5. **Generator Environment File:** Menghasilkan file `/var/lib/auto-static-ip/network.env` yang memuat variabel `TARGET_INTERFACE` dan `CURRENT_IP` untuk dikonsumsi oleh layanan lain.

## Instalasi (Paket ZIP)

1. Ekstrak file zip di server target:
   ```bash
   unzip auto-static-ip.zip -d auto-static-ip
   cd auto-static-ip/auto-static-ip

```

2. Jalankan skrip instalasi dengan hak akses root (sudo):
```bash
sudo ./install.sh

```



## Konfigurasi Awal (`/etc/interface.conf`)

Sesuaikan variabel berikut sesuai dengan perangkat keras dan kebutuhan topologi server Anda:

```ini
PHYSICAL_INTERFACE_IN="enp1s0"        # Port sumber internet/DHCP

# Kosongkan atau isi "false" jika hanya 1 port LAN
PHYSICAL_INTERFACE_EXPAND=""          

# Kosongkan atau isi "false" jika TIDAK menggunakan Open vSwitch
OVS_BRIDGE="ovsbr0"                   

SEARCH_DOMAIN="meaningfrost.my.id"    # Domain resolusi lokal

```

*(Catatan: Setelah mengubah file ini, selalu jalankan `sudo auto-static-ip sync` dan `sudo auto-static-ip start`)*.

## Panduan Penggunaan CLI

* **`auto-static-ip start`** : Menjalankan paksa proses DHCP-ke-Statis pada *interface* yang aktif.
* **`auto-static-ip sync`** : Merakit ulang konfigurasi Netplan berdasarkan variabel.
* **`auto-static-ip info`** : Melihat status layanan jaringan, *interface* aktif, dan mode OVS.
* **`auto-static-ip help`** : Menampilkan menu panduan.

```

Dengan tambahan versi 0.0.0.2-beta ini, *script* Anda resmi menjadi alat jaringan multi-fungsi yang sangat adaptif. Apakah Anda berencana untuk mempublikasikan *script* ini ke repositori publik seperti GitHub di kemudian hari?

```