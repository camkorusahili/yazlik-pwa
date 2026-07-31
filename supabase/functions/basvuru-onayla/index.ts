// Supabase Edge Function: Bekleyen bir başvuruyu onaylar.
// - Eğer eslesen_sakin_id belirtilmişse: o sakin kaydına hesap açar (ya da zaten hesabı varsa hata döner)
// - Eğer belirtilmemişse: yeni bir sakin kaydı oluşturup ona hesap açar
// Şifre: telefonun son 6 hanesi

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function telefonTemizle(tel: string) {
  return (tel || '').replace(/\D/g, '')
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const authHeader = req.headers.get('Authorization')!
    const supabaseAuth = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user } } = await supabaseAuth.auth.getUser()
    if (!user || user.user_metadata?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Yetkisiz erişim' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const { basvuru_id, eslesen_sakin_id } = await req.json()
    if (!basvuru_id) {
      return new Response(JSON.stringify({ error: 'basvuru_id gerekli' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: basvuru, error: basvuruError } = await supabaseAdmin
      .from('basvurular')
      .select('*')
      .eq('id', basvuru_id)
      .single()

    if (basvuruError || !basvuru) throw new Error('Başvuru bulunamadı')
    if (basvuru.durum !== 'bekliyor') throw new Error('Bu başvuru zaten işlenmiş')

    const telRaw = telefonTemizle(basvuru.telefon)
    if (telRaw.length < 6) throw new Error('Geçersiz telefon numarası')
    const sifre = telRaw.slice(-6)
    const girisEmail = `${telRaw}@yazlik.local`

    let hedefSakinId = eslesen_sakin_id

    // Eşleşen sakin belirtilmemişse yeni kayıt oluştur
    if (!hedefSakinId) {
      const { data: yeniSakin, error: sakinError } = await supabaseAdmin
        .from('sakinler')
        .insert({
          adi: basvuru.adi,
          soyadi: basvuru.soyadi,
          daire_no: basvuru.daire_no,
          daire: basvuru.daire || String(basvuru.daire_no || ''),
          ceptel: basvuru.telefon
        })
        .select()
        .single()

      if (sakinError) throw new Error('Sakin kaydı oluşturulamadı: ' + sakinError.message)
      hedefSakinId = yeniSakin.id
    } else {
      // Eşleşen sakin zaten hesaplıysa, sadece o hesabı bu kayda da bağla (çoklu daire durumu)
      const { data: hedefSakin } = await supabaseAdmin
        .from('sakinler')
        .select('user_id')
        .eq('id', hedefSakinId)
        .single()

      if (hedefSakin?.user_id) {
        // Yeni daire kaydı oluştur, mevcut user_id'yi ona bağla
        const { data: yeniDaire, error: yeniDaireError } = await supabaseAdmin
          .from('sakinler')
          .insert({
            adi: basvuru.adi,
            soyadi: basvuru.soyadi,
            daire_no: basvuru.daire_no,
            daire: basvuru.daire || String(basvuru.daire_no || ''),
            ceptel: basvuru.telefon,
            user_id: hedefSakin.user_id
          })
          .select()
          .single()

        if (yeniDaireError) throw new Error('Daire kaydı oluşturulamadı: ' + yeniDaireError.message)

        await supabaseAdmin
          .from('basvurular')
          .update({ durum: 'onaylandi', eslesen_sakin_id: yeniDaire.id, islenme_tarihi: new Date().toISOString() })
          .eq('id', basvuru_id)

        return new Response(JSON.stringify({ basarili: true, mevcutHesabaBaglandi: true }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // Yeni hesap oluştur
    const { data: yeniKullanici, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: girisEmail,
      password: sifre,
      email_confirm: true,
      user_metadata: { role: 'sakin' }
    })

    if (createError) throw new Error('Hesap oluşturulamadı: ' + createError.message)

    await supabaseAdmin
      .from('sakinler')
      .update({ user_id: yeniKullanici.user.id })
      .eq('id', hedefSakinId)

    await supabaseAdmin
      .from('basvurular')
      .update({ durum: 'onaylandi', eslesen_sakin_id: hedefSakinId, islenme_tarihi: new Date().toISOString() })
      .eq('id', basvuru_id)

    return new Response(JSON.stringify({ basarili: true, email: girisEmail, sifre }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
