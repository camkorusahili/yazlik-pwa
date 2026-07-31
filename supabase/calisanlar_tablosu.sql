-- =============================================
-- ÇALIŞANLAR TABLOSU + YÖNETİM ROZET
-- =============================================

-- Site çalışanları (sakin değil)
create table public.calisanlar (
  id uuid primary key default gen_random_uuid(),
  ad text not null,
  soyad text,
  gorev text not null,  -- teknisyen, bahçıvan, güvenlik vb.
  telefon text,
  telefon2 text,
  aciklama text,
  aktif boolean default true,
  created_at timestamptz default now()
);

alter table public.calisanlar enable row level security;

create policy "Herkes çalışanları görebilir" on public.calisanlar
  for select using (auth.uid() is not null);

create policy "Sadece admin çalışan yönetir" on public.calisanlar
  for all using (is_admin());

-- Sakinler tablosuna yönetim üyesi alanı ekle
alter table public.sakinler
  add column if not exists yonetim_uyesi boolean default false,
  add column if not exists yonetim_gorevi text;  -- başkan, veznedar, üye vb.
