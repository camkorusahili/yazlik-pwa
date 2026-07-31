-- =============================================
-- STORAGE: Sakin Fotoğrafları
-- ÖNEMLİ: Önce Dashboard'dan bucket'ı oluşturun (aşağıdaki notlara bakın),
-- SONRA bu SQL'i çalıştırın.
-- =============================================

-- Sadece admin fotoğraf yükleyebilir/silebilir
create policy "Admin fotoğraf yükleyebilir"
  on storage.objects for insert
  with check (bucket_id = 'sakin-fotograflari' and is_admin());

create policy "Admin fotoğraf silebilir"
  on storage.objects for delete
  using (bucket_id = 'sakin-fotograflari' and is_admin());

create policy "Admin fotoğraf güncelleyebilir"
  on storage.objects for update
  using (bucket_id = 'sakin-fotograflari' and is_admin());

-- Giriş yapmış herkes fotoğrafları görebilir (rehberde göstermek için)
create policy "Giriş yapanlar fotoğraf görebilir"
  on storage.objects for select
  using (bucket_id = 'sakin-fotograflari' and auth.uid() is not null);
