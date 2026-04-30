import { Injectable, Pipe, PipeTransform } from '@angular/core';
import EN from '../../../locale/TRANSLATIONS_EN.json';
import NL from '../../../locale/TRANSLATIONS_NL.json';

const LOCALE_MAP: Record<string, Record<string, unknown>> = { en: EN, nl: NL };

function detectLocale(): string {
  const param = new URLSearchParams(window.location.search).get('lang');
  if (param && param in LOCALE_MAP) return param;
  const stored = typeof localStorage !== 'undefined' ? localStorage.getItem('locale') : null;
  if (stored && stored in LOCALE_MAP) return stored;
  return 'en';
}

const TRANSLATIONS: Record<string, unknown> = LOCALE_MAP[detectLocale()];

@Pipe({ name: 'translate', pure: true, standalone: true })
@Injectable({ providedIn: 'root' })
export class I18nTranslatePipe implements PipeTransform {
  transform(key: string, options?: Record<string, unknown> & { defaultValue?: string; emptyIfMissing?: boolean }): string {
    if (!key) return '';

    const raw = this.lookup(key);
    const resolved = raw === key ? (options?.defaultValue ?? key) : raw;

    if (options?.emptyIfMissing && resolved === key) return '';

    if (!options || typeof resolved !== 'string') return resolved;

    return resolved.replace(/\{\{(\w+)\}\}/g, (_, k) =>
      k in options ? String(options[k]) : `{{${k}}}`
    );
  }

  private lookup(key: string): string {
    const parts = key.split('.');
    let current: unknown = TRANSLATIONS;
    for (const part of parts) {
      if (current === null || typeof current !== 'object') return key;
      current = (current as Record<string, unknown>)[part];
      if (current === undefined) return key;
    }
    return typeof current === 'string' ? current : key;
  }
}
