import type { Role } from "../auth/types";
import type { TranslationKey } from "../i18n/tr";

export type NavItem = {
  id: string;
  path: string;
  labelKey: TranslationKey;
  /** Which roles see this module in nav AND may route to it. */
  roles: Role[];
};

// Single source of truth for role-based navigation + routing (brief §3).
// UI gating only — Supabase RLS independently enforces data access.
export const NAV_ITEMS: NavItem[] = [
  {
    id: "dashboard",
    path: "/",
    labelKey: "nav.dashboard",
    roles: ["super_admin", "manager", "operations", "staff"]
  },
  {
    id: "tasks",
    path: "/tasks",
    labelKey: "nav.tasks",
    roles: ["super_admin", "manager", "operations", "staff"]
  },
  {
    id: "stock",
    path: "/stock",
    labelKey: "nav.stock",
    roles: ["super_admin", "manager", "operations", "staff"]
  },
  {
    id: "pos",
    path: "/pos",
    labelKey: "nav.pos",
    roles: ["super_admin", "manager", "operations", "staff"]
  },
  {
    id: "kds",
    path: "/kds",
    labelKey: "nav.kds",
    // Kitchen/Bar display: station + those who oversee service.
    roles: ["super_admin", "manager", "station"]
  },
  {
    id: "procurement",
    path: "/procurement",
    labelKey: "nav.procurement",
    // Mustafa (operations) enters invoices/costs; staff (Burcu) cannot see costs.
    roles: ["super_admin", "manager", "operations"]
  },
  {
    id: "reports",
    path: "/reports",
    labelKey: "nav.reports",
    // Profit/aggregate financials: managers + super admin only.
    roles: ["super_admin", "manager"]
  },
  {
    id: "users",
    path: "/users",
    labelKey: "nav.users",
    // Only super_admin (Omer) manages users/roles.
    roles: ["super_admin"]
  }
];

export const navForRole = (role: Role): NavItem[] =>
  NAV_ITEMS.filter((item) => item.roles.includes(role));

export const canAccess = (role: Role, path: string): boolean => {
  const item = NAV_ITEMS.find((i) => i.path === path);
  return item ? item.roles.includes(role) : false;
};

/** Where each role lands right after login. */
export const homePathForRole = (role: Role): string =>
  role === "station" ? "/kds" : "/";
