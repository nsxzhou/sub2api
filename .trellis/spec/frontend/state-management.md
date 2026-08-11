# State Management

> Local state, global state, server state.

---

## Overview

State management uses **Pinia** for global/shared state, Vue Composition API (`ref`/`computed`) for local component state, and **server state lives in API responses** (no dedicated data-fetching library like TanStack Query). The axios client + stores handle auth/token persistence and caching.

## Where State Lives

| State | Mechanism | Examples |
|---|---|---|
| Component-local ephemeral state | `ref` / `reactive` in `<script setup>` | form inputs, toggles |
| Shared app-wide state | Pinia store (`defineStore`) | auth, app config, payment, subscriptions |
| Server data | API calls via `api/` modules; stores may cache | users list, usage, orders |
| Cross-component reusable logic | composables | table loader, selection |

## Pinia Stores

- Stores live in `frontend/src/stores/` (e.g. `auth.ts`, `app.ts`, `payment.ts`, `subscriptions.ts`, `adminSettings.ts`, `adminCompliance.ts`, `announcements.ts`, `onboarding.ts`).
- Use `defineStore('name', () => {...})` setup-style with `ref`/`computed` (composition stores).
- Auth store (`stores/auth.ts`) owns tokens: `auth_token`, `refresh_token`, expiry timestamp, persisted user, token auto-refresh (60s interval, 120s buffer), pending auth session handling.
- Stores call `api/` modules for data; components read store state and call store actions.
- Token refresh is centralized (`api/tokenRefresh.ts`) and wired into the axios interceptor.

## Rules

- Do not put API calls directly in components; route through `api/` modules (optionally wrapped by store actions).
- Keep stores focused: one domain per store; split `adminSettings`/`adminCompliance` rather than a monolithic admin store.
- Local state stays local; only promote to a store when multiple unrelated components need it.
- Server data that is fetched per-view may live in the view (via composables) rather than a store — avoid premature caching.

## Forbidden Patterns

- `localStorage` manipulation scattered across components (auth persistence is centralized in `stores/auth.ts`).
- Directly mutating another store's state from a component.
- Global mutable singletons outside Pinia.

## Common Mistakes

- Duplicating auth/token logic in components instead of using the auth store.
- Storing server responses in multiple stores → inconsistent cache.
- Forgetting to refresh token → 401 after expiry (use the interceptor + `tokenRefresh.ts`).
