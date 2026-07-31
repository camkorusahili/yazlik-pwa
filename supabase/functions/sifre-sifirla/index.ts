// Supabase Edge Function: Bir sakinin şifresini telefonun son 6 hanesine sıfırlar.
// Gerekirse e-postasını da telefon tabanlı girişe çevirir (sakin_id ile çağrılır).

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

    const { sakin_id, telefona_cevir } = await req.json()
    if (!sakin_id) throw new Error('sakin_id gerekli')

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: sakin, error: sakinError } = await supabaseAdmin
      .from('sakinler')
      .select('id, daire, daire_no, adi, soyadi, user_id, ceptel, ceptel2, tel1')
      .eq('id', sakin_id)
      .single()

    if (sakinError || !sakin) throw new Error('Sakin bulunamadı')
    if (!sakin.user_id) throw new Error('Bu sakinin henüz hesabı yok')

    const telRaw = telefonTemizle(sakin.ceptel || sakin.ceptel2 || sakin.tel1 || '')
    if (telRaw.length < 6) throw new Error('Geçerli bir telefon numarası bulunamadı')

    const yeniSifre = telRaw.slice(-6)
    const guncelleme: Record<string, unknown> = { password: yeniSifre }

    // İstenirse e-postayı da telefon tabanlı sahte e-postaya çevir
    if (telefona_cevir) {
      guncelleme.email = `${telRaw}@yazlik.local`
      guncelleme.email_confirm = true
    }

    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(sakin.user_id, guncelleme)
    if (updateError) throw new Error(updateError.message)

    return new Response(JSON.stringify({
      basarili: true,
      sifre: yeniSifre,
      email: telefona_cevir ? `${telRaw}@yazlik.local` : undefined
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
