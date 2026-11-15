# VM-02 Energy Nasional — Ubuntu 24.04 + Nginx + PHP 5.6

**Status:** Paket aplikasi dan installer telah disusun serta diperiksa statis. Installer **belum** dijalankan pada VM Ubuntu 24.04. Memerlukan internet saat instalasi APT dan `docker pull`.

## Isi paket

- `setup.sh` — installer Nginx, Docker, PHP 5.6 FPM, OpenSSH, web app, Nginx virtual host, health check
- `app/index.php` — website company profile dan dua formulir pelanggan
- `app/assets/` — CSS, ilustrasi SVG, logo fiktif

## Instalasi

Anda bisa menyalin **hanya file `setup.sh`** ke Ubuntu karena seluruh source website sudah tertanam di dalam script. Alternatifnya, ekstrak seluruh ZIP bila ingin mengedit source aplikasi, kemudian:

```bash
cd energy-ctf
chmod +x setup.sh
sudo LAB_DOMAIN=energy.co.id LAB_IP=192.168.36.93 ./setup.sh
sudo ./setup.sh --status
```

Sesuaikan IP contoh `192.168.36.93` dengan IP VM Energy Nasional. Jika port 80 sudah dipakai oleh aplikasi sebelumnya, matikan situs Nginx lama atau gunakan VM khusus.

### Konfigurasi Kali Linux

Tambahkan ke `/etc/hosts` Kali (sesuaikan IP):

```
192.168.36.93 energy.co.id
```

Kemudian buka:

- `http://energy.co.id/` — landing page
- `http://energy.co.id/profil` — profil perusahaan dan manajemen fiktif
- `http://energy.co.id/layanan` — layanan perusahaan
- `http://energy.co.id/berita` — berita dummy
- `http://energy.co.id/hubungi-kami` — formulir pesan dengan lampiran
- `http://energy.co.id/cek-data-pelanggan` — formulir verifikasi data dengan lampiran

## Lokasi aplikasi

| Lokasi | Keterangan |
|---|---|
| `/opt/energy-ctf/www/` | source aplikasi yang dihidangkan Nginx |
| `/opt/energy-ctf/www/index.php` | halaman utama/front controller |
| `/opt/energy-ctf/www/assets/` | CSS, logo dan ilustrasi |
| `/opt/energy-ctf/uploads/contact/` | lampiran Hubungi Kami |
| `/opt/energy-ctf/uploads/customer/` | lampiran Cek Data Pelanggan |
| `/opt/energy-ctf/uploads/upload-events.log` | catatan server tentang upload |
| `/etc/nginx/sites-available/energy-ctf` | virtual host Nginx |
| `/var/log/nginx/energy-access.log` | access log Nginx |
| `energy-php56` | nama container PHP 5.6-FPM |

## Catatan keamanan / cakupan skenario

Kedua form menerima semua **ekstensi** berkas (tanpa allowlist jenis file), untuk studi risiko validasi upload. Akan tetapi, file disimpan dengan nama acak `.dat` **di luar webroot**; tidak dapat diakses atau dieksekusi melalui URL. Direktori website tidak menggunakan permission `777`, PHP hanya dapat mengubah direktori uploads dan endpoint PHP FPM hanya terikat pada loopback host. Tidak ada akses root atau jalur eskalasi hak istimewa yang ditanamkan.

Untuk tantangan mencari `root.txt`, gunakan artefak/flag simulasi yang dibuat pada tahap pengembangan CTF berikutnya; jangan menggunakan file root OS yang sebenarnya. PHP 5.6 tidak lagi menerima pembaruan keamanan, sehingga gunakan snapshot VM, jaringan **Internal Network / Host-only** dan **tanpa akses publik** setelah instalasi.

Domain `energy.co.id` hanyalah mapping lokal dan tidak menandakan kepemilikan domain publik. Penggunaan `.test` lebih aman untuk lab yang sepenuhnya tertutup.

## Diagnostik

```bash
sudo ./setup.sh --status
sudo nginx -t
sudo docker logs --tail 40 energy-php56
sudo tail -f /var/log/nginx/energy-error.log
curl --noproxy '*' -I -H 'Host: energy.co.id' http://127.0.0.1/
```

Jika `docker pull php:5.6-fpm` gagal karena arsitektur/manifest legacy, ganti `PHP_IMAGE` dengan image legacy PHP 5.6 FPM yang telah diverifikasi di lingkungan internal Anda. Jangan menjalankan image yang tidak dipercaya.
