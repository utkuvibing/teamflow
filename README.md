# TeamFlow

Flutter mobil istemci + Laravel REST API ile çalışan ekip uygulaması: görevler, günlük check-in, takvim ve uygulama içi bildirimler.

## Teknoloji

| Katman | Teknoloji |
|--------|-----------|
| Mobil | Flutter (Dart 3.12+), `http`, `shared_preferences` |
| Backend | Laravel 13 (PHP 8.3+), Sanctum |
| Veritabanı | SQLite (geliştirme), MySQL veya PostgreSQL |

## Proje yapısı

```text
backend/   # API
mobile/    # Flutter uygulaması
```

Mobil uygulama JSON REST API’ye **Bearer token** ile bağlanır. Giriş `POST /api/login`; korumalı rotalar Sanctum ile çalışır. Yanıtlar `{ success, message, data }` formatındadır.

**Roller:** `admin` (kullanıcı yönetimi, tüm görevler, check-in özeti) ve `employee` (kendi görevleri, check-in, etkinlikler).

## Kurulum

### Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

Geliştirmede varsayılan veritabanı SQLite’tır (`.env.example`). Production için `.env` içinde kendi DB ve `APP_KEY` değerlerinizi kullanın.

İlk kullanıcıyı yerelde kendiniz oluşturun (Tinker, seeder veya admin akışı). **Örnek hesap veya şifreleri repoya koymayın.**

### Mobil

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=<backend-url>/api
```

`API_BASE_URL`, backend’in erişilebilir adresidir (emülatör, cihaz veya production URL’ine göre değişir).

### Test

```bash
cd backend && php artisan test
cd mobile && flutter analyze && flutter test
```

## Lisans ve güvenlik

Public repoda `.env`, gerçek kimlik bilgileri ve production URL’leri paylaşılmamalıdır. API detayları için `backend/routes/api.php` dosyasına bakın.
