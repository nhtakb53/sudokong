import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { getLocales } from 'expo-localization';
import ko from './locales/ko/common.json';
import en from './locales/en/common.json';

const deviceLang = getLocales()[0]?.languageCode ?? 'en';
const initial = deviceLang === 'ko' ? 'ko' : 'en';

void i18n.use(initReactI18next).init({
  resources: {
    ko: { common: ko },
    en: { common: en },
  },
  lng: initial,
  fallbackLng: 'en',
  defaultNS: 'common',
  interpolation: { escapeValue: false },
  compatibilityJSON: 'v4',
});

export default i18n;
