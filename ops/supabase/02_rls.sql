-- =============================================================================
-- NOT IN PARIS — Operations | RLS scaffolding (Phase 0)
-- Row Level Security is the source of truth (brief §3). UI gating is secondary.
-- This is a SCAFFOLD: policies are tightened per phase as modules land.
-- Run after 01_schema.sql.
-- =============================================================================

-- Current user's app role, read from profiles. security definer so policies can
-- read profiles without recursing through profiles' own RLS.
create or replace function app_role()
returns user_role
language sql
stable
security definer
set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function is_super_admin() returns boolean
language sql stable as $$ select app_role() = 'super_admin' $$;

-- manager or above (sees reports/profit)
create or replace function is_manager_plus() returns boolean
language sql stable as $$ select app_role() in ('super_admin','manager') $$;

-- operations or above (can enter stock/costs/invoices)
create or replace function is_ops_plus() returns boolean
language sql stable as $$ select app_role() in ('super_admin','manager','operations') $$;

-- any signed-in human (everyone except shared station displays)
create or replace function is_staff_plus() returns boolean
language sql stable as $$ select app_role() in ('super_admin','manager','operations','staff') $$;

-- ---- Enable RLS on every table ----------------------------------------------
alter table profiles            enable row level security;
alter table categories          enable row level security;
alter table products            enable row level security;
alter table stock_batches       enable row level security;
alter table stock_movements     enable row level security;
alter table recipes             enable row level security;
alter table recipe_items        enable row level security;
alter table tab_accounts        enable row level security;
alter table shifts              enable row level security;
alter table orders              enable row level security;
alter table order_items         enable row level security;
alter table tab_entries         enable row level security;
alter table suppliers           enable row level security;
alter table supplier_prices     enable row level security;
alter table purchase_orders     enable row level security;
alter table purchase_order_items enable row level security;
alter table tasks               enable row level security;

-- =============================================================================
-- PROFILES — everyone signed in can read names/roles; only super_admin writes.
-- =============================================================================
drop policy if exists profiles_select on profiles;
create policy profiles_select on profiles for select
  using (deleted_at is null);

drop policy if exists profiles_admin_write on profiles;
create policy profiles_admin_write on profiles for all
  using (is_super_admin()) with check (is_super_admin());

-- =============================================================================
-- CATALOG (categories, products) — readable by all signed in (incl. station for
-- KDS). Cost column (last_purchase_price) is hidden from staff/station via a
-- view (see bottom). Writes: operations and above.
-- =============================================================================
drop policy if exists categories_select on categories;
create policy categories_select on categories for select using (deleted_at is null);
drop policy if exists categories_write on categories;
create policy categories_write on categories for all
  using (is_ops_plus()) with check (is_ops_plus());

drop policy if exists products_select on products;
create policy products_select on products for select using (deleted_at is null);
drop policy if exists products_write on products;
create policy products_write on products for all
  using (is_ops_plus()) with check (is_ops_plus());

-- =============================================================================
-- STOCK (batches, movements) — staff+ read & write (sales/counts). Append-only
-- audit intent: updates/deletes restricted to ops+; inserts allowed staff+.
-- =============================================================================
drop policy if exists stock_batches_rw on stock_batches;
create policy stock_batches_rw on stock_batches for all
  using (is_ops_plus()) with check (is_ops_plus());

drop policy if exists movements_select on stock_movements;
create policy movements_select on stock_movements for select
  using (deleted_at is null and is_staff_plus());
drop policy if exists movements_insert on stock_movements;
create policy movements_insert on stock_movements for insert
  with check (is_staff_plus());
drop policy if exists movements_update on stock_movements;
create policy movements_update on stock_movements for update
  using (is_ops_plus()) with check (is_ops_plus());

-- =============================================================================
-- RECIPES — readable by staff+ (POS needs BOM); writable by ops+.
-- =============================================================================
drop policy if exists recipes_select on recipes;
create policy recipes_select on recipes for select using (deleted_at is null and is_staff_plus());
drop policy if exists recipes_write on recipes;
create policy recipes_write on recipes for all using (is_ops_plus()) with check (is_ops_plus());

drop policy if exists recipe_items_select on recipe_items;
create policy recipe_items_select on recipe_items for select using (deleted_at is null and is_staff_plus());
drop policy if exists recipe_items_write on recipe_items;
create policy recipe_items_write on recipe_items for all using (is_ops_plus()) with check (is_ops_plus());

-- =============================================================================
-- SALES (orders, order_items, tabs, shifts) — staff+ operate the POS.
-- Station displays read order_items for their station (KDS); see kds policy.
-- =============================================================================
drop policy if exists orders_rw on orders;
create policy orders_rw on orders for all using (is_staff_plus()) with check (is_staff_plus());

drop policy if exists order_items_staff on order_items;
create policy order_items_staff on order_items for all
  using (is_staff_plus()) with check (is_staff_plus());

-- Station (shared display) may read items routed to it and flip kds_status.
-- NOTE: station accounts authenticate as a profile with role='station'.
drop policy if exists order_items_station_select on order_items;
create policy order_items_station_select on order_items for select
  using (app_role() = 'station' and deleted_at is null);
drop policy if exists order_items_station_update on order_items;
create policy order_items_station_update on order_items for update
  using (app_role() = 'station') with check (app_role() = 'station');

drop policy if exists shifts_rw on shifts;
create policy shifts_rw on shifts for all using (is_staff_plus()) with check (is_staff_plus());
drop policy if exists tab_accounts_rw on tab_accounts;
create policy tab_accounts_rw on tab_accounts for all using (is_staff_plus()) with check (is_staff_plus());
drop policy if exists tab_entries_rw on tab_entries;
create policy tab_entries_rw on tab_entries for all using (is_staff_plus()) with check (is_staff_plus());

-- =============================================================================
-- PROCUREMENT — THE MUSTAFA RULE (brief §3): operations may INSERT cost/price
-- rows (data-in) but may NOT read suppliers' prices back or any aggregate cost
-- (big-picture blocked). Managers+ have full read.
-- =============================================================================
drop policy if exists suppliers_select on suppliers;
create policy suppliers_select on suppliers for select using (deleted_at is null and is_ops_plus());
drop policy if exists suppliers_write on suppliers;
create policy suppliers_write on suppliers for all using (is_ops_plus()) with check (is_ops_plus());

-- supplier_prices: managers read; operations can ONLY insert (not select).
drop policy if exists supplier_prices_select on supplier_prices;
create policy supplier_prices_select on supplier_prices for select
  using (deleted_at is null and is_manager_plus());
drop policy if exists supplier_prices_insert on supplier_prices;
create policy supplier_prices_insert on supplier_prices for insert
  with check (is_ops_plus());

-- purchase orders: operations can create/receive (data-in); managers read all.
drop policy if exists po_select on purchase_orders;
create policy po_select on purchase_orders for select using (deleted_at is null and is_ops_plus());
drop policy if exists po_write on purchase_orders;
create policy po_write on purchase_orders for all using (is_ops_plus()) with check (is_ops_plus());

drop policy if exists po_items_select on purchase_order_items;
create policy po_items_select on purchase_order_items for select using (deleted_at is null and is_ops_plus());
drop policy if exists po_items_insert on purchase_order_items;
create policy po_items_insert on purchase_order_items for insert with check (is_ops_plus());

-- =============================================================================
-- TASKS (pool) — every signed-in human reads & participates. Staff create only
-- pool tasks (assignee null); ops+ may assign directly. Enforced finer in app +
-- tightened in Phase 1.
-- =============================================================================
drop policy if exists tasks_select on tasks;
create policy tasks_select on tasks for select using (deleted_at is null and is_staff_plus());
drop policy if exists tasks_insert on tasks;
create policy tasks_insert on tasks for insert with check (
  is_staff_plus() and (is_ops_plus() or assignee_id is null)
);
drop policy if exists tasks_update on tasks;
create policy tasks_update on tasks for update using (is_staff_plus()) with check (is_staff_plus());

-- =============================================================================
-- COST-HIDING VIEWS
--  v_products_public : catalog WITHOUT cost — safe for staff & station.
--  v_profit_margin   : aggregate margins — managers+ ONLY (blocks Mustafa).
-- Apps select the appropriate view per role; base tables stay RLS-protected.
-- =============================================================================
create or replace view v_products_public
with (security_invoker = true) as
  select id, name_tr, name_en, category_id, unit, barcode,
         is_sellable, is_raw, station, sell_price,
         current_stock, min_stock, track_expiry
  from products
  where deleted_at is null;

create or replace view v_profit_margin
with (security_invoker = true) as
  select p.id as product_id, p.name_tr, p.name_en,
         p.sell_price, p.last_purchase_price,
         (p.sell_price - p.last_purchase_price) as margin_abs,
         case when p.sell_price > 0
              then round((p.sell_price - p.last_purchase_price) / p.sell_price * 100, 1)
              else null end as margin_pct
  from products p
  where p.deleted_at is null
    and is_manager_plus(); -- security_invoker → blocks operations/staff/station
