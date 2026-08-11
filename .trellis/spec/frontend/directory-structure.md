# Directory Structure

> Component/page/hook organization.

---

## Overview

The frontend is a **Vue 3 + TypeScript + Vite + TailwindCSS** SPA with **Pinia** stores and **vue-i18n** multi-language support. Package management is **pnpm** only (never npm). All source lives under `frontend/src/`.

## Directory Layout

```
frontend/src/
├── api/                      # Axios API layer (one file per domain)
│   ├── client.ts             # Shared axios instance + interceptors (auth, locale, timezone)
│   ├── admin/                # Admin-panel API modules (accounts, groups, ops, ...)
│   └── <domain>.ts           # keys.ts, usage.ts, payment.ts, subscriptions.ts, ...
├── assets/                   # Static assets (icons, images)
├── components/               # Reusable Vue components
│   ├── common/               # Generic UI primitives (Input, DataTable, BaseDialog, ...)
│   ├── admin/                # Admin-specific components (grouped by feature subdirs)
│   ├── user/                 # User-panel components
│   ├── account/              # Account-related components
│   ├── payment/              # Payment components (Stripe, Airwallex, QR)
│   ├── auth/                 # Auth-related components
│   ├── layout/               # Layout components (header, sidebar, etc.)
│   ├── charts/               # Chart.js wrappers
│   └── keys/ channels/ modelPlaza/  # Feature-specific components
├── composables/              # Reusable composition functions (useXxx.ts)
├── i18n/                     # vue-i18n setup + locales/ (multi-language)
├── router/                   # Vue Router config + guards
├── stores/                   # Pinia stores (auth, app, payment, subscriptions, ...)
├── types/                    # Shared TypeScript types (index.ts + domain types)
├── utils/                    # Utility functions (formatting, device, ...)
├── views/                    # Route-level page components
│   ├── admin/                # Admin pages (97 files)
│   ├── user/                 # User panel pages
│   ├── auth/                 # Auth pages (login/register/OAuth callbacks)
│   ├── setup/                # First-run setup wizard
│   └── public/               # Public pages (Home, Model Plaza, Key Usage)
└── main.ts / App.vue
```

## Module Organization

- **Pages** live in `views/`; each route component is lazy-loaded via `router/index.ts`.
- **Reusable UI** lives in `components/common/`; feature-specific components live under `components/<feature>/` (e.g. `components/admin/account/`, `components/payment/`).
- **API calls** never happen inline in components: all HTTP goes through `api/` modules using the shared `apiClient`.
- **Shared state** lives in Pinia `stores/`; ephemeral component state stays local (`ref`/`reactive`).
- **Composition functions** (`useXxx`) live in `composables/` when logic is reused across components.
- **Types** are centralized in `types/` and imported by both `api/` and components.

## Naming Conventions

- Vue components: `PascalCase.vue` (e.g. `DataTable.vue`, `BaseDialog.vue`).
- Views: `XxxView.vue` (e.g. `AccountsView.vue`, `KeysView.vue`, `PaymentView.vue`).
- Composables: `useCamelCase.ts` (e.g. `useClipboard.ts`, `useTableLoader.ts`).
- API modules: lowercase domain names (`keys.ts`, `usage.ts`).
- Stores: camelCase (`auth.ts`, `adminSettings.ts`).
- Test files: colocated under `__tests__/` next to source (`composables/__tests__/useClipboard.spec.ts`, `utils/__tests__/...`).

## Examples

- Reference view: `frontend/src/views/admin/AccountsView.vue`
- Reference component: `frontend/src/components/common/DataTable.vue` (responsive, dark-mode aware, slots)
- Reference composable: `frontend/src/composables/useTableLoader.ts`
- Reference API module: `frontend/src/api/keys.ts`
- Reference store: `frontend/src/stores/auth.ts`
