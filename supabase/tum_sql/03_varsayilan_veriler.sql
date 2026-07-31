-- =============================================
-- 3. VARSAYILAN VERİLER
-- =============================================

insert into public.ayarlar (anahtar, deger, aciklama) values
  ('aidat_tutari', '500', 'Aylık aidat tutarı (TL)'),
  ('aidat_yili',   '2026', 'Aktif aidat yılı');

insert into public.duyurular (baslik, icerik, onem) values
  ('Hoş Geldiniz!', 'Yazlık Sitesi uygulamasına hoş geldiniz.', 'normal');
