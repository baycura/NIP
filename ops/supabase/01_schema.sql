-- =============================================================================
-- NOT IN PARIS — Operations | Schema (Phase 0)
-- Core tables from System Brief §4. RLS-first, soft-delete from day one.
-- Apply in order: 01_schema.sql → 02_rls.sql → 03_seed.sql
-- Idempotent-ish: safe to re-run on a fresh project.
-- =============================================================================

create extension if not exists pgcrypto; -- gen_random_uuid()

-- ---- Enums -------------------------------------------------------------------
do $$ begin
  create type user_role     as enum ('super_admin','manager','operations','staff','station');
exception when duplicate_object then null; end $$;
do $$ begin
  create type category_type as enum ('bar','coffee','food','consumable','store');
exception when duplicate_object then null; end $$;
do $$ begin
  create type product_unit  as enum ('piece','kg','lt');
exception when duplicate_object then null; end $$;
do $$ begin
  create type product_station as enum ('kitchen','bar','none');
exception when duplicate_object then null; end $$;
do $$ begin
  create type movement_type as enum ('in','out','waste','sale','count_adjust');
exception when duplicate_object then null; end $$;
do $$ begin
  create type order_status  as enum ('open','closed','void');
exception when duplicate_object then null; end $$;
do $$ begin
  create type payment_type  as enum ('cash','card','transfer','tab');
exception when duplicate_object then null; end $$;
do $$ begin
  create type kds_status    as enum ('new','ready');
exception when duplicate_object then null; end $$;
do $$ begin
  create type po_status     as enum ('draft','ordered','received');
exception when duplicate_object then null; end $$;
do $$ begin
  create type task_status   as enum ('open','done');
exception when duplicate_object then null; end $$;

-- ---- Core --------------------------------------------------------------------
create table if not exists profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text not null,
  role        user_role not null default 'staff',
  lang        text not null default 'tr',
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  name_tr     text not null,
  name_en     text not null,
  type        category_type not null,
  sort        int not null default 0,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists products (
  id                  uuid primary key default gen_random_uuid(),
  name_tr             text not null,
  name_en             text not null,
  category_id         uuid references categories (id),
  unit                product_unit not null default 'piece',
  barcode             text,
  is_sellable         boolean not null default true,
  is_raw              boolean not null default false,
  station             product_station not null default 'none',
  sell_price          numeric(12,2) not null default 0,
  current_stock       numeric(14,3) not null default 0,
  min_stock           numeric(14,3) not null default 0,   -- critical threshold
  last_purchase_price numeric(12,2) not null default 0,
  track_expiry        boolean not null default false,
  created_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

create table if not exists stock_batches (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references products (id),
  qty         numeric(14,3) not null,
  expiry_date date,
  received_at timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists stock_movements (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references products (id),
  type        movement_type not null,
  qty         numeric(14,3) not null,
  reason      text,
  user_id     uuid references profiles (id),
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ---- Recipes (BOM) -----------------------------------------------------------
create table if not exists recipes (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references products (id),   -- the sellable item
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists recipe_items (
  id              uuid primary key default gen_random_uuid(),
  recipe_id       uuid not null references recipes (id),
  raw_product_id  uuid not null references products (id),
  qty             numeric(14,3) not null,
  unit            product_unit not null,
  deleted_at      timestamptz
);

-- ---- Sales / POS -------------------------------------------------------------
create table if not exists tab_accounts (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  balance     numeric(12,2) not null default 0,
  notes       text,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists shifts (
  id             uuid primary key default gen_random_uuid(),
  opened_by      uuid references profiles (id),
  opened_at      timestamptz not null default now(),
  closed_at      timestamptz,
  cash_total     numeric(12,2) not null default 0,
  card_total     numeric(12,2) not null default 0,
  transfer_total numeric(12,2) not null default 0,
  notes          text,                                  -- Z-report
  deleted_at     timestamptz
);

create table if not exists orders (
  id            uuid primary key default gen_random_uuid(),
  status        order_status not null default 'open',
  table_label   text,
  payment_type  payment_type,
  tab_account_id uuid references tab_accounts (id),
  total         numeric(12,2) not null default 0,
  opened_by     uuid references profiles (id),
  shift_id      uuid references shifts (id),
  created_at    timestamptz not null default now(),
  closed_at     timestamptz,
  deleted_at    timestamptz
);

create table if not exists order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references orders (id),
  product_id  uuid not null references products (id),
  qty         numeric(14,3) not null default 1,
  unit_price  numeric(12,2) not null default 0,
  note        text,
  is_comp     boolean not null default false,
  is_void     boolean not null default false,
  station     product_station not null default 'none',
  kds_status  kds_status not null default 'new',
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists tab_entries (
  id             uuid primary key default gen_random_uuid(),
  tab_account_id uuid not null references tab_accounts (id),
  order_id       uuid references orders (id),
  amount         numeric(12,2) not null,
  settled        boolean not null default false,
  created_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

-- ---- Procurement & Suppliers -------------------------------------------------
create table if not exists suppliers (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  contact     text,
  notes       text,
  created_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

create table if not exists supplier_prices (
  id           uuid primary key default gen_random_uuid(),
  supplier_id  uuid not null references suppliers (id),
  product_id   uuid not null references products (id),
  price        numeric(12,2) not null,
  recorded_at  timestamptz not null default now(),
  deleted_at   timestamptz
);

create table if not exists purchase_orders (
  id           uuid primary key default gen_random_uuid(),
  supplier_id  uuid not null references suppliers (id),
  status       po_status not null default 'draft',
  created_by   uuid references profiles (id),
  created_at   timestamptz not null default now(),
  received_at  timestamptz,
  deleted_at   timestamptz
);

create table if not exists purchase_order_items (
  id          uuid primary key default gen_random_uuid(),
  po_id       uuid not null references purchase_orders (id),
  product_id  uuid not null references products (id),
  qty         numeric(14,3) not null,
  unit_price  numeric(12,2) not null,
  deleted_at  timestamptz
);

-- ---- Tasks (Pool) ------------------------------------------------------------
create table if not exists tasks (
  id             uuid primary key default gen_random_uuid(),
  title          text not null,
  description    text,
  is_urgent      boolean not null default false,
  assignee_id    uuid references profiles (id),          -- null = pool
  parent_task_id uuid references tasks (id),             -- blocking sub-task
  is_pool        boolean not null default true,
  status         task_status not null default 'open',
  created_by     uuid references profiles (id),
  created_at     timestamptz not null default now(),
  closed_by      uuid references profiles (id),
  closed_at      timestamptz,
  deleted_at     timestamptz
);

-- Parent cannot be closed while any child sub-task is still open (brief §4).
create or replace function assert_subtasks_done() returns trigger as $$
begin
  if new.status = 'done' and (old.status is distinct from 'done') then
    if exists (
      select 1 from tasks c
      where c.parent_task_id = new.id
        and c.status = 'open'
        and c.deleted_at is null
    ) then
      raise exception 'Cannot close task %: open sub-tasks remain', new.id;
    end if;
  end if;
  return new;
end $$ language plpgsql;

drop trigger if exists trg_assert_subtasks_done on tasks;
create trigger trg_assert_subtasks_done
  before update on tasks
  for each row execute function assert_subtasks_done();

-- ---- Helpful indexes ---------------------------------------------------------
create index if not exists idx_products_active on products (deleted_at) where deleted_at is null;
create index if not exists idx_movements_product on stock_movements (product_id);
create index if not exists idx_order_items_order on order_items (order_id);
create index if not exists idx_order_items_kds on order_items (station, kds_status) where deleted_at is null;
create index if not exists idx_tasks_pool on tasks (is_pool, assignee_id, status) where deleted_at is null;
