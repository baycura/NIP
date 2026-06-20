-- =============================================================================
-- NOT IN PARIS — Operations | Seed (Phase 0)
-- Run after 01_schema.sql + 02_rls.sql.
--
-- AUTH USERS: create the 5 people in Supabase Auth first (Dashboard → Auth, or
-- via MCP / admin API), using these emails. Then run this file to assign roles.
--   omer@notinparis.me    → super_admin
--   ceren@notinparis.me   → manager
--   fatih@notinparis.me   → manager
--   mustafa@notinparis.me → operations
--   burcu@notinparis.me   → staff
-- Station accounts (MUTFAK / BAR) are separate shared logins with role='station'
-- created the same way when KDS lands (Phase 2).
-- =============================================================================

-- ---- Assign roles to existing auth users (idempotent upsert by email) --------
do $$
declare
  r record;
  uid uuid;
begin
  for r in (
    select * from (values
      ('omer@notinparis.me',    'Omer',    'super_admin'),
      ('ceren@notinparis.me',   'Ceren',   'manager'),
      ('fatih@notinparis.me',   'Fatih',   'manager'),
      ('mustafa@notinparis.me', 'Mustafa', 'operations'),
      ('burcu@notinparis.me',   'Burcu',   'staff')
    ) as t(email, name, role)
  ) loop
    select id into uid from auth.users where email = r.email limit 1;
    if uid is not null then
      insert into profiles (id, name, role, lang, active)
      values (uid, r.name, r.role::user_role, 'tr', true)
      on conflict (id) do update
        set name = excluded.name, role = excluded.role, active = true, deleted_at = null;
    else
      raise notice 'Auth user % not found — create it in Auth, then re-run.', r.email;
    end if;
  end loop;
end $$;

-- ---- Demo categories (safe to run; no auth dependency) -----------------------
insert into categories (name_tr, name_en, type, sort) values
  ('Kahve',        'Coffee',      'coffee',     10),
  ('Bar',          'Bar',         'bar',        20),
  ('Yiyecek',      'Food',        'food',       30),
  ('Sarf Malzeme', 'Consumables', 'consumable', 40),
  ('Konsept Mağaza','Concept Store','store',    50)
on conflict do nothing;

-- ---- A couple of demo products to exercise stock/recipe flows later ----------
insert into products (name_tr, name_en, category_id, unit, is_sellable, is_raw, station, sell_price, current_stock, min_stock, last_purchase_price)
select 'Espresso', 'Espresso', c.id, 'piece', true, false, 'kitchen', 70, 0, 0, 0
from categories c where c.type = 'coffee'
on conflict do nothing;

insert into products (name_tr, name_en, category_id, unit, is_sellable, is_raw, station, sell_price, current_stock, min_stock, last_purchase_price)
select 'Çekirdek Kahve', 'Coffee Beans', c.id, 'kg', false, true, 'none', 0, 5, 1, 600
from categories c where c.type = 'consumable'
on conflict do nothing;
