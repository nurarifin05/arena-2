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
install -d -o www-data -g www-data -m 0777 "$UP" "$UP/contact" "$UP/customer"
chmod 0777 "$UP" "$UP/contact" "$UP/customer"
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
