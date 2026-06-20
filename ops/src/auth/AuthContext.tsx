import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import type { Session, StationKind } from "./types";
import { findUserById, findUserByPin } from "./mockUsers";

const STORAGE_KEY = "nip.session";

type AuthContextValue = {
  session: Session | null;
  /** Mock passkey login — in production this is WebAuthn via Supabase. */
  loginWithPasskey: (userId: string) => boolean;
  /** Shared-device identity: a short PIN marks who is acting. */
  loginWithPin: (pin: string) => boolean;
  /** Station (MUTFAK / BAR) shared display login. */
  loginStation: (station: StationKind) => void;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

function loadSession(): Session | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as Session) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(loadSession);

  useEffect(() => {
    if (session) localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
    else localStorage.removeItem(STORAGE_KEY);
  }, [session]);

  const loginWithPasskey = useCallback((userId: string) => {
    const user = findUserById(userId);
    if (!user) return false;
    setSession({
      kind: "personal",
      userId: user.id,
      role: user.role,
      name: user.name,
      via: "passkey"
    });
    return true;
  }, []);

  const loginWithPin = useCallback((pin: string) => {
    const user = findUserByPin(pin);
    if (!user) return false;
    setSession({
      kind: "personal",
      userId: user.id,
      role: user.role,
      name: user.name,
      via: "pin"
    });
    return true;
  }, []);

  const loginStation = useCallback((station: StationKind) => {
    setSession({ kind: "station", role: "station", station });
  }, []);

  const logout = useCallback(() => setSession(null), []);

  const value = useMemo(
    () => ({ session, loginWithPasskey, loginWithPin, loginStation, logout }),
    [session, loginWithPasskey, loginWithPin, loginStation, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
