import { useAuth } from "../auth/AuthContext";
import { useI18n } from "../i18n";
import type { TranslationKey } from "../i18n/tr";
import LangToggle from "./LangToggle";

export default function AppHeader() {
  const { session, logout } = useAuth();
  const { t } = useI18n();

  const roleLabelKey = session ? (`role.${session.role}` as TranslationKey) : null;
  const who =
    session?.kind === "station"
      ? t(session.station === "kitchen" ? "station.kitchen" : "station.bar")
      : session?.name;

  return (
    <header className="app-header">
      <div className="app-header__brand">
        <span className="app-header__title">{t("app.title")}</span>
        <span className="label">{t("app.subtitle")}</span>
      </div>
      <div className="app-header__right">
        <LangToggle />
        {session && (
          <div className="app-header__who">
            <span className="app-header__name">{who}</span>
            {roleLabelKey && <span className="label">{t(roleLabelKey)}</span>}
          </div>
        )}
        <button className="btn" onClick={logout}>
          {t("common.logout")}
        </button>
      </div>
    </header>
  );
}
