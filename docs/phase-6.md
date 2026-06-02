# Faz 6 — UI/UX İyileştirme + Bildirimler

## Kapsam

Bu fazda Mini TeamFlow MVP'sine uygulama içi bildirim altyapısı ve bildirim ekranı eklendi.

## Backend

### Yeni tablo

- `notifications`

### Notification alanları

```txt
id
user_id
title
body nullable
type default info
read_at nullable
created_at
updated_at
```

### Endpointler

```txt
GET   /api/notifications
PATCH /api/notifications/{notification}/read
```

### Bildirim üretimi

- Admin başka bir kullanıcıya görev atadığında atanan kullanıcıya `task_assigned` bildirimi oluşturulur.

### Yetki kuralları

- Kullanıcı sadece kendi bildirimlerini listeler.
- Kullanıcı sadece kendi bildirimini okundu işaretleyebilir.

## Flutter

- AppBar'a `Bildirimler` butonu eklendi.
- Bildirimler ekranı eklendi.
- Okunmamış bildirimler farklı arka planla gösterilir.
- Bildirime dokununca okundu olarak işaretlenir.
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

- [x] Bildirim migration/model/controller
- [x] Bildirim listeleme endpointi
- [x] Okundu işaretleme endpointi
- [x] Görev atama bildirimi
- [x] Flutter bildirim ekranı
- [x] Backend testleri
- [x] Flutter analyze/test
