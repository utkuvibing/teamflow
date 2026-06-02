# Faz 1 — Temel Kurulum

## Amaç

Mini TeamFlow projesinin Laravel backend ve Flutter mobil temelini kurmak.

## Kapsam

### Backend

- Laravel projesi oluşturma
- Database bağlantısı
- Laravel Sanctum kurulumu
- Auth endpointleri
- Kullanıcı rol alanı
- İlk admin seed'i
- Standart API response yapısı

### Mobil

- Flutter projesi oluşturma
- Login ekranı
- Splash/auth kontrol akışı
- Token saklama
- `/me` endpointinden kullanıcı bilgisi çekme
- Role göre yönlendirme temeli

## Faz 1 Endpointleri

```txt
POST /api/login
POST /api/logout
GET  /api/me
```

Admin kullanıcı yönetimi Faz 2 öncesi eklenecek:

```txt
GET  /api/users
POST /api/users
```

## Kullanıcı Modeli

```txt
id
name
email
password
role: admin | employee
position nullable
is_active boolean default true
created_at
updated_at
```

## Auth Akışı

1. Kullanıcı email/şifre ile login olur.
2. Backend Sanctum token döner.
3. Flutter token'ı local saklar.
4. App açılışında token varsa `/me` çağrılır.
5. Kullanıcı rolüne göre admin veya employee dashboard'a yönlenir.

## İlk Admin

Seed ile oluşturulacak:

```txt
name: Admin
email: admin@miniteamflow.local
password: password
role: admin
```

> Gerçek kullanıma geçmeden önce parola değiştirilmeli.

## Kurulum Komutları

Bu repoda araçlar lokal olarak `.tools/` altında hazırlandı ve `.gitignore` ile dışarıda bırakıldı. Proje scaffold'u oluşturuldu. Temiz bir makinede kurulum gerektiğinde şu komutlar referans alınabilir:

```bash
composer create-project laravel/laravel backend
cd backend
composer require laravel/sanctum
php artisan sanctum:install
php artisan migrate
```

```bash
flutter create mobile
cd mobile
flutter pub add http shared_preferences
```

## Çalıştırma

Backend:

```bash
cd backend
../.tools/php/php.exe artisan serve --host=127.0.0.1 --port=8010
```

Flutter:

```bash
cd mobile
../.tools/flutter/bin/flutter.bat run --dart-define=API_BASE_URL=http://10.0.2.2:8010/api
```

Windows desktop üzerinden çalıştırırken API URL için şunu kullan:

```bash
../.tools/flutter/bin/flutter.bat run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8010/api
```

## Tamamlanma Kriterleri

- [x] Backend ayağa kalkıyor.
- [x] Migration'lar çalışıyor.
- [x] Seed ile admin oluşuyor.
- [x] Login/logout/me endpointleri çalışıyor.
- [x] Flutter login ekranı oluşturuldu.
- [x] Token saklama eklendi.
- [x] App tekrar açıldığında auth state kontrol ediliyor.
- [x] Backend testleri geçiyor.
- [x] Flutter analyze/test geçiyor.
