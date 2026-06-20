import { useI18n } from "../i18n";
import type { TranslationKey } from "../i18n/tr";

type Props = {
  titleKey: TranslationKey;
  bodyKey: TranslationKey;
  phase?: number;
};

// Phase 0 placeholder: every module is present in the shell but empty.
export default function ModuleScreen({ titleKey, bodyKey, phase }: Props) {
  const { t } = useI18n();
  return (
    <section className="module">
      <header className="module__head">
        <h1 className="module__title">{t(titleKey)}</h1>
        {phase != null && (
          <span className="label">
            {t("common.phase")} {phase}
          </span>
        )}
      </header>
      <p className="module__body">{t(bodyKey)}</p>
      <p className="label module__note">{t("common.comingSoon")}</p>
    </section>
  );
}
