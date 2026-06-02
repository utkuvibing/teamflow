# Faz 5 — Dashboard/Raporlar

## Kapsam

Bu fazda Mini TeamFlow'a görev, check-in ve etkinlik verilerini özetleyen dashboard/rapor MVP'si eklendi.

## Backend

### Yeni endpoint

```txt
GET /api/dashboard/summary
```

### Dönen özetler

```txt
tasks.total
tasks.pending
tasks.in_progress
tasks.completed
tasks.cancelled
tasks.high_priority
tasks.due_soon
check_ins.today_count
events.today_count
events.upcoming_count
```

### Yetki/veri kapsamı

- Admin tüm görev, etkinlik ve check-in özetlerini görür.
- Çalışan sadece erişebildiği görev/etkinlikleri ve kendi check-in özetini görür.

## Flutter

- Panel sekmesi gerçek dashboard verisiyle güncellendi.
- Toplam görev, tamamlanan görev, yaklaşan/acil görev ve bugünkü etkinlik kartları eklendi.
- Bugünkü check-in özeti eklendi.
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

- [x] Dashboard summary endpointi
- [x] Role göre rapor kapsamı
- [x] Backend dashboard testi
- [x] Flutter dashboard kartları
- [x] Backend testleri
- [x] Flutter analyze/test
