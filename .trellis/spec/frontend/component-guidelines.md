# Component Guidelines

> Component patterns, props conventions.

---

## Overview

Components are Vue 3 **Composition API** SFCs (`<script setup lang="ts">`). The project uses TailwindCSS utility classes with dark-mode variants (`dark:` prefix) and `vue-i18n` (`t()` / `useI18n`) for all user-facing strings. Icons come from a shared `Icon` component with named icons.

## Component Structure

- `<script setup lang="ts">` with typed props via `defineProps<{...}>()` and typed emits via `defineEmits<{...}>()`.
- `v-model` conventions: custom inputs use `modelValue` prop + `update:modelValue` emit (see `components/common/Input.vue`).
- Slots for extensibility: `prefix` / `suffix` (inputs), `empty` (DataTable empty state), action columns, etc.
- Reusable logic extracted to composables (e.g. `useTableLoader`, `useClipboard`, `useStepUp`).

## Props Conventions

- Props are explicit and typed; no implicit `any` in prop types.
- Boolean/state props use kebab-case in templates (`:is-loading`), camelCase in script.
- Components accept optional `class` passthrough where the root element should be styleable.
- Accessibility: inputs have labels (`label` prop with `:for="id"`), aria attributes used where relevant.

## Styling

- Tailwind utility classes, not scoped CSS, for the vast majority of styling.
- Dark mode is supported everywhere via `dark:` variants (`text-gray-400 dark:text-dark-400`, `bg-white dark:bg-dark-900`).
- Brand color tokens: `primary-*` / `dark-*` palette; do not hardcode brand hex colors.
- Responsive: use `isDesktopViewport`-style composables or Tailwind responsive prefixes; DataTable renders card layout on mobile.

## i18n

- All user-facing strings go through `t('...')` with keys in `i18n/locales/` (multiple languages).
- Do not hardcode UI text in templates.

## Common Patterns (existing components)

- `DataTable.vue` — reusable table with loading skeleton, empty state, selection, actions, responsive mobile cards, pagination.
- `BaseDialog.vue` / `ConfirmDialog.vue` — modal patterns.
- `Input.vue` — form input with label/required/error/slots.
- `AutoRefreshButton.vue` — auto-refresh controls.

## Forbidden Patterns

- `any`-typed props/emits without justification.
- Hardcoded UI strings (bypass i18n).
- Inline API calls inside components (must use `api/` modules).
- Duplicating common UI (build on `components/common/`).
- Mixing Options API with Composition API in new code.

## Common Mistakes

- Forgetting dark-mode variants → component looks broken in dark theme.
- Not using `modelValue`/`update:modelValue` convention → v-model breaks.
- Duplicating DataTable logic instead of reusing the shared component.
