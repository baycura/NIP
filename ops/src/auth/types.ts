// Roles map 1:1 to the brief (§3) and to the DB `profiles.role` column.
// RLS in Supabase is the real source of truth; these types drive UI gating only.
export type Role = "super_admin" | "manager" | "operations" | "staff" | "station";

export type StationKind = "kitchen" | "bar";

export type Lang = "tr" | "en";

export type MockUser = {
  id: string;
  name: string;
  role: Exclude<Role, "station">;
  email: string;
  /** Demo-only PIN for the shared-device flow. Never used in production auth. */
  pin: string;
  lang: Lang;
  active: boolean;
  /** Soft-delete convention from day one (brief §3.1). */
  deletedAt: string | null;
};

export type PersonalSession = {
  kind: "personal";
  userId: string;
  role: Exclude<Role, "station">;
  name: string;
  /** "passkey" or "pin" — how identity was established on this device. */
  via: "passkey" | "pin";
};

export type StationSession = {
  kind: "station";
  role: "station";
  station: StationKind;
};

export type Session = PersonalSession | StationSession;
