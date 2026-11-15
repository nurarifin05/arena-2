#!/usr/bin/env bash
# Energy Nasional — fictional company-profile and customer-service CTF lab.
# Ubuntu 24.04 + Nginx + isolated legacy PHP 5.6-FPM Docker runtime.
# Unrestricted extension acceptance is simulated. Uploaded content is never executable.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
LAB_DOMAIN="${LAB_DOMAIN:-energy.co.id}"
LAB_SUBNET="${LAB_SUBNET:-192.168.36.0/24}"
LAB_IP="${LAB_IP:-}"
ROOT=/opt/energy-ctf
WEB="$ROOT/www"
UP="$ROOT/uploads"
IMAGE="${PHP_IMAGE:-php:5.6-fpm}"
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
log(){ printf '[Energy Nacional] %s\n' "$*"; }
fail(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
status(){
  systemctl is-active nginx || true
  systemctl is-active docker || true
  docker ps --filter name='^/energy-php56$' --format '{{.Names}} {{.Status}}' 2>/dev/null || true
  ss -lntp | grep -E ':80 |:9000 ' || true
  curl --noproxy '*' -sS -I -H "Host: $LAB_DOMAIN" http://127.0.0.1/ || true
  log "Source: $WEB | Upload: $UP | Domain: $LAB_DOMAIN"
}
if [[ "${1:-}" == '--status' ]]; then status; exit 0; fi
[[ ${EUID} -eq 0 ]] || fail 'Jalankan sebagai root: sudo ./setup.sh'
# Standalone deployment: app files are embedded inside setup.sh as a compressed payload.
if [[ -f "$DIR/app/index.php" ]]; then
  SOURCE_APP="$DIR/app"
else
  PAYLOAD_DIR="$(mktemp -d /tmp/energy-ctf.XXXXXX)"
  trap 'rm -rf "$PAYLOAD_DIR"' EXIT
  base64 -d <<'ENERGY_APP_PAYLOAD' | tar -xz -C "$PAYLOAD_DIR"
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
m2tzba7Ntbk21+baXP9mrv8P7nFSJADIAAA=
ENERGY_APP_PAYLOAD
  SOURCE_APP="$PAYLOAD_DIR/app"
fi
[[ "$LAB_DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] || fail 'LAB_DOMAIN tidak valid.'
if ! grep -q 'Ubuntu 24.04' /etc/os-release; then log 'PERINGATAN: installer dibuat untuk Ubuntu 24.04'; fi
log 'Memasang Nginx, Docker, OpenSSH, dan utilitas...'
apt-get update
apt-get install -y nginx docker.io openssh-server curl ca-certificates unzip
systemctl enable --now docker nginx ssh
log 'Menyiapkan source aplikasi dan direktori uploads...'
mkdir -p "$WEB" "$UP/contact" "$UP/customer"
cp -a "$SOURCE_APP/." "$WEB/"
# Ownership: web is not writable by the PHP container or unprivileged users.
chown -R root:root "$WEB"
find "$WEB" -type d -exec chmod 0755 {} +
find "$WEB" -type f -exec chmod 0644 {} +
# PHP container user www-data uses uid 33 in the official Debian PHP image.
chown -R 33:33 "$UP"
chmod 0750 "$UP" "$UP/contact" "$UP/customer"
touch "$UP/upload-events.log"
chown 33:33 "$UP/upload-events.log"
chmod 0640 "$UP/upload-events.log"
log "Mengambil image $IMAGE. Image legacy mungkin tidak tersedia pada sebagian arsitektur Docker."
docker pull "$IMAGE"
if docker ps -a --format '{{.Names}}' | grep -qx energy-php56; then docker rm -f energy-php56 >/dev/null; fi
# PHP-FPM is reachable only on host loopback; upload area is a separate, no-webroot mount.
docker run -d --name energy-php56 --restart unless-stopped \
  --memory=512m --cpus=1 \
  -p 127.0.0.1:9000:9000 \
  -v "$WEB:/var/www/html:ro" \
  -v "$UP:/var/energy-uploads:rw" \
  "$IMAGE" \
  php-fpm -F -d upload_max_filesize=8M -d post_max_size=10M -d max_execution_time=30 \
  -d expose_php=Off -d display_errors=Off >/dev/null
log 'Mengonfigurasi Nginx...'
cat > /etc/nginx/sites-available/energy-ctf <<NGINX
server {
    listen 80;
    server_name ${LAB_DOMAIN};
    root ${WEB};
    index index.php;
    client_max_body_size 10m;
    access_log /var/log/nginx/energy-access.log;
    error_log /var/log/nginx/energy-error.log warn;
    add_header X-Content-Type-Options nosniff always;

    location /assets/ { try_files \$uri =404; expires 12h; }
    location / { try_files \$uri \$uri/ @application; }
    location @application { rewrite ^/(.*)\$ /index.php?page=\$1 last; }
    location = /index.php {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/html/index.php;
        fastcgi_param PHP_VALUE "upload_max_filesize=8M\\npost_max_size=10M";
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_read_timeout 30s;
    }
    # Do not allow PHP execution anywhere but the application front controller.
    location ~* \\.php(?:/|\$) { return 403; }
    location ~ /\\. { deny all; }
}
NGINX
ln -sfn /etc/nginx/sites-available/energy-ctf /etc/nginx/sites-enabled/energy-ctf
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
if [[ -n "$LAB_IP" ]]; then
  sed -i "/[[:space:]]${LAB_DOMAIN//./\\.}\$/d" /etc/hosts
  printf '%s %s\n' "$LAB_IP" "$LAB_DOMAIN" >> /etc/hosts
fi
log 'Memeriksa respons lokal...'
sleep 2
curl --fail --silent --show-error --max-time 15 -H "Host: $LAB_DOMAIN" http://127.0.0.1/ -o /dev/null || fail 'Website belum dapat diakses. Periksa docker logs energy-php56 dan /var/log/nginx/energy-error.log'
log 'INSTALASI SELESAI'
log "Website: http://${LAB_DOMAIN}/"
log "Webroot: ${WEB}"
log "Uploads: ${UP} (tidak dapat diakses langsung melalui HTTP)"
log 'Tambahkan mapping LAB_IP energy.co.id pada /etc/hosts client Kali.'
log 'PENTING: gunakan hanya jaringan VM terisolasi; PHP 5.6 sudah EOL.'
status
