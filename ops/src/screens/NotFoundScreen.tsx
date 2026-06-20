import { useI18n } from "../i18n";

export default function NotFoundScreen() {
  const { t } = useI18n();
  return (
    <section className="module">
      <header className="module__head">
        <h1 className="module__title">{t("screen.notFound.title")}</h1>
      </header>
      <p className="module__body">{t("screen.notFound.body")}</p>
    </section>
  );
}
