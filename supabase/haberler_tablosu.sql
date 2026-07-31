-- =============================================
-- HABERLER VE YORUMLAR TABLOLARI
-- =============================================

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

create table public.yorumlar (
  id uuid primary key default gen_random_uuid(),
  haber_id uuid references public.haberler(id) on delete cascade not null,
  sakin_id uuid references public.sakinler(id) on delete cascade not null,
  icerik text not null,
  created_at timestamptz default now()
);

alter table public.haberler enable row level security;
alter table public.yorumlar enable row level security;

-- Haberler politikaları
create policy "Herkes haberleri görebilir" on public.haberler
  for select using (auth.uid() is not null and yayinda = true);

create policy "Admin haber yönetir" on public.haberler
  for all using (is_admin());

-- Yorumlar politikaları
create policy "Herkes yorumları görebilir" on public.yorumlar
  for select using (auth.uid() is not null);

create policy "Sakin yorum yapabilir" on public.yorumlar
  for insert with check (
    sakin_id in (select id from public.sakinler where user_id = auth.uid())
  );

create policy "Sakin kendi yorumunu silebilir" on public.yorumlar
  for delete using (
    sakin_id in (select id from public.sakinler where user_id = auth.uid())
    or is_admin()
  );

-- updated_at trigger
create trigger haberler_updated_at
  before update on public.haberler
  for each row execute function public.handle_updated_at();
