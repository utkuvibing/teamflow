# TeamFlow

Şirket içi kullanım için geliştirilmiş mini ekip uygulaması: görev yönetimi, günlük check-in, takvim/etkinlik, dashboard özeti ve uygulama içi bildirimler. Mobil istemci Flutter, backend Laravel REST API üzerinden konuşur.

## Teknoloji yığını

| Katman | Teknoloji | Not |
|--------|-----------|-----|
| Mobil | **Flutter** (Dart 3.12+) | Tek dosyada UI + API istemcisi (`mobile/lib/main.dart`) |
| HTTP | `http`, `shared_preferences` | Bearer token saklama ve REST çağrıları |
| Backend | **Laravel 13** (PHP 8.3+) | `backend/` altında API-only kullanım |
| Kimlik doğrulama | **Laravel Sanctum** | Mobil için personal access token |
| Veritabanı | SQLite (varsayılan), MySQL veya PostgreSQL | `.env` ile seçilir |
| Test | PHPUnit (backend), `flutter test` (mobil) | Feature testler `backend/tests/Feature/` |

Ayrı web admin paneli yok; tüm yönetim ve kullanım mobil uygulama üzerinden yapılır.

## Proje yapısı

```text
.
├── backend/          # Laravel API (routes/api.php, Models, Controllers)
├── mobile/           # Flutter uygulaması
└── docs/             # Faz dokümantasyonu (geliştirme notları)
```

## Nasıl çalışır?

### Genel mimari

```text
┌─────────────┐     HTTPS/HTTP JSON      ┌──────────────────┐
│   Flutter   │  Authorization: Bearer   │  Laravel API     │
│   (mobile)  │ ◄──────────────────────► │  /api/*          │
└─────────────┘                          └────────┬─────────┘
                                                  │
                                          ┌───────▼────────┐
                                          │  Veritabanı    │
                                          └────────────────┘
```

Mobil uygulama doğrudan Laravel’in `/api` rotalarına istek atar. Oturum tarayıcı çerezi değil; Sanctum ile üretilen **Bearer token** kullanılır.

### Kimlik doğrulama akışı

1. Kullanıcı `POST /api/login` ile e-posta ve şifre gönderir.
2. Backend kullanıcıyı doğrular, `is_active` değilse 403 döner.
3. Başarılı girişte `data.token` ve `data.user` döner; Flutter token’ı `shared_preferences` ile saklar.
4. Uygulama açılışında `AuthGate` saklanan token ile `GET /api/me` çağırır; geçersizse token silinir ve login ekranı gösterilir.
5. Çıkışta `POST /api/logout` ile mevcut token silinir, yerel depolama temizlenir.

Korumalı tüm endpoint’ler `auth:sanctum` middleware grubundadır.

### API yanıt formatı

Tüm JSON yanıtlar tutarlı bir zarf kullanır:

```json
{
  "success": true,
  "message": "İşlem açıklaması",
  "data": { }
}
```

Hata durumlarında `success: false` ve uygun HTTP kodu döner; `api/*` isteklerinde Laravel JSON hata gövdesi üretir.

### Roller ve yetkiler

| Rol | Değer | Yetkiler (özet) |
|-----|-------|------------------|
| Admin | `admin` | Tüm görevleri görür; kullanıcı ekler (`GET/POST /api/users`); check-in listesinde **yapmayanları** görür |
| Çalışan | `employee` | Kendine atanan veya kendi oluşturduğu görevler; kendi check-in’leri; kendi + paylaşılan etkinlikler |

**Görevler:** Admin herkese atayabilir. Çalışan görev oluşturduğunda atama otomatik kendisine yapılır. Liste ve dashboard sorguları role göre filtrelenir.

**Check-in:** Zorunlu değil. Çalışan günde bir kez `POST /api/check-ins/today` ile durum bildirir (`working`, `remote`, `leave` vb.). Admin aynı gün için kimlerin yapmadığını `missing_users` alanından görür.

**Takvim:** Her kullanıcı kendi etkinliğini ekler (`POST /api/events`). `is_private` false olan etkinlikler ekip tarafından görülebilir; admin tüm etkinlikleri görür.

**Bildirimler:** Örneğin görev atandığında `notifications` tablosuna kayıt düşer; mobil `GET /api/notifications` ile listeler, `PATCH .../read` ile okundu işaretler.

### Mobil ekran mantığı

Giriş sonrası `HomeScreen` alt navigasyon ile dört sekme sunar:

- **Panel** — `GET /api/dashboard/summary` (görev durumları, yaklaşan teslim, bugünkü etkinlik/check-in sayıları)
- **Görevler** — CRUD + yorum (`/api/tasks`, `/api/tasks/{id}/comments`)
- **Takvim** — Etkinlik listesi ve oluşturma
- **Check-in** — Günlük kayıt ve (admin için) eksik kullanıcı listesi

API taban adresi derleme zamanında verilir:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8010/api', // Android emülatör → host makine
);
```

### Veri modeli (özet)

- **users** — `role`, `position`, `is_active`
- **tasks** — atama, durum (`pending` … `cancelled`), öncelik, `due_date`
- **task_comments** — göreve bağlı yorumlar
- **check_ins** — kullanıcı + `work_date` (günde bir kayıt)
- **events** — `starts_at`, `ends_at`, `is_private`
- **notifications** — kullanıcıya özel uygulama bildirimleri
- **personal_access_tokens** — Sanctum token’ları

## Kurulum

### Gereksinimler

- PHP **8.3+**, [Composer](https://getcomposer.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.12+**
- İsteğe bağlı: MySQL 8+ veya PostgreSQL (geliştirmede SQLite yeterli)

### 1. Backend

```bash
cd backend
composer install
cp .env.example .env   # Windows: copy .env.example .env
php artisan key:generate
```

Veritabanı (geliştirme için SQLite varsayılandır):

```env
DB_CONNECTION=sqlite
```

MySQL kullanacaksanız `.env` içinde `DB_CONNECTION=mysql` ve host/database/kullanıcı bilgilerini doldurun; veritabanını oluşturmayı unutmayın.

```bash
php artisan migrate
php artisan db:seed
php artisan serve --host=127.0.0.1 --port=8010
```

API adresi: `http://127.0.0.1:8010/api`

### 2. Mobil

```bash
cd mobile
flutter pub get
```

Hedef platforma göre API adresi ile çalıştırın:

| Ortam | Komut |
|-------|--------|
| Android emülatör | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010/api` |
| Windows masaüstü | `flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8010/api` |
| Fiziksel cihaz (aynı ağ) | Bilgisayarın LAN IP’si: `http://192.168.x.x:8010/api` |

Backend farklı portta çalışıyorsa URL’deki portu buna göre değiştirin.

### Demo hesaplar (seed)

| E-posta | Şifre | Rol |
|---------|-------|-----|
| `admin@miniteamflow.local` | `password` | admin |
| `admin2@miniteamflow.local` | `password` | admin |
| `employee@miniteamflow.local` | `password` | employee |
| `employee2@miniteamflow.local` | `password` | employee |

Gerçek ortamda bu parolaları mutlaka değiştirin.

### Testleri çalıştırma

```bash
cd backend && php artisan test
cd mobile && flutter analyze && flutter test
```

## API uç noktaları (özet)

| Metot | Yol | Açıklama |
|-------|-----|----------|
| POST | `/api/login` | Giriş (public) |
| GET | `/api/me` | Oturumlu kullanıcı |
| POST | `/api/logout` | Çıkış |
| GET/POST | `/api/users` | Kullanıcı listesi / ekleme (admin) |
| GET | `/api/dashboard/summary` | Panel özeti |
| CRUD | `/api/tasks` | Görevler |
| POST | `/api/tasks/{task}/comments` | Yorum |
| GET/POST | `/api/check-ins`, `/api/check-ins/today` | Liste / bugünkü kayıt |
| CRUD | `/api/events` | Etkinlikler (`show` yok) |
| GET/PATCH | `/api/notifications`, `.../read` | Bildirimler |

Tam rota tanımı: `backend/routes/api.php`.

## Ürün kararları (kısa)

- Tek ekip; departman yok.
- Admin ve çalışan görev oluşturabilir; kullanıcı ekleme sadece admin.
- Check-in zorunlu değil; admin eksikleri görür.
- Arayüz dili Türkçe; Material 3 tabanlı modern görünüm.
- İleride ayrı web admin paneli eklenebilir; şu an yalnızca mobil.
