-- =============================================
-- 4. STORAGE POLİTİKALARI
-- Bu SQL'i çalıştırmadan önce Dashboard'dan
-- şu bucket'ları oluşturun (Public: AÇIK):
--   - sakin-fotograflari
--   - haber-dosyalari
-- =============================================

-- Sakin fotoğrafları
create policy "Admin fotoğraf yükleyebilir" on storage.objects for insert with check (bucket_id = 'sakin-fotograflari' and is_admin());
create policy "Admin fotoğraf silebilir" on storage.objects for delete using (bucket_id = 'sakin-fotograflari' and is_admin());
create policy "Admin fotoğraf güncelleyebilir" on storage.objects for update using (bucket_id = 'sakin-fotograflari' and is_admin());
create policy "Giriş yapanlar fotoğraf görebilir" on storage.objects for select using (bucket_id = 'sakin-fotograflari' and auth.uid() is not null);

-- Haber dosyaları
create policy "Admin haber dosyası yükleyebilir" on storage.objects for insert with check (bucket_id = 'haber-dosyalari' and is_admin());
create policy "Admin haber dosyası silebilir" on storage.objects for delete using (bucket_id = 'haber-dosyalari' and is_admin());
create policy "Herkes haber dosyalarını görebilir" on storage.objects for select using (bucket_id = 'haber-dosyalari' and auth.uid() is not null);
