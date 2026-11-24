#!/usr/bin/env bash
# Energy Nasional — native Ubuntu 24.04 / 26.04 / Nginx / distro PHP-FPM.
# Training uploads are stored in a protected directory inside the web root and never executed.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
LAB_DOMAIN="${LAB_DOMAIN:-energy.co.id}"
LAB_IP="${LAB_IP:-192.168.36.81}"
LAB_SUBNET="${LAB_SUBNET:-192.168.36.0/24}"
ROOT=/opt/energy-ctf
WEB="$ROOT/www"
UP="$WEB/upload"
log(){ printf '[Energy Nasional] %s\n' "$*"; }
fail(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
status(){
  systemctl is-active nginx || true
  systemctl list-units --type=service --all "php*-fpm.service" --no-pager || true
  curl --noproxy '*' -sSI --max-time 10 --resolve "$LAB_DOMAIN:80:$LAB_IP" "http://$LAB_DOMAIN/" || true
  log "Webroot: $WEB | Access log: /var/log/nginx/access.log"
}
if [[ "${1:-}" == '--status' ]]; then status; exit 0; fi
[[ $EUID -eq 0 ]] || fail 'Jalankan sebagai root: sudo bash setup1.sh'
[[ "$LAB_DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]] || fail 'Domain tidak valid'
[[ "$LAB_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'IP tidak valid'
[[ "$LAB_SUBNET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] || fail 'Subnet tidak valid'
. /etc/os-release
[[ "$ID" == ubuntu && ( "$VERSION_ID" == 24.04 || "$VERSION_ID" == 26.04 ) ]] || fail 'Installer memerlukan Ubuntu 24.04 atau 26.04'
ip -4 -o addr show | awk '{split($4,a,"/");print a[1]}' | grep -Fxq "$LAB_IP" || fail "IP $LAB_IP belum terpasang pada interface VM"
trap 'printf "[ERROR] Gagal pada baris %s\n" "$LINENO" >&2' ERR
log 'Memasang dependensi native...'
apt-get update
apt-get install -y nginx php-fpm php-cli curl ca-certificates iproute2
PHP_PKG="$(dpkg-query -W -f='${Depends}' php-fpm | grep -oE 'php[0-9]+\.[0-9]+-fpm' | head -n1)"
[[ "$PHP_PKG" =~ ^php([0-9]+\.[0-9]+)-fpm$ ]] || fail 'Tidak dapat mendeteksi paket PHP-FPM default'
PHP_VERSION="${BASH_REMATCH[1]}"
PHP_SERVICE="php${PHP_VERSION}-fpm"
log "PHP-FPM terdeteksi: $PHP_VERSION"
apt-get install -y "php${PHP_VERSION}-cli"
# Stop an older Energy pool only if it exists, avoiding socket conflicts.
for old in /etc/php/*/fpm/pool.d/energy.conf; do
  [[ -f "$old" ]] || continue
  [[ "$old" == "/etc/php/$PHP_VERSION/fpm/pool.d/energy.conf" ]] && continue
  old_version="${old#/etc/php/}"; old_version="${old_version%%/*}"
  mv "$old" "$old.disabled.$(date +%s)"
  if systemctl is-active --quiet "php${old_version}-fpm"; then
    systemctl reload "php${old_version}-fpm"
  fi
done
# Stop only containers belonging to the previous Energy installation, if present.
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  for c in energy-ctf-nginx-1 energy-ctf-php-1 energy-php56; do
    if docker inspect "$c" >/dev/null 2>&1; then
      docker update --restart=no "$c" >/dev/null
      docker stop "$c" >/dev/null
    fi
  done
fi
PAYLOAD_DIR="$(mktemp -d)"
trap 'rm -rf "$PAYLOAD_DIR"' EXIT
base64 -d <<'ENERGY_APP_PAYLOAD' | tar -xz -C "$PAYLOAD_DIR"
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
ENERGY_APP_PAYLOAD
log 'Menyiapkan aplikasi dan penyimpanan lampiran...'
install -d -m 0755 "$ROOT" "$WEB"
cp -a "$PAYLOAD_DIR/app/." "$WEB/"
chown root:root "$WEB" "$WEB/index.php"
chown -R root:root "$WEB/assets"
chmod 0755 "$WEB"
chmod 0644 "$WEB/index.php"
find "$WEB/assets" -type d -exec chmod 0755 {} +
find "$WEB/assets" -type f -exec chmod 0644 {} +
install -d -o www-data -g www-data -m 0777 "$UP" "$UP/hubungi-kami" "$UP/cek-data-pelanggan"
chmod 0777 "$UP" "$UP/hubungi-kami" "$UP/cek-data-pelanggan"
touch "$UP/upload-events.log"
chown www-data:www-data "$UP/upload-events.log"
chmod 0640 "$UP/upload-events.log"
"php${PHP_VERSION}" -l "$WEB/index.php"
cat > "/etc/php/$PHP_VERSION/fpm/pool.d/energy.conf" <<'FPM'
[energy]
user = www-data
group = www-data
listen = /run/php/energy-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
php_admin_value[upload_max_filesize] = 8M
php_admin_value[post_max_size] = 10M
php_admin_value[max_execution_time] = 30
php_admin_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_flag[expose_php] = off
php_admin_value[open_basedir] = /opt/energy-ctf/www:/tmp
FPM
log 'Mengonfigurasi Nginx dan log SIEM...'
cat > /etc/nginx/conf.d/energy-upload-log.conf <<'LOGFORMAT'
log_format energy_upload escape=default '$remote_addr - $remote_user [$time_local] "$request" '
    '$status $body_bytes_sent "$http_referer" "$http_user_agent" '
    'upload_filename="$upstream_http_x_energy_upload_filename"';
LOGFORMAT
CONF=/etc/nginx/sites-available/energy-ctf
if [[ -f "$CONF" ]]; then cp -a "$CONF" "$CONF.bak.$(date +%s)"; fi
cat > "$CONF" <<NGINX
server {
    listen ${LAB_IP}:80;
    server_name ${LAB_DOMAIN};
    root ${WEB};
    index index.php;
    client_max_body_size 10m;
    access_log /var/log/nginx/access.log energy_upload;
    error_log /var/log/nginx/error.log warn;
    allow ${LAB_SUBNET};
    deny all;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Training-Lab Energy-CTF-local-only always;
    location /assets/ { try_files \$uri =404; expires 12h; }
    location = /upload { return 403; }
    location ^~ /upload/ { return 403; }
    location / { try_files \$uri \$uri/ @application; }
    location @application { rewrite ^/(.*)\$ /index.php?page=\$1 last; }
    location = /index.php {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root/index.php;
        fastcgi_pass unix:/run/php/energy-fpm.sock;
        fastcgi_read_timeout 30s;
        fastcgi_hide_header X-Energy-Upload-Filename;
    }
    location ~* \.php(?:/|\$) { return 403; }
    location ~ /\. { deny all; }
}
NGINX
ln -sfn "$CONF" /etc/nginx/sites-enabled/energy-ctf
# Remove only the distribution's default symlink, not other virtual hosts.
if [[ -L /etc/nginx/sites-enabled/default && "$(readlink -f /etc/nginx/sites-enabled/default)" == /etc/nginx/sites-available/default ]]; then
  rm /etc/nginx/sites-enabled/default
fi
"php-fpm${PHP_VERSION}" -t
nginx -t
systemctl enable "$PHP_SERVICE" nginx
systemctl restart "$PHP_SERVICE"
systemctl restart nginx
# Replace only the domain token in /etc/hosts, retaining other aliases.
cp -a /etc/hosts "/etc/hosts.energy.bak.$(date +%s)"
awk -v domain="$LAB_DOMAIN" -v ip="$LAB_IP" '{ if ($1 ~ /^#/ || NF<2) {print; next} line=$1; n=0; for(i=2;i<=NF;i++){if($i ~ /^#/){for(j=i;j<=NF;j++) line=line " " $j;break} if($i!=domain){line=line " " $i;n++}} if(n) print line } END {print ip " " domain}' /etc/hosts > "$PAYLOAD_DIR/hosts"
cat "$PAYLOAD_DIR/hosts" > /etc/hosts
log 'Health check...'
for route in / /profil /hubungi-kami /cek-data-pelanggan; do
  curl --noproxy '*' --fail --silent --show-error --max-time 15 --resolve "$LAB_DOMAIN:80:$LAB_IP" "http://$LAB_DOMAIN$route" -o /dev/null || fail "Health check gagal: $route; periksa /var/log/nginx/error.log"
done
log "INSTALASI SELESAI: http://$LAB_DOMAIN/ ($LAB_IP)"
log "Access log: /var/log/nginx/access.log"
log "Error log: /var/log/nginx/error.log"
log "Upload events: $UP/upload-events.log"
status
