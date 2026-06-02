# Faz 2 — Görev Sistemi

## Kapsam

Bu fazda Mini TeamFlow'un görev yönetimi MVP'si eklendi.

## Backend

### Yeni tablolar

- `tasks`
- `task_comments`

### Task alanları

```txt
id
title
description nullable
assigned_to
created_by
status: pending | in_progress | completed | cancelled
priority: low | medium | high
due_date nullable
completed_at nullable
created_at
updated_at
```

### Endpointler

```txt
GET    /api/tasks
POST   /api/tasks
GET    /api/tasks/{task}
PATCH  /api/tasks/{task}
PUT    /api/tasks/{task}
DELETE /api/tasks/{task}
POST   /api/tasks/{task}/comments
```

Kullanıcı yönetimi için:

```txt
GET  /api/users
POST /api/users
```

### Yetki kuralları

- Admin tüm görevleri görür.
- Admin aktif kullanıcılara görev atayabilir.
- Çalışan kendi görevlerini ve kendi oluşturduğu görevleri görür.
- Çalışan görev oluşturduğunda görev otomatik kendisine atanır.
- Çalışan kendi görev durumunu güncelleyebilir.
- Çalışan sadece kendi oluşturduğu görevin başlık/açıklama/öncelik gibi alanlarını düzenleyebilir.

## Flutter

- Alt navigasyona `Görevler` sekmesi eklendi.
- Görev listesi eklendi.
- Pull-to-refresh eklendi.
- Görev oluşturma bottom sheet'i eklendi.
- Admin için kullanıcı seçerek görev atama eklendi.
- Çalışan için görev otomatik kendisine atanır.
- Görev durum güncelleme eklendi.

## Demo kullanıcılar

```txt
Admin:
email: admin@miniteamflow.local
password: password

Çalışan:
email: employee@miniteamflow.local
password: password
```

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

- [x] Task migration/model/controller
- [x] Task comment altyapısı
- [x] User list/create endpointleri
- [x] Role göre task yetkilendirme
- [x] Flutter görev listesi
- [x] Flutter görev oluşturma
- [x] Flutter görev durum güncelleme
- [x] Backend testleri
- [x] Flutter analyze/test
