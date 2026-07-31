-- =============================================
-- SAKİN PROFİLİNE EK ALANLAR (sadece admin görür/düzenler)
-- =============================================

alter table public.sakinler
  add column if not exists plaka text,
  add column if not exists cocuk_sayisi integer;

-- fotograf_url ve aciklama, es_adi, baba_adi, anne_adi sütunları zaten şemada mevcuttu
