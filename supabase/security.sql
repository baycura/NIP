-- ============================================================================
-- NOT IN PARIS — Supabase güvenlik betiği (RLS + admin modeli + RPC'ler)
-- ============================================================================
--
-- AMAÇ: Uygulama tamamen client-side olduğu için (anon key herkese açık),
-- TEK gerçek güvenlik sınırı bu politikalardır. Bu betik olmadan, herhangi
-- bir ziyaretçi tarayıcı konsolundan kendi profilini "approved" yapabilir,
-- puanını yükseltebilir, başka üyeleri silebilir veya rezervasyonları
-- onaylayabilir.
--
-- ⚠️ ÖNEMLİ — UYGULAMADAN ÖNCE OKU:
--   1) Bu betik, frontend kodundan ÇIKARILAN şema varsayımlarına dayanır.
--      Çalıştırmadan önce tablo/kolon adlarını KENDİ veritabanınla doğrula.
--   2) Mümkünse önce bir STAGING/branch veritabanında test et.
--   3) RLS'i etkinleştirmek, politikalar eksikse uygulamanın bir kısmını
--      "boş" gösterebilir — her bölümü uyguladıktan sonra uygulamayı test et.
--   4) Geri alma (rollback) komutları en altta.
--
-- ROLLOUT SIRASI (SECURITY.md'deki adımlarla birlikte):
--   A) Bu betiği çalıştır.
--   B) Kendine bir Supabase Auth kullanıcısı oluştur (e-posta + şifre).
--   C) O kullanıcının profilinde is_admin = true yap (en alttaki örnek).
--   D) Frontend'i (PR) merge et.
--   E) Eski açık sırrı sil:  delete from settings where key='admin_credentials';
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0) Admin bayrağı: profiles.is_admin
-- ----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists is_admin boolean not null default false;

-- ----------------------------------------------------------------------------
-- 1) Yardımcı: çağıran kullanıcı admin mi?  (RLS özyinelemesini önlemek için
--    SECURITY DEFINER — profiles üstündeki RLS'i tetiklemeden okur)
-- ----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.is_admin from public.profiles p where p.id = auth.uid()),
    false
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2) RLS'i etkinleştir
-- ----------------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.events            enable row level security;
alter table public.reservations      enable row level security;
alter table public.reputation_ledger enable row level security;
alter table public.settings          enable row level security;
-- waitlist tablon varsa:
-- alter table public.waitlist enable row level security;

-- ----------------------------------------------------------------------------
-- 3) PROFILES politikaları
--    - Kullanıcı yalnızca KENDİ profilini görür; admin hepsini görür.
--    - Kullanıcı kendi profilini güncelleyebilir AMA korunan kolonları
--      (status/puan/tier/is_admin...) DEĞİŞTİREMEZ — aşağıdaki trigger engeller.
--    - Silme yalnızca admin.
-- ----------------------------------------------------------------------------
drop policy if exists profiles_select_own_or_admin on public.profiles;
create policy profiles_select_own_or_admin on public.profiles
  for select using ( id = auth.uid() or public.is_admin() );

drop policy if exists profiles_update_own_or_admin on public.profiles;
create policy profiles_update_own_or_admin on public.profiles
  for update using ( id = auth.uid() or public.is_admin() )
            with check ( id = auth.uid() or public.is_admin() );

drop policy if exists profiles_delete_admin on public.profiles;
create policy profiles_delete_admin on public.profiles
  for delete using ( public.is_admin() );

-- INSERT: profiller normalde auth.users üstündeki trigger ile oluşur
-- (handle_new_user). Eğer öyle ise INSERT politikası gerekmez. Değilse:
-- drop policy if exists profiles_insert_self on public.profiles;
-- create policy profiles_insert_self on public.profiles
--   for insert with check ( id = auth.uid() );

-- ----- Privilege-escalation koruması: korunan kolonlar -----------------------
-- Kullanıcı kendi satırını güncellerken yalnızca güvenli alanları
-- değiştirebilir. status/tier/puanlar/is_admin/member_code/referral_* vs.
-- yalnızca admin veya SECURITY DEFINER RPC (guard_off) tarafından değişebilir.
create or replace function public.profiles_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- RPC'ler (redeem_referral vb.) bu bayrağı set ederek geçer:
  if coalesce(current_setting('app.guard_off', true), '') = '1' then
    return new;
  end if;
  -- Admin her şeyi değiştirebilir:
  if public.is_admin() then
    return new;
  end if;
  -- Aksi halde korunan kolonlar değişmemeli:
  if new.status            is distinct from old.status            then raise exception 'status değiştirilemez'; end if;
  if new.is_admin          is distinct from old.is_admin          then raise exception 'is_admin değiştirilemez'; end if;
  if new.tier              is distinct from old.tier              then raise exception 'tier değiştirilemez'; end if;
  if new.trust_score       is distinct from old.trust_score       then raise exception 'trust_score değiştirilemez'; end if;
  if new.loyalty_score     is distinct from old.loyalty_score     then raise exception 'loyalty_score değiştirilemez'; end if;
  if new.reward_points     is distinct from old.reward_points     then raise exception 'reward_points değiştirilemez'; end if;
  if new.member_code       is distinct from old.member_code       then raise exception 'member_code değiştirilemez'; end if;
  if new.referral_code     is distinct from old.referral_code     then raise exception 'referral_code değiştirilemez'; end if;
  if new.referral_used     is distinct from old.referral_used     then raise exception 'referral_used değiştirilemez'; end if;
  if new.referral_limit    is distinct from old.referral_limit    then raise exception 'referral_limit değiştirilemez'; end if;
  if new.referred_by       is distinct from old.referred_by       then raise exception 'referred_by değiştirilemez'; end if;
  if new.total_attended    is distinct from old.total_attended    then raise exception 'total_attended değiştirilemez'; end if;
  if new.total_no_show     is distinct from old.total_no_show     then raise exception 'total_no_show değiştirilemez'; end if;
  if new.attendance_streak is distinct from old.attendance_streak then raise exception 'attendance_streak değiştirilemez'; end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_guard on public.profiles;
create trigger trg_profiles_guard
  before update on public.profiles
  for each row execute function public.profiles_guard();

-- ----------------------------------------------------------------------------
-- 4) EVENTS politikaları
--    - Herkes (anon dahil) aktif etkinlikleri okuyabilir.
--    - Yazma yalnızca admin.
-- ----------------------------------------------------------------------------
drop policy if exists events_select_all on public.events;
create policy events_select_all on public.events
  for select using ( true );

drop policy if exists events_write_admin on public.events;
create policy events_write_admin on public.events
  for all using ( public.is_admin() ) with check ( public.is_admin() );

-- ----------------------------------------------------------------------------
-- 5) RESERVATIONS politikaları
--    - INSERT: herkes (üye veya misafir) rezervasyon talebi oluşturabilir,
--      ANCAK yalnızca status='pending' ve (giriş yapmışsa) kendi profile_id'si.
--    - SELECT: kullanıcı kendi rezervasyonlarını görür; admin hepsini.
--    - UPDATE/DELETE: yalnızca admin (onay/red/no-show/check-in).
-- ----------------------------------------------------------------------------
drop policy if exists reservations_insert_public on public.reservations;
create policy reservations_insert_public on public.reservations
  for insert with check (
    status = 'pending'
    and ( profile_id is null or profile_id = auth.uid() )
  );

drop policy if exists reservations_select_own_or_admin on public.reservations;
create policy reservations_select_own_or_admin on public.reservations
  for select using ( profile_id = auth.uid() or public.is_admin() );

drop policy if exists reservations_update_admin on public.reservations;
create policy reservations_update_admin on public.reservations
  for update using ( public.is_admin() ) with check ( public.is_admin() );

drop policy if exists reservations_delete_admin on public.reservations;
create policy reservations_delete_admin on public.reservations
  for delete using ( public.is_admin() );

-- ----------------------------------------------------------------------------
-- 6) REPUTATION_LEDGER politikaları
--    - SELECT: kullanıcı kendi geçmişini; admin hepsini.
--    - INSERT/UPDATE/DELETE: yalnızca admin (puan hareketleri).
-- ----------------------------------------------------------------------------
drop policy if exists ledger_select_own_or_admin on public.reputation_ledger;
create policy ledger_select_own_or_admin on public.reputation_ledger
  for select using ( profile_id = auth.uid() or public.is_admin() );

drop policy if exists ledger_write_admin on public.reputation_ledger;
create policy ledger_write_admin on public.reputation_ledger
  for all using ( public.is_admin() ) with check ( public.is_admin() );

-- ----------------------------------------------------------------------------
-- 7) SETTINGS politikaları
--    - SELECT: yalnızca herkese açık anahtarlar (slogan, announcement).
--      DİKKAT: admin_credentials ARTIK KULLANILMIYOR ve okunabilir OLMAMALI.
--    - Yazma: yalnızca admin.
-- ----------------------------------------------------------------------------
drop policy if exists settings_select_public on public.settings;
create policy settings_select_public on public.settings
  for select using ( key in ('slogan','announcement') or public.is_admin() );

drop policy if exists settings_write_admin on public.settings;
create policy settings_write_admin on public.settings
  for all using ( public.is_admin() ) with check ( public.is_admin() );

-- ----------------------------------------------------------------------------
-- 8) RPC: referans kodu önizleme (validate_referral)
--    Frontend referans kodunu doğrudan profiles'tan okuyamaz (RLS). Bu RPC
--    yalnızca güvenli alanları döner: referrer adı + kalan hak.
-- ----------------------------------------------------------------------------
create or replace function public.validate_referral(p_code text)
returns table(name text, remaining int)
language sql
stable
security definer
set search_path = public
as $$
  select p.name,
         greatest(0, coalesce(p.referral_limit,3) - coalesce(p.referral_used,0)) as remaining
  from public.profiles p
  where p.referral_code = p_code
    and p.status = 'approved'
    and coalesce(p.referral_used,0) < coalesce(p.referral_limit,3);
$$;

revoke all on function public.validate_referral(text) from public;
grant execute on function public.validate_referral(text) to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 9) RPC: profil tamamla + referans kullan (redeem_referral)
--    Google ile giren kullanıcının client'ta KENDİNİ "approved" yapması
--    güvenlik açığıydı. Onay artık SADECE bu sunucu fonksiyonuyla olur.
--    Geçerli referans varsa approved + member_code üretir ve referrer'ın
--    referral_used değerini güvenli şekilde artırır.
-- ----------------------------------------------------------------------------
create or replace function public.redeem_referral(
  p_phone text,
  p_instagram text,
  p_referral_code text
)
returns text  -- ortaya çıkan status ('approved' | 'pending')
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ref    public.profiles%rowtype;
  v_status text := 'pending';
  v_code   text := null;
begin
  if auth.uid() is null then
    raise exception 'oturum yok';
  end if;

  -- Üyelik için telefon ve instagram zorunlu (client atlansa bile engelle)
  if p_phone is null or length(trim(p_phone)) = 0 then
    raise exception 'telefon zorunludur';
  end if;
  if p_instagram is null or length(trim(p_instagram)) = 0 then
    raise exception 'instagram zorunludur';
  end if;

  -- korunan-kolon trigger'ını bu kontrollü işlem için aç
  perform set_config('app.guard_off', '1', true);

  if p_referral_code is not null and length(p_referral_code) > 0 then
    select * into v_ref from public.profiles
      where referral_code = p_referral_code
        and status = 'approved'
        and coalesce(referral_used,0) < coalesce(referral_limit,3)
      for update;
    if found then
      v_status := 'approved';
      v_code   := 'NIP-MBR-' || upper(substr(md5(random()::text),1,6));
      update public.profiles
         set referral_used = coalesce(referral_used,0) + 1
       where id = v_ref.id;
    end if;
  end if;

  update public.profiles
     set phone       = p_phone,
         instagram   = nullif(p_instagram,''),
         status      = v_status,
         member_code = coalesce(v_code, member_code),
         ref_by      = coalesce(v_ref.name, ref_by),
         referred_by = coalesce(v_ref.id, referred_by),
         approved_at = case when v_status='approved' then now() else approved_at end
   where id = auth.uid();

  return v_status;
end;
$$;

revoke all on function public.redeem_referral(text,text,text) from public;
grant execute on function public.redeem_referral(text,text,text) to authenticated;

-- ----------------------------------------------------------------------------
-- 10) İLK ADMİNİ AYARLA
--     Önce Supabase Auth'ta kendine bir kullanıcı oluştur (e-posta+şifre),
--     sonra şu satırı KENDİ e-postanla çalıştır:
-- ----------------------------------------------------------------------------
-- update public.profiles set is_admin = true
--   where id = (select id from auth.users where email = 'senin@epostan.com');

-- delete from public.settings where key = 'admin_credentials';  -- eski sırrı sil

-- ============================================================================
-- ROLLBACK (acil durumda RLS'i geri kapatmak için — uygulamayı tekrar açar
-- ama korumayı kaldırır):
-- ============================================================================
-- alter table public.profiles          disable row level security;
-- alter table public.events            disable row level security;
-- alter table public.reservations      disable row level security;
-- alter table public.reputation_ledger disable row level security;
-- alter table public.settings          disable row level security;
-- drop trigger if exists trg_profiles_guard on public.profiles;
