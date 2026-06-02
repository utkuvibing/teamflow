# Faz 3 — Günlük Check-in

## Kapsam

Bu fazda günlük çalışma durumu/check-in MVP'si eklendi.

## Backend

### Yeni tablo

- `check_ins`

### Check-in alanları

```txt
id
user_id
work_date
status: available | remote | leave | sick
note nullable
checked_in_at
created_at
updated_at
```

Her kullanıcı için günde tek kayıt tutulur; aynı gün tekrar check-in yapılırsa kayıt güncellenir.

### Endpointler

```txt
GET  /api/check-ins
POST /api/check-ins/today
```

### Yetki kuralları

- Çalışan kendi günlük check-in kaydını oluşturabilir/güncelleyebilir.
- Çalışan check-in listesinde sadece kendi kaydını görür.
- Admin ilgili günün tüm check-in kayıtlarını görür.
- Admin aynı cevapta check-in yapmayan aktif kullanıcıları `missing_users` olarak görür.

## Flutter

- Alt navigasyondaki `Check-in` sekmesi aktif hale getirildi.
- Kullanıcı bugünkü durumunu hızlı butonlarla seçebilir:
  - Ofisteyim
  - Uzaktan
  - İzinli
  - Raporlu
- Check-in yapanlar listesi eklendi.
- Admin için check-in yapmayanlar listesi eklendi.
- Pull-to-refresh eklendi.

## Kontrol

```bash
cd backend
../.tools/php/php.exe artisan test
```

```bash
cd mobile
../.tools/flutter/bin/flutter.bat analyze
../.tools/flutter/bin/flutter.bat test
```

## Durum

- [x] Check-in migration/model/controller
- [x] Günlük tekil check-in kaydı
- [x] Admin için eksik check-in listesi
- [x] Flutter check-in ekranı
- [x] Backend testleri
- [x] Flutter analyze/test
