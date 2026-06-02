# Manuel VPS Deployment

Bu doküman Mini TeamFlow'u manuel VPS'e deploy etmek içindir.

## Önerilen yapı

Tek VPS üzerinde iki domain/subdomain kullan:

```txt
https://teamflow.example.com      -> Flutter Web
https://api-teamflow.example.com  -> Laravel API
```

> iPhone/Android kullanıcıları ilk etapta web olarak `teamflow.example.com` üzerinden dener.

## VPS gereksinimleri

- Ubuntu 22.04/24.04 önerilir
- Nginx
- PHP 8.3+ ve PHP-FPM
- Composer
- MySQL veya PostgreSQL
- Git
- Flutter SDK sadece build VPS'te alınacaksa gerekir. Alternatif: web build lokal alınıp VPS'e kopyalanabilir.

## Dizin önerisi

```txt
/var/www/mini-teamflow
  backend/
  web/
```

## Backend deploy

```bash
cd /var/www/mini-teamflow
git clone REPO_URL repo
cp -r repo/backend ./backend
cd backend
composer install --no-dev --optimize-autoloader
cp .env.production.example .env
php artisan key:generate
```

`.env` içinde özellikle şunları düzenle:

```txt
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api-teamflow.example.com
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=mini_teamflow
DB_USERNAME=mini_teamflow
DB_PASSWORD=strong_password
SANCTUM_STATEFUL_DOMAINS=teamflow.example.com,api-teamflow.example.com
SESSION_DOMAIN=.example.com
```

Migration/seed:

```bash
php artisan migrate --force
php artisan db:seed --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

Yetkiler:

```bash
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
```

## Flutter Web build

Lokal bilgisayarda veya VPS'te:

```bash
cd mobile
flutter build web --release --dart-define=API_BASE_URL=https://api-teamflow.example.com/api
```

Build çıktısını VPS'e koy:

```txt
/var/www/mini-teamflow/web
```

## Nginx — Laravel API

`/etc/nginx/sites-available/api-teamflow`:

```nginx
server {
    listen 80;
    server_name api-teamflow.example.com;

    root /var/www/mini-teamflow/backend/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

Aktifleştir:

```bash
ln -s /etc/nginx/sites-available/api-teamflow /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## Nginx — Flutter Web

`/etc/nginx/sites-available/teamflow`:

```nginx
server {
    listen 80;
    server_name teamflow.example.com;

    root /var/www/mini-teamflow/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Aktifleştir:

```bash
ln -s /etc/nginx/sites-available/teamflow /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## SSL

Certbot ile:

```bash
apt install certbot python3-certbot-nginx
certbot --nginx -d teamflow.example.com -d api-teamflow.example.com
```

## Güncelleme deploy akışı

```bash
cd /var/www/mini-teamflow/repo
git pull
rsync -a --delete backend/ /var/www/mini-teamflow/backend/
cd /var/www/mini-teamflow/backend
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
chown -R www-data:www-data storage bootstrap/cache
```

Flutter web için:

```bash
cd /var/www/mini-teamflow/repo/mobile
flutter build web --release --dart-define=API_BASE_URL=https://api-teamflow.example.com/api
rsync -a --delete build/web/ /var/www/mini-teamflow/web/
```

## Demo kullanıcıları

```txt
Admin:
admin@miniteamflow.local
password

Çalışan:
employee@miniteamflow.local
password
```

> Gerçek demo öncesi parolaları değiştir.
