-- =============================================
-- SAKİN PROFİLİNE EK ALANLAR (2. tur)
-- =============================================

alter table public.sakinler
  add column if not exists dogum_tarihi date,
  add column if not exists dogum_yeri text,
  add column if not exists meslek text;
