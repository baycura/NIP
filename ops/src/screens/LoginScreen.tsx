import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { activeUsers } from "../auth/mockUsers";
import { homePathForRole } from "../nav/navConfig";
import { useI18n } from "../i18n";
import type { TranslationKey } from "../i18n/tr";
import LangToggle from "../components/LangToggle";

export default function LoginScreen() {
  const { loginWithPasskey, loginWithPin, loginStation } = useAuth();
  const { t } = useI18n();
  const navigate = useNavigate();

  const [pin, setPin] = useState("");
  const [pinError, setPinError] = useState(false);

  const go = (path: string) => navigate(path, { replace: true });

  const onPasskey = (userId: string, role: ReturnType<typeof activeUsers>[number]["role"]) => {
    if (loginWithPasskey(userId)) go(homePathForRole(role));
  };

  const onPin = (e: React.FormEvent) => {
    e.preventDefault();
    if (loginWithPin(pin)) {
      const role = activeUsers().find((u) => u.pin === pin)!.role;
      go(homePathForRole(role));
    } else {
      setPinError(true);
    }
  };

  const onStation = (station: "kitchen" | "bar") => {
    loginStation(station);
    go(homePathForRole("station"));
  };

  return (
    <div className="login">
      <div className="login__top">
        <div className="login__brand">
          <span className="login__title">{t("app.title")}</span>
          <span className="label">{t("app.subtitle")}</span>
        </div>
        <LangToggle />
      </div>

      <div className="login__panels">
        {/* Personal — Passkey */}
        <section className="panel">
          <h2 className="panel__title">{t("login.personal.title")}</h2>
          <p className="label">{t("login.personal.hint")}</p>
          <div className="panel__list">
            {activeUsers().map((u) => (
              <button
                key={u.id}
                className="btn btn--block"
                onClick={() => onPasskey(u.id, u.role)}
              >
                {u.name} · {t(`role.${u.role}` as TranslationKey)}
              </button>
            ))}
          </div>
        </section>

        {/* Shared device — PIN */}
        <section className="panel">
          <h2 className="panel__title">{t("login.pin.title")}</h2>
          <p className="label">{t("login.pin.hint")}</p>
          <form className="stack" onSubmit={onPin}>
            <input
              inputMode="numeric"
              autoComplete="off"
              placeholder={t("login.pin.placeholder")}
              value={pin}
              onChange={(e) => {
                setPin(e.target.value.replace(/\D/g, ""));
                setPinError(false);
              }}
              aria-invalid={pinError}
            />
            {pinError && <span className="login__error">{t("login.pin.error")}</span>}
            <button className="btn btn--primary btn--block" type="submit" disabled={!pin}>
              {t("login.pin.action")}
            </button>
          </form>
        </section>

        {/* Station displays */}
        <section className="panel">
          <h2 className="panel__title">{t("login.station.title")}</h2>
          <p className="label">{t("login.station.hint")}</p>
          <div className="row">
            <button className="btn btn--block" onClick={() => onStation("kitchen")}>
              {t("station.kitchen")}
            </button>
            <button className="btn btn--block" onClick={() => onStation("bar")}>
              {t("station.bar")}
            </button>
          </div>
        </section>
      </div>

      <p className="label login__mock">{t("login.mock.note")}</p>
    </div>
  );
}
