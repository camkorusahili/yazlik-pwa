-- =============================================
-- AYARLAR TABLOSU
-- =============================================
create table public.ayarlar (
  anahtar text primary key,
  deger text not null,
  aciklama text,
  updated_at timestamptz default now()
);

alter table public.ayarlar enable row level security;

create policy "Herkes okuyabilir" on public.ayarlar
  for select using (auth.uid() is not null);

create policy "Sadece admin yazabilir" on public.ayarlar
  for all using (is_admin());

-- Varsayılan değerler
insert into public.ayarlar (anahtar, deger, aciklama) values
  ('aidat_tutari', '500', 'Aylık aidat tutarı (TL)'),
  ('aidat_yili',   '2026', 'Aktif aidat yılı');
