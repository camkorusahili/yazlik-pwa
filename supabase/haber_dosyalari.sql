-- =============================================
-- HABER DOSYALARI
-- =============================================

create table public.haber_dosyalari (
  id uuid primary key default gen_random_uuid(),
  haber_id uuid references public.haberler(id) on delete cascade not null,
  dosya_adi text not null,        -- orijinal dosya adı
  dosya_url text not null,        -- Supabase Storage URL
  dosya_tipi text not null,       -- 'image' | 'pdf' | 'diger'
  storage_path text not null,     -- Storage'daki yol (silmek için)
  dosya_boyutu integer,           -- byte cinsinden
  created_at timestamptz default now()
);

alter table public.haber_dosyalari enable row level security;

create policy "Herkes haber dosyalarını görebilir" on public.haber_dosyalari
  for select using (auth.uid() is not null);

create policy "Sadece admin yönetir" on public.haber_dosyalari
  for all using (is_admin());

-- haberler tablosuna kapak_foto sütunu (ilk yüklenen foto otomatik kapak olur)
alter table public.haberler
  add column if not exists kapak_url text;
