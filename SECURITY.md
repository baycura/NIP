# Güvenlik — NOT IN PARIS

Bu uygulama **tamamen client-side** bir statik sitedir (GitHub Pages) ve
doğrudan Supabase'e `anon` (herkese açık) anahtarla bağlanır. Bu mimaride
**tek gerçek güvenlik sınırı Supabase Row Level Security (RLS) politikalarıdır.**
JavaScript içindeki hiçbir kontrol güvenlik sağlamaz — herkes "View Source"
yapabilir ve anon anahtarla doğrudan veritabanına istek atabilir.

## Bulunan açıklar

| Önem | Açık | Açıklama |
|------|------|----------|
| 🔴 Kritik | **Privilege escalation** | `doCompleteProfile` client'ta kullanıcının kendi profilinde `status='approved'`, `member_code` vb. ayarlıyordu. RLS yoksa herkes konsoldan kendini onaylayabilir, puanını/tier'ını yükseltebilir. |
| 🔴 Kritik | **Korumasız yazma** | RLS yoksa anon anahtarla `profiles`/`reservations`/`reputation_ledger`/`events` üzerinde herkes silme/güncelleme/insert yapabilir (başka üyeyi silmek, rezervasyon onaylamak, puan basmak). |
| 🔴 Kritik | **Açık admin şifresi** | `index.html` içinde admin kullanıcı adı/şifresi düz metin gömülüydü (`settings.admin_credentials` yoksa fallback). Kaynak kodda herkese görünür. Ayrıca admin yetkisi sadece `sessionStorage` bayrağıyla kontrol ediliyordu. |
| 🟡 Orta | **Referans tablosu okuması** | Referans kontrolü `profiles` tablosunu koda doğrudan sorguluyordu; RLS ile kısıtlanınca RPC gerekir. |

## Doğru çözüm — bu repodaki dosyalar

1. **`supabase/security.sql`** — Asıl düzeltme: RLS politikaları, `is_admin()`
   yardımcı fonksiyonu, privilege-escalation'ı engelleyen `profiles` trigger'ı
   ve referans işlemleri için iki güvenli RPC (`validate_referral`,
   `redeem_referral`).
2. **`index.html`** (bu PR) — Frontend artık:
   - Admin girişini **gerçek Supabase Auth + `is_admin`** ile yapıyor;
     gömülü düz-metin şifre **kaldırıldı**.
   - Referans önizlemesini `validate_referral` RPC'siyle alıyor.
   - Profil tamamlamayı `redeem_referral` RPC'siyle yapıyor (artık client
     kendini "approved" yapamıyor).

> ⚠️ Frontend ve SQL **birlikte** çalışır. PR'ı merge etmeden ÖNCE aşağıdaki
> backend adımlarını uygula, yoksa admin girişi ve referanslı kayıt çalışmaz.

## Rollout (sırasıyla)

1. **SQL'i çalıştır.** Supabase → SQL Editor → `supabase/security.sql` içeriğini
   yapıştır. (Önce tablo/kolon adlarını kendi şemanla doğrula; mümkünse bir
   branch/staging DB'de test et.)
2. **Admin kullanıcısı oluştur.** Supabase → Authentication → Users → "Add user"
   ile kendine e-posta + şifre tanımla.
3. **`is_admin` ver.** SQL Editor'de:
   ```sql
   update public.profiles set is_admin = true
     where id = (select id from auth.users where email = 'senin@epostan.com');
   ```
4. **Test et.** Site → `#admin` → e-posta + şifre ile gir. Admin paneli açılmalı;
   bir etkinlik oluştur/güncelle ve bir rezervasyonu onayla.
5. **PR'ı merge et** (frontend canlıya çıkar).
6. **Eski sırrı sil.**
   ```sql
   delete from public.settings where key = 'admin_credentials';
   ```
   Ayrıca git geçmişinde kaldığı için **eski şifreyi her yerde değiştir** (aynı
   şifreyi başka serviste kullandıysan).

## Doğrulama (RLS gerçekten çalışıyor mu?)

Tarayıcı konsolunda, **normal bir üye olarak giriş yaptıktan sonra** şunu dene —
hata dönmeli (engellenmeli):

```js
// kendini onaylamayı dene — RLS/trigger ENGELLEMELİ
await window._SB.from('profiles')
  .update({ status:'approved', trust_score:9999 })
  .eq('id', (await window._SB.auth.getUser()).data.user.id);
// -> error: "status değiştirilemez" benzeri
```

Engellenmiyorsa RLS/trigger düzgün uygulanmamıştır.

## Not

Anon anahtarın kodda bulunması **normaldir** (Supabase böyle tasarlanmıştır) —
güvenlik anon anahtarın gizliliğinden değil, RLS politikalarından gelir. Asla
`service_role` anahtarını client'a koyma.
