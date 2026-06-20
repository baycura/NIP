import { Navigate, useLocation } from "react-router-dom";
import type { ReactNode } from "react";
import { useAuth } from "../auth/AuthContext";
import { canAccess, homePathForRole } from "../nav/navConfig";

// Route guard: must be signed in, and the role must be allowed on this path.
// This is UI gating; Supabase RLS is the real enforcement layer.
export default function RoleRoute({ children }: { children: ReactNode }) {
  const { session } = useAuth();
  const location = useLocation();

  if (!session) return <Navigate to="/login" replace />;

  if (!canAccess(session.role, location.pathname)) {
    return <Navigate to={homePathForRole(session.role)} replace />;
  }

  return <>{children}</>;
}
