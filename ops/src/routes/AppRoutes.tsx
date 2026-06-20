import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { homePathForRole } from "../nav/navConfig";
import AppShell from "../components/AppShell";
import RoleRoute from "../components/RoleRoute";
import LoginScreen from "../screens/LoginScreen";
import ModuleScreen from "../screens/ModuleScreen";
import NotFoundScreen from "../screens/NotFoundScreen";

// Wraps a screen in the shell + role guard.
function Guarded({ children }: { children: React.ReactNode }) {
  return (
    <RoleRoute>
      <AppShell>{children}</AppShell>
    </RoleRoute>
  );
}

export default function AppRoutes() {
  const { session } = useAuth();

  return (
    <Routes>
      <Route
        path="/login"
        element={
          session ? <Navigate to={homePathForRole(session.role)} replace /> : <LoginScreen />
        }
      />

      <Route
        path="/"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.dashboard.title" bodyKey="screen.dashboard.body" />
          </Guarded>
        }
      />
      <Route
        path="/tasks"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.tasks.title" bodyKey="screen.tasks.body" phase={1} />
          </Guarded>
        }
      />
      <Route
        path="/stock"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.stock.title" bodyKey="screen.stock.body" phase={1} />
          </Guarded>
        }
      />
      <Route
        path="/pos"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.pos.title" bodyKey="screen.pos.body" phase={2} />
          </Guarded>
        }
      />
      <Route
        path="/kds"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.kds.title" bodyKey="screen.kds.body" phase={2} />
          </Guarded>
        }
      />
      <Route
        path="/procurement"
        element={
          <Guarded>
            <ModuleScreen
              titleKey="screen.procurement.title"
              bodyKey="screen.procurement.body"
              phase={3}
            />
          </Guarded>
        }
      />
      <Route
        path="/reports"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.reports.title" bodyKey="screen.reports.body" phase={3} />
          </Guarded>
        }
      />
      <Route
        path="/users"
        element={
          <Guarded>
            <ModuleScreen titleKey="screen.users.title" bodyKey="screen.users.body" phase={0} />
          </Guarded>
        }
      />

      <Route
        path="*"
        element={
          session ? (
            <AppShell>
              <NotFoundScreen />
            </AppShell>
          ) : (
            <Navigate to="/login" replace />
          )
        }
      />
    </Routes>
  );
}
