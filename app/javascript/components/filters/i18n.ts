// @ts-expect-error -- locale.js has no type declarations
import { getBrowserLocale } from "@/utils/locale";
import en from "./locales/en.json";
import ptBR from "./locales/pt-BR.json";
import es from "./locales/es.json";

type TranslationMap = Record<string, Record<string, string>>;

const TRANSLATIONS: Record<string, TranslationMap> = {
  en,
  "pt-br": ptBR,
  es,
};

function resolveLocale(locale: string): string {
  const normalized = locale.toLowerCase();

  if (TRANSLATIONS[normalized]) return normalized;

  const lang = normalized.split("-")[0];
  if (TRANSLATIONS[lang]) return lang;

  return "en";
}

let cachedLocale: string | null = null;

function getCurrentLocale(): string {
  if (!cachedLocale) {
    cachedLocale = resolveLocale(getBrowserLocale());
  }
  return cachedLocale;
}

export function t(scope: string, key: string): string {
  const locale = getCurrentLocale();
  const translations = TRANSLATIONS[locale];
  return translations?.[scope]?.[key] ?? TRANSLATIONS.en[scope]?.[key] ?? key;
}

export function tOperator(key: string): string {
  return t("operators", key);
}

export function tFilter(key: string): string {
  return t("filter", key);
}
