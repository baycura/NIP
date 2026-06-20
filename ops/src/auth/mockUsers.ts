import type { MockUser } from "./types";

// The five named users from the brief (§3). PINs are demo-only placeholders
// for the shared-device flow and will be replaced by real Supabase auth.
export const MOCK_USERS: MockUser[] = [
  {
    id: "u_omer",
    name: "Omer",
    role: "super_admin",
    email: "omer@notinparis.me",
    pin: "1001",
    lang: "tr",
    active: true,
    deletedAt: null
  },
  {
    id: "u_ceren",
    name: "Ceren",
    role: "manager",
    email: "ceren@notinparis.me",
    pin: "1002",
    lang: "tr",
    active: true,
    deletedAt: null
  },
  {
    id: "u_fatih",
    name: "Fatih",
    role: "manager",
    email: "fatih@notinparis.me",
    pin: "1003",
    lang: "tr",
    active: true,
    deletedAt: null
  },
  {
    id: "u_mustafa",
    name: "Mustafa",
    role: "operations",
    email: "mustafa@notinparis.me",
    pin: "1004",
    lang: "tr",
    active: true,
    deletedAt: null
  },
  {
    id: "u_burcu",
    name: "Burcu",
    role: "staff",
    email: "burcu@notinparis.me",
    pin: "1005",
    lang: "tr",
    active: true,
    deletedAt: null
  }
];

/** Only non-deleted, active users participate in auth (soft-delete aware). */
export const activeUsers = () =>
  MOCK_USERS.filter((u) => u.active && u.deletedAt === null);

export const findUserByPin = (pin: string): MockUser | undefined =>
  activeUsers().find((u) => u.pin === pin);

export const findUserById = (id: string): MockUser | undefined =>
  activeUsers().find((u) => u.id === id);
