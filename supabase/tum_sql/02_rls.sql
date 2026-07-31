-- =============================================
-- 2. ROW LEVEL SECURITY POLİTİKALARI
-- =============================================

alter table public.sakinler enable row level security;
alter table public.duyurular enable row level security;
alter table public.aidatlar enable row level security;
alter table public.talepler enable row level security;
alter table public.basvurular enable row level security;
alter table public.ayarlar enable row level security;
alter table public.calisanlar enable row level security;
alter table public.haberler enable row level security;
alter table public.haber_dosyalari enable row level security;
alter table public.yorumlar enable row level security;
alter table public.push_abonelikleri enable row level security;

-- SAKİNLER
create policy "Herkes sakinleri görebilir" on public.sakinler for select using (auth.uid() is not null);
create policy "Sakin kendi kaydını güncelleyebilir" on public.sakinler for update using (user_id = auth.uid() or is_admin());
create policy "Sadece admin ekleyebilir" on public.sakinler for insert with check (is_admin());
create policy "Sadece admin silebilir" on public.sakinler for delete using (is_admin());

-- DUYURULAR
create policy "Herkes duyuruları görebilir" on public.duyurular for select using (auth.uid() is not null and yayinda = true);
create policy "Admin duyuru yönetir" on public.duyurular for all using (is_admin());

-- AİDATLAR
create policy "Sakin kendi aidatlarını görür" on public.aidatlar for select using (sakin_id in (select id from public.sakinler where user_id = auth.uid()) or is_admin());
create policy "Admin aidat yönetir" on public.aidatlar for all using (is_admin());

-- TALEPLER
create policy "Sakin kendi taleplerini görür" on public.talepler for select using (sakin_id in (select id from public.sakinler where user_id = auth.uid()) or is_admin());
create policy "Sakin talep oluşturabilir" on public.talepler for insert with check (sakin_id in (select id from public.sakinler where user_id = auth.uid()));
create policy "Sakin/admin talep güncelleyebilir" on public.talepler for update using (sakin_id in (select id from public.sakinler where user_id = auth.uid()) or is_admin());

-- BAŞVURULAR
create policy "Herkes başvuru oluşturabilir" on public.basvurular for insert with check (true);
create policy "Admin başvuruları görebilir" on public.basvurular for select using (is_admin());
create policy "Admin başvuru güncelleyebilir" on public.basvurular for update using (is_admin());
create policy "Admin başvuru silebilir" on public.basvurular for delete using (is_admin());

-- AYARLAR
create policy "Herkes okuyabilir" on public.ayarlar for select using (auth.uid() is not null);
create policy "Admin yazabilir" on public.ayarlar for all using (is_admin());

-- ÇALIŞANLAR
create policy "Herkes çalışanları görebilir" on public.calisanlar for select using (auth.uid() is not null and aktif = true);
create policy "Admin çalışan yönetir" on public.calisanlar for all using (is_admin());

-- HABERLER
create policy "Herkes haberleri görebilir" on public.haberler for select using (auth.uid() is not null and yayinda = true);
create policy "Admin haber yönetir" on public.haberler for all using (is_admin());

-- HABER DOSYALARI
create policy "Herkes haber dosyalarını görebilir" on public.haber_dosyalari for select using (auth.uid() is not null);
create policy "Admin haber dosyası yönetir" on public.haber_dosyalari for all using (is_admin());

-- YORUMLAR
create policy "Herkes yorumları görebilir" on public.yorumlar for select using (auth.uid() is not null);
create policy "Sakin yorum yapabilir" on public.yorumlar for insert with check (sakin_id in (select id from public.sakinler where user_id = auth.uid()));
create policy "Sakin/admin yorum silebilir" on public.yorumlar for delete using (sakin_id in (select id from public.sakinler where user_id = auth.uid()) or is_admin());

-- PUSH ABONELİKLERİ
create policy "Kullanıcı kendi aboneliğini yönetir" on public.push_abonelikleri for all using (user_id = auth.uid());
create policy "Admin tüm abonelikleri görebilir" on public.push_abonelikleri for select using (is_admin());
