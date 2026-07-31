-- =============================================
-- SITE EKİBİ
-- =============================================

-- Çalışanlar tablosu (sakin değil, sisteme giriş yapmaz)
create table public.calisanlar (
  id uuid primary key default gen_random_uuid(),
  adi text not null,
  soyadi text,
  gorev text not null,  -- Teknisyen, Bahçıvan, Güvenlik vb.
  telefon text,
  telefon2 text,
  email text,
  aktif boolean default true,
  sira integer default 0,  -- Listeleme sırası
  created_at timestamptz default now()
);

alter table public.calisanlar enable row level security;

create policy "Herkes çalışanları görebilir" on public.calisanlar
  for select using (auth.uid() is not null and aktif = true);

create policy "Sadece admin yönetir" on public.calisanlar
  for all using (is_admin());

-- Sakinler tablosuna yönetim üyeliği sütunu ekle
alter table public.sakinler
  add column if not exists yonetim_uyesi boolean default false,
  add column if not exists yonetim_gorevi text;  -- Başkan, Veznedar, Üye vb.

-- Örnek çalışan verisi
insert into public.calisanlar (adi, soyadi, gorev, telefon, sira) values
  ('Site', 'Teknisyeni', 'Teknisyen', '0532 000 00 01', 1),
  ('Site', 'Bahçıvanı',  'Bahçıvan',  '0532 000 00 02', 2);
