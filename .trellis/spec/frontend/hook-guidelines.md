# Hook Guidelines

> Custom hook (composable) naming, patterns.

---

## Overview

The project uses Vue 3 composables named `useXxx.ts` in `frontend/src/composables/`. They encapsulate reusable logic: clipboard, form handling, table loading/selection, OAuth flows, auto-refresh, pagination persistence, navigation state.

## Naming

- File: `useCamelCase.ts` (e.g. `useClipboard.ts`, `useTableLoader.ts`, `useKeyedDebouncedSearch.ts`).
- Export: a single `useCamelCase` function that returns `{ refs, computed, functions }` (or a narrow typed return).
- Composable names start with `use`.

## Patterns

- Composables receive options via an options object where sensible and return typed values.
- They own their lifecycle: timers/intervals are cleaned up on unmount (`onUnmounted` / `onScopeDispose`).
- Async data loading is centralized in composables like `useTableLoader` (loading/error/data + refresh) instead of duplicated per view.
- UI-agnostic logic (formatting, device detection, clipboard) is reusable; view-specific glue stays in components.
- Composables may call `api/` modules directly (e.g. `useOpenAIOAuth`, `useGrokOAuth`) — this is accepted in this codebase.

## Examples

- `useTableLoader.ts` — paginated table state (loading, items, total, refresh, sort).
- `useTableSelection.ts` — row selection for tables.
- `useForm.ts` — form state + validation helpers.
- `useClipboard.ts` — clipboard copy with feedback.
- `usePersistedPageSize.ts` — persist page size preference.
- `useAutoRefresh.ts` — polling with interval cleanup.

## Forbidden Patterns

- Naming composables without `use` prefix.
- Leaving intervals/timeouts uncleaned on unmount (memory leaks).
- Duplicating `useTableLoader`-style logic per view when the shared composable fits.
- Returning overly broad `any` from composables.

## Common Mistakes

- Forgetting cleanup of watchers/intervals → leaked listeners on route changes.
- Putting component-specific DOM logic into a composable that is supposed to be generic.
