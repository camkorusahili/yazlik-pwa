-- =============================================
-- BAŞVURULAR TABLOSU (Self-signup, admin onaylı)
-- =============================================

create table public.basvurular (
  id uuid primary key default gen_random_uuid(),
  adi text not null,
  soyadi text not null,
  daire_no integer,
  daire text,
  telefon text not null,
  durum text default 'bekliyor' check (durum in ('bekliyor', 'onaylandi', 'reddedildi')),
  eslesen_sakin_id uuid references public.sakinler(id), -- admin hangi sakin kaydına eşleştirdi
  not_admin text, -- admin'in red/onay notu
  created_at timestamptz default now(),
  islenme_tarihi timestamptz
);

alter table public.basvurular enable row level security;

-- Herkes (giriş yapmamış kullanıcı dahil) başvuru oluşturabilir
create policy "Herkes başvuru oluşturabilir" on public.basvurular
  for insert with check (true);

-- Sadece admin görebilir / yönetebilir
create policy "Sadece admin başvuruları görebilir" on public.basvurular
  for select using (is_admin());

create policy "Sadece admin başvuru güncelleyebilir" on public.basvurular
  for update using (is_admin());

create policy "Sadece admin başvuru silebilir" on public.basvurular
  for delete using (is_admin());
