// Supabase Edge Function: Bir sakinin giriş hesabını siler ve user_id bağlantısını keser.
// Aynı hesaba bağlı başka daire varsa sadece bu dairedeki bağlantıyı keser,
// diğer dairelere dokunmaz (hesabı silmez).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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

    const { sakin_id } = await req.json()
    if (!sakin_id) throw new Error('sakin_id gerekli')

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Sakini bul
    const { data: sakin, error: sakinError } = await supabaseAdmin
      .from('sakinler')
      .select('id, daire_no, daire, adi, soyadi, user_id')
      .eq('id', sakin_id)
      .single()

    if (sakinError || !sakin) throw new Error('Sakin bulunamadı')
    if (!sakin.user_id) throw new Error('Bu sakinin zaten hesap bağlantısı yok')

    // Aynı hesaba bağlı başka daire var mı?
    const { data: digerDaireler } = await supabaseAdmin
      .from('sakinler')
      .select('id, daire_no, daire')
      .eq('user_id', sakin.user_id)
      .neq('id', sakin_id)

    // Sadece bu dairedeki bağlantıyı kes
    await supabaseAdmin
      .from('sakinler')
      .update({ user_id: null })
      .eq('id', sakin_id)

    // Başka daire yoksa Auth hesabını da sil
    if (!digerDaireler || digerDaireler.length === 0) {
      await supabaseAdmin.auth.admin.deleteUser(sakin.user_id)
      return new Response(JSON.stringify({
        basarili: true,
        mesaj: 'Hesap bağlantısı kesildi ve giriş hesabı silindi.',
        hesapSilindi: true
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Başka daire varsa sadece bu dairedeki bağlantıyı kestik, hesabı koruyoruz
    const digerDaireIsim = digerDaireler.map(d => `Daire ${d.daire_no || d.daire}`).join(', ')
    return new Response(JSON.stringify({
      basarili: true,
      mesaj: `Bağlantı kesildi. Hesap ${digerDaireIsim} için korundu.`,
      hesapSilindi: false,
      digerDaireler: digerDaireler
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
