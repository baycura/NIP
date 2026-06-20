import { NavLink } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { useI18n } from "../i18n";
import { navForRole } from "../nav/navConfig";

export default function BottomNav() {
  const { session } = useAuth();
  const { t } = useI18n();
  if (!session) return null;

  const items = navForRole(session.role);
  if (items.length <= 1) return null; // e.g. station: single screen, no nav needed

  return (
    <nav className="bottom-nav" aria-label="primary">
      {items.map((item) => (
        <NavLink
          key={item.id}
          to={item.path}
          end={item.path === "/"}
          className={({ isActive }) =>
            "bottom-nav__item" + (isActive ? " is-active" : "")
          }
        >
          {t(item.labelKey)}
        </NavLink>
      ))}
    </nav>
  );
}
