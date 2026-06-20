import type { TranslationKey } from "./tr";

// English toggle. Must mirror every key in tr.ts.
const en: Record<TranslationKey, string> = {
  "app.title": "NOT IN PARIS",
  "app.subtitle": "Operations System",

  "lang.tr": "TR",
  "lang.en": "EN",

  "login.personal.title": "Personal sign-in",
  "login.personal.hint": "With a passkey (Face ID / fingerprint)",
  "login.personal.action": "Sign in with passkey",
  "login.pin.title": "Shared device",
  "login.pin.hint": "Who is acting? Enter PIN",
  "login.pin.placeholder": "PIN",
  "login.pin.action": "Enter",
  "login.pin.error": "Wrong PIN",
  "login.station.title": "Station display",
  "login.station.hint": "Shared view for a tablet",
  "login.mock.note":
    "Demo mode: real passkey/PIN verification activates once Supabase is connected.",

  "station.kitchen": "KITCHEN",
  "station.bar": "BAR",

  "nav.dashboard": "Home",
  "nav.tasks": "Tasks",
  "nav.stock": "Stock",
  "nav.pos": "Sell",
  "nav.kds": "Kitchen",
  "nav.procurement": "Purchasing",
  "nav.reports": "Reports",
  "nav.users": "Users",
  "nav.more": "More",

  "common.logout": "Sign out",
  "common.comingSoon": "This module arrives in a later phase.",
  "common.phase": "Phase",
  "common.role": "Role",

  "role.super_admin": "Super admin",
  "role.manager": "Manager",
  "role.operations": "Operations",
  "role.staff": "Staff",
  "role.station": "Station",

  "screen.dashboard.title": "Home",
  "screen.dashboard.body": "Daily pulse, critical stock and summaries will live here.",
  "screen.tasks.title": "Task Pool",
  "screen.tasks.body":
    "Create, claim and close tasks. Urgent flag and sub-task locking land in Phase 1.",
  "screen.stock.title": "Stock & Products",
  "screen.stock.body": "Product catalog, stock movements and critical-stock alerts in Phase 1.",
  "screen.pos.title": "Fast POS",
  "screen.pos.body": "Fast POS, favorites and multi-tab orders in Phase 2.",
  "screen.kds.title": "Kitchen Display",
  "screen.kds.body": "Real-time order flow (New → Ready) in Phase 2.",
  "screen.procurement.title": "Purchasing",
  "screen.procurement.body": "Suppliers, purchase orders and invoice OCR in Phase 3.",
  "screen.reports.title": "Reports",
  "screen.reports.body": "Profit margin, bonus stats and detailed reports in Phase 3–4.",
  "screen.users.title": "Users",
  "screen.users.body": "User and role management (super admin only).",
  "screen.notFound.title": "Not found",
  "screen.notFound.body": "You don't have access to this page, or it doesn't exist."
};

export default en;
