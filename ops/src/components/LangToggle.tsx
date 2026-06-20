import { useI18n } from "../i18n";

export default function LangToggle() {
  const { lang, setLang, t } = useI18n();
  return (
    <div className="row" role="group" aria-label="language">
      <button
        className="lang-btn"
        aria-pressed={lang === "tr"}
        onClick={() => setLang("tr")}
      >
        {t("lang.tr")}
      </button>
      <span aria-hidden>/</span>
      <button
        className="lang-btn"
        aria-pressed={lang === "en"}
        onClick={() => setLang("en")}
      >
        {t("lang.en")}
      </button>
    </div>
  );
}
