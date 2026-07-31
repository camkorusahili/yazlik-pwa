# Supabase Kurulum Adımları

## 1. Proje oluştur
https://supabase.com → "New Project" → isim ver → şifre belirle → bölge: Frankfurt (EU)

## 2. Schema çalıştır
Supabase Dashboard → SQL Editor → schema.sql içeriğini yapıştır → Run

## 3. Örnek veri ekle (isteğe bağlı)
SQL Editor → seed.sql içeriğini yapıştır → Run

## 4. Admin kullanıcı oluştur
Authentication → Users → "Invite User" ile e-posta gönder
Sonra SQL Editor'da şu komutu çalıştır (kendi user id'ni yaz):

```sql
update auth.users
set raw_user_meta_data = jsonb_set(
  coalesce(raw_user_meta_data, '{}'),
  '{role}',
  '"admin"'
)
where id = 'BURAYA-USER-ID-YAZ';
```

## 5. .env için bilgileri al
Settings → API:
- Project URL → VITE_SUPABASE_URL
- anon public key → VITE_SUPABASE_ANON_KEY

## 6. Storage bucket oluştur (fotoğraflar için)
Storage → New bucket → "fotograflar" → Public: kapalı
