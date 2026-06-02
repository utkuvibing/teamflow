# Faz 4 — Takvim/Etkinlik

## Kapsam

Bu fazda Mini TeamFlow'a takvim/etkinlik MVP'si eklendi.

## Backend

### Yeni tablo

- `events`

### Event alanları

```txt
id
title
description nullable
user_id
starts_at
ends_at nullable
is_private boolean default false
created_at
updated_at
```

### Endpointler

```txt
GET    /api/events
POST   /api/events
PATCH  /api/events/{event}
PUT    /api/events/{event}
DELETE /api/events/{event}
```

### Yetki kuralları

- Kullanıcı kendi kişisel etkinliğini oluşturabilir.
- Çalışan kendi etkinliklerini ve herkese açık etkinlikleri görür.
- Çalışan başkasının özel etkinliğini göremez.
- Kullanıcı sadece kendi etkinliğini düzenleyip silebilir.
- Admin tüm etkinlikleri görebilir, düzenleyebilir ve silebilir.

## Flutter

- Alt navigasyondaki `Takvim` sekmesi aktif hale getirildi.
- Etkinlik listesi eklendi.
- Etkinlik oluşturma bottom sheet'i eklendi.
- Tarih/saat seçimi eklendi.
- Özel etkinlik seçeneği eklendi.
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

- [x] Event migration/model/controller
- [x] Etkinlik listeleme/oluşturma/güncelleme/silme endpointleri
- [x] Özel etkinlik görünürlük kuralı
- [x] Flutter takvim ekranı
- [x] Flutter etkinlik oluşturma
- [x] Backend testleri
- [x] Flutter analyze/test
