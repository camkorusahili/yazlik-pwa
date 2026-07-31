# Yazlık Sitesi PWA — Sıfırdan Kurulum Rehberi

## 1. Supabase Projesi

1. https://supabase.com → New Project → Frankfurt (EU) bölgesi
2. Settings → API'den şunları not al:
   - **Project URL** → `VITE_SUPABASE_URL`
   - **anon public key** → `VITE_SUPABASE_ANON_KEY`

---

## 2. Veritabanı Kurulumu (SQL Editor'de SIRAYLA çalıştır)

1. `supabase/tum_sql/01_schema.sql` → tablolar ve triggerlar
2. `supabase/tum_sql/02_rls.sql` → güvenlik politikaları
3. `supabase/tum_sql/03_varsayilan_veriler.sql` → ayarlar ve örnek duyuru

---

## 3. Storage Bucket'ları (Dashboard'dan)

Storage → New bucket → **Public** işaretli olarak:
- `sakin-fotograflari`
- `haber-dosyalari`

Bucket'ları oluşturduktan sonra:
4. `supabase/tum_sql/04_storage.sql` → storage politikaları

---

## 4. Edge Functions (Dashboard → Edge Functions → Create)

Her biri için: fonksiyon adını tam yaz → kodu yapıştır → Deploy

| Fonksiyon Adı | Dosya |
|---|---|
| `toplu-hesap-olustur` | `supabase/functions/toplu-hesap-olustur/index.ts` |
| `basvuru-onayla` | `supabase/functions/basvuru-onayla/index.ts` |
| `sifre-sifirla` | `supabase/functions/sifre-sifirla/index.ts` |
| `hesap-baglantisi-kes` | `supabase/functions/hesap-baglantisi-kes/index.ts` |

> Bu fonksiyonlar için ekstra secret eklemeye gerek yok —
> SUPABASE_URL, ANON_KEY, SERVICE_ROLE_KEY otomatik tanımlı gelir.

---

## 5. Admin Kullanıcı

1. Authentication → Users → Add User → e-postanızla, "Auto Confirm" işaretli
2. Kullanıcının ID'sini kopyala
3. SQL Editor'de:

```sql
update auth.users
set raw_user_meta_data = jsonb_set(coalesce(raw_user_meta_data, '{}'), '{role}', '"admin"')
where id = 'BURAYA-USER-ID';
```

---

## 6. GitHub Repo

1. Yeni repo oluştur: **`yazlik-pwa`** (bu isim önemli, vite.config.js ile eşleşmeli)
2. Bu klasörün TÜM içeriğini yükle (`.github` gizli klasörü dahil)
3. Settings → Pages → Source: **GitHub Actions**
4. Settings → Secrets → Actions → 2 secret ekle:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
5. Push yap → Actions sekmesinde "Deploy PWA" yeşil tik alınca site hazır

---

## 7. PWA İkonları

`public/icons/` klasörüne ekle:
- `icon-192.png` (192×192)
- `icon-512.png` (512×512)
- Kök dizine: `favicon.ico`

---

## 8. İlk Kullanım

### Sakin Verisi Yükleme
- `sakin_ekleme_sablonu_v2.xlsx` şablonunu doldur
- CSV olarak kaydet → Supabase Table Editor → sakinler → Import CSV

### Hesap Açma
- Profil → 🔑 Sakin Hesaplarını Yönet → "Eksik Hesapları Oluştur"
- E-postası olanlar → rastgele şifre
- Sadece telefonu olanlar → telefon + son 6 hane şifre

---

## Özellikler

- 📋 Sakin rehberi (fotoğraf, konum durumu: yazlıkçı/devamlı/yok)
- 📢 Duyurular
- 📰 Haberler + yorum sistemi + dosya ekleri
- 🔧 Arıza/talep bildirimi + arşivleme
- 💰 Aidat takibi (toplu oluşturma, banka ekstresi eşleştirme)
- 👥 Sakin yönetimi (ekle/düzenle/sil, fotoğraf, detaylı profil)
- 🏛️ Yönetim kurulu + site çalışanları
- 👤 Self-servis kayıt + admin onay sistemi
- 🔑 Şifre sıfırlama, hesap bağlantısı kesme
- 📊 CSV export (yedekleme)
- 🔗 Çoklu daire desteği
