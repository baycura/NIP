# NOT IN PARIS — Operations System

Role-based, mobile-first PWA for the NIP café/bar + concept store: stock, recipes,
POS, kitchen display, procurement, invoice OCR and a task pool. Built on React +
Vite, backed (later) by Supabase. Visual identity is layered separately via design
tokens — components stay semantic and unstyled-but-structured.

This app lives in `ops/` and is independent of the reservation app at the repo root.

## Status — Phase 0 (Foundation)

Running on **mock/in-memory auth + data** for now. Supabase is wired later via MCP.

Built so far:
- Mobile-first app shell, sticky header + scrollable content + bottom nav
- TR/EN i18n (Turkish default, toggle persisted)
- Auth flows (mock): **Passkey** (personal), **PIN** (shared device), **Station** (MUTFAK/BAR)
- Role-based routing + nav per role (5 roles + station), route guard
- Soft-delete convention modeled in the data layer and the SQL schema
- Supabase deliverables ready to apply: `supabase/01_schema.sql`, `02_rls.sql`, `03_seed.sql`

## Run

```bash
cd ops
npm install
npm run dev        # http://localhost:5173
```

Other scripts: `npm run build`, `npm run preview`, `npm run typecheck`.

### Demo logins (mock)

| Path | How |
| --- | --- |
| Personal (Passkey) | Tap a name on the login screen |
| Shared device (PIN) | Omer `1001`, Ceren `1002`, Fatih `1003`, Mustafa `1004`, Burcu `1005` |
| Station | Tap **MUTFAK** or **BAR** |

Each role sees a different bottom-nav set; the station lands directly on the
Kitchen screen. PINs are demo-only and disappear once real Supabase auth is on.

## Supabase (deferred wiring)

`supabase/*.sql` is runnable on a fresh project (apply in order). Highlights:
- All tables carry `deleted_at` (soft-delete from day one)
- RLS enabled on every table; `app_role()` drives policies
- **Mustafa rule**: `operations` can *insert* costs/prices but cannot *select*
  supplier prices or the `v_profit_margin` aggregate view
- `v_products_public` exposes the catalog without cost columns for staff/station

## Roles → navigation

| Role | Modules |
| --- | --- |
| super_admin (Omer) | Home, Tasks, Stock, Sell, Kitchen, Purchasing, Reports, Users |
| manager (Ceren, Fatih) | Home, Tasks, Stock, Sell, Kitchen, Purchasing, Reports |
| operations (Mustafa) | Home, Tasks, Stock, Sell, Purchasing |
| staff (Burcu) | Home, Tasks, Stock, Sell |
| station (MUTFAK/BAR) | Kitchen only |
