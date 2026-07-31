// Supabase Edge Function: Sakinler için toplu giriş hesabı oluşturur
// Sadece admin tetikleyebilir. service_role key burada güvenli (sunucu tarafı).
//
// Öncelik sırası:
// 1) E-postası varsa -> gerçek e-posta + rastgele şifre
// 2) E-postası yoksa ama telefonu varsa -> sahte e-posta (telefon@yazlik.local) + telefonun son 6 hanesi şifre
// 3) İkisi de yoksa -> atlanır

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function rastgeleSifre() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
  let s = ''
  for (let i = 0; i < 8; i++) s += chars[Math.floor(Math.random() * chars.length)]
  return s
}

function telefonTemizle(tel: string) {
  return (tel || '').replace(/\D/g, '') // sadece rakamlar
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

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // user_id'si boş olan tüm sakinleri çek (email veya telefon biri olsun yeter)
    const { data: sakinler, error: fetchError } = await supabaseAdmin
      .from('sakinler')
      .select('id, daire, daire_no, adi, soyadi, email, ceptel, ceptel2, tel1')
      .is('user_id', null)

    if (fetchError) throw fetchError

    const sonuclar = []

    for (const sakin of sakinler) {
      const gercekEmail = sakin.email && sakin.email.trim() !== ''
      const telRaw = telefonTemizle(sakin.ceptel || sakin.ceptel2 || sakin.tel1 || '')

      let girisEmail = ''
      let sifre = ''
      let yontem = ''

      if (gercekEmail) {
        girisEmail = sakin.email.trim()
        sifre = rastgeleSifre()
        yontem = 'eposta'
      } else if (telRaw.length >= 6) {
        const son6 = telRaw.slice(-6)
        girisEmail = `${telRaw}@yazlik.local`
        sifre = son6
        yontem = 'telefon'
      } else {
        sonuclar.push({
          daire: sakin.daire_no || sakin.daire, adi: `${sakin.adi} ${sakin.soyadi}`,
          durum: 'atlandi', mesaj: 'E-posta ve telefon bilgisi yetersiz'
        })
        continue
      }

      const { data: yeniKullanici, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: girisEmail,
        password: sifre,
        email_confirm: true,
        user_metadata: { role: 'sakin', daire: sakin.daire }
      })

      if (createError) {
        sonuclar.push({
          daire: sakin.daire_no || sakin.daire, adi: `${sakin.adi} ${sakin.soyadi}`,
          email: girisEmail, durum: 'hata', mesaj: createError.message
        })
        continue
      }

      await supabaseAdmin
        .from('sakinler')
        .update({ user_id: yeniKullanici.user.id })
        .eq('id', sakin.id)

      sonuclar.push({
        daire: sakin.daire_no || sakin.daire, adi: `${sakin.adi} ${sakin.soyadi}`,
        email: girisEmail, sifre, yontem, durum: 'basarili'
      })
    }

    return new Response(JSON.stringify({ sonuclar, toplam: sonuclar.length }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
