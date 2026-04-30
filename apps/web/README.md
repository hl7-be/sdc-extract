# Frontend — FHIR Questionnaire Mapper

Angular 18 application for annotating FHIR Questionnaires and extracting structured FHIR resources from QuestionnaireResponses.

## Prerequisites

- [Node.js](https://nodejs.org/) 18 or higher
- [npm](https://www.npmjs.com/) (bundled with Node.js)
- A running backend (see `../api/README.md`)

## Getting started

```bash
cd web
npm install
npm start
```

The app will be available at **http://localhost:4200**.  
API calls are proxied to `http://localhost:8000` via `proxy.conf.json`.

## Translations (i18n)

Translation files live in `src/locale/`:

| File | Language |
|------|----------|
| `TRANSLATIONS_EN.json` | English (default) |
| `TRANSLATIONS_NL.json` | Dutch |

**English is used by default.** To switch language at runtime, append `?lang=nl` to any URL, or set `locale` in `localStorage`:

```js
// In the browser console
localStorage.setItem('locale', 'nl');
location.reload();
```

To go back to English:

```js
localStorage.removeItem('locale');
location.reload();
```

The language is detected once at startup (page load). Refreshing the page is required after changing it.

### Adding or updating translations

1. Edit `src/locale/TRANSLATIONS_EN.json` and `src/locale/TRANSLATIONS_NL.json`.
2. Both files must contain the same set of keys.
3. Keys follow a flat dot-notation path that mirrors the nested JSON structure, e.g. `wizard.alert.no-resource-categories.title`.
4. Template placeholders use the `{{variableName}}` syntax and are resolved at runtime.

## Build

```bash
npm run build
```

Build artifacts are written to `dist/frontend/`.

## Code scaffolding

```bash
npx ng generate component path/to/my-component
```

