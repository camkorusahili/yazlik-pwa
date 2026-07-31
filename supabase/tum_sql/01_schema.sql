-- =============================================
-- 1. ANA ŞEMA - Tüm tablolar, RLS, fonksiyonlar
-- =============================================

-- Admin kontrolü
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from auth.users
    where id = auth.uid()
    and raw_user_meta_data->>'role' = 'admin'
  );
$$ language sql security definer;

-- updated_at trigger fonksiyonu
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- SAKİNLER
create table public.sakinler (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  daire text not null unique,
  daire_no integer,
  konum integer default 0,
  adi text not null,
  soyadi text not null,
  tc_kimlik text,
  es_adi text,
  baba_adi text,
  anne_adi text,
  tel1 text,
  ceptel text,
  ceptel2 text,
  email text,
  ev_adresi text,
  aciklama text,
  fotograf_url text,
  plaka text,
  cocuk_sayisi integer,
  dogum_tarihi date,
  dogum_yeri text,
  meslek text,
  yonetim_uyesi boolean default false,
  yonetim_gorevi text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- DUYURULAR
create table public.duyurular (
  id uuid primary key default gen_random_uuid(),
  baslik text not null,
  icerik text not null,
  onem text default 'normal' check (onem in ('normal', 'onemli', 'acil')),
  yayinda boolean default true,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- AİDATLAR
create table public.aidatlar (
  id uuid primary key default gen_random_uuid(),
  sakin_id uuid references public.sakinler(id) on delete cascade,
  yil integer not null,
  ay integer not null check (ay between 1 and 12),
  tutar numeric(10,2) not null default 0,
  odendi boolean default false,
  odeme_tarihi date,
  aciklama text,
  created_at timestamptz default now(),
  unique(sakin_id, yil, ay)
);

-- TALEPLER
create table public.talepler (
  id uuid primary key default gen_random_uuid(),
  sakin_id uuid references public.sakinler(id) on delete cascade,
  kategori text not null check (kategori in ('elektrik','su','asansor','bahce','guvenlik','diger')),
  baslik text not null,
  aciklama text,
  durum text default 'bekliyor' check (durum in ('bekliyor','inceleniyor','tamamlandi','iptal')),
  oncelik text default 'normal' check (oncelik in ('dusuk','normal','yuksek','acil')),
  arsivlendi boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- BAŞVURULAR
create table public.basvurular (
  id uuid primary key default gen_random_uuid(),
  adi text not null,
  soyadi text not null,
  daire_no integer,
  daire text,
  telefon text not null,
  durum text default 'bekliyor' check (durum in ('bekliyor', 'onaylandi', 'reddedildi')),
  eslesen_sakin_id uuid references public.sakinler(id) on delete set null,
  not_admin text,
  created_at timestamptz default now(),
  islenme_tarihi timestamptz
);

-- AYARLAR
create table public.ayarlar (
  anahtar text primary key,
  deger text not null,
  aciklama text,
  updated_at timestamptz default now()
);

-- ÇALIŞANLAR
create table public.calisanlar (
  id uuid primary key default gen_random_uuid(),
  adi text not null,
  soyadi text,
  gorev text not null,
  telefon text,
  telefon2 text,
  email text,
  aktif boolean default true,
  sira integer default 0,
  created_at timestamptz default now()
);

-- HABERLER
create table public.haberler (
  id uuid primary key default gen_random_uuid(),
  baslik text not null,
  icerik text not null,
  kapak_url text,
  yayinda boolean default true,
  created_by uuid references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- HABER DOSYALARI
create table public.haber_dosyalari (
  id uuid primary key default gen_random_uuid(),
  haber_id uuid references public.haberler(id) on delete cascade not null,
  dosya_adi text not null,
  dosya_url text not null,
  dosya_tipi text not null,
  storage_path text not null,
  dosya_boyutu integer,
  created_at timestamptz default now()
);

-- YORUMLAR
create table public.yorumlar (
  id uuid primary key default gen_random_uuid(),
  haber_id uuid references public.haberler(id) on delete cascade not null,
  sakin_id uuid references public.sakinler(id) on delete cascade not null,
  icerik text not null,
  created_at timestamptz default now()
);

-- PUSH ABONELİKLERİ (ilerisi için hazır)
create table public.push_abonelikleri (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz default now()
);

-- =============================================
-- TRIGGERLAR
-- =============================================
create trigger sakinler_updated_at before update on public.sakinler for each row execute function public.handle_updated_at();
create trigger talepler_updated_at before update on public.talepler for each row execute function public.handle_updated_at();
create trigger haberler_updated_at before update on public.haberler for each row execute function public.handle_updated_at();
create trigger ayarlar_updated_at before update on public.ayarlar for each row execute function public.handle_updated_at();
