-- ============================================================================
-- Profil alan doğrulaması (sunucu tarafı) — NOT IN PARIS
-- ============================================================================
-- Client'taki form doğrulaması atlatılabilir (konsol/doğrudan API). Bu trigger,
-- profiles tablosuna yazılan isim/telefon/instagram değerlerinin gerçekten
-- doldurulmuş olmasını DB seviyesinde zorunlu kılar: "-", "...", tek kelime
-- isim, 0000000 gibi geçiştirmeler reddedilir.
--
-- Kural yalnızca YENİ yazılan/değişen değerlere uygulanır; mevcut satırlar
-- ellenmedikçe etkilenmez. Adminler (nip_is_admin) muaftır.
-- ============================================================================

create or replace function public.nip_validate_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_digits text;
begin
  -- Adminler düzeltme yapabilsin
  if public.nip_is_admin() then
    return new;
  end if;

  -- İSİM: en az iki kelime, her kelimede >=2 harf, rakam yok
  if (tg_op = 'INSERT' or new.name is distinct from old.name) and new.name is not null then
    if new.name ~ '[0-9]'
       or (select count(*) from regexp_split_to_table(trim(new.name), '\s+') w
           where length(regexp_replace(w, '[^[:alpha:]]', '', 'g')) >= 2) < 2 then
      raise exception 'Geçerli isim ve soyisim girin';
    end if;
  end if;

  -- TELEFON: 7-15 rakam, hepsi aynı rakam olamaz
  if (tg_op = 'INSERT' or new.phone is distinct from old.phone) and new.phone is not null then
    v_digits := regexp_replace(new.phone, '\D', '', 'g');
    if length(v_digits) < 7 or length(v_digits) > 15
       or v_digits ~ '^(\d)\1+$' then
      raise exception 'Geçerli bir telefon numarası girin';
    end if;
  end if;

  -- INSTAGRAM: 3-30 karakter, harf/rakam/._ ; sadece nokta-altçizgi olamaz
  if (tg_op = 'INSERT' or new.instagram is distinct from old.instagram) and new.instagram is not null then
    new.instagram := regexp_replace(trim(new.instagram), '^@+', '');
    if new.instagram !~ '^[A-Za-z0-9._]{3,30}$'
       or new.instagram !~ '[A-Za-z0-9]' then
      raise exception 'Geçerli bir Instagram kullanıcı adı girin';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_nip_validate_profile on public.profiles;
create trigger trg_nip_validate_profile
  before insert or update on public.profiles
  for each row execute function public.nip_validate_profile();

-- INSERT'te OLD mevcut olmadığından TG_OP='INSERT' dalıyla tüm alanlar kontrol edilir.

-- ROLLBACK:
-- drop trigger if exists trg_nip_validate_profile on public.profiles;
-- drop function if exists public.nip_validate_profile();
