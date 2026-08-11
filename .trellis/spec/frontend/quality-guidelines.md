# Quality Guidelines

> Linting, testing, accessibility.

---

## Overview

Frontend quality is enforced through ESLint (TypeScript + Vue), Vitest unit tests, type checking (`vue-tsc` via `vite-plugin-checker`), and pnpm-lockfile consistency. CI runs these in GitHub Actions (`backend-ci.yml`, `security-scan.yml` includes `pnpm audit`).

## Toolchain

- Package manager: **pnpm only** (CI uses `pnpm install --frozen-lockfile`; `pnpm-lock.yaml` must be committed).
- Scripts (in `frontend/package.json`): `pnpm dev`, `pnpm build`, `pnpm test`, `pnpm lint` (ESLint).
- Type checking runs through `vite-plugin-checker` during dev/build; `vue-tsc` is the Vue type checker.
- Tests: Vitest + `@vue/test-utils` + jsdom.

## Testing Requirements

- Unit/component tests colocated under `__tests__/` next to source: `composables/__tests__/useClipboard.spec.ts`, `utils/__tests__/...`, `stores/__tests__/...`, `router/__tests__/...`, `views/__tests__/...`.
- Test files use `.spec.ts` suffix.
- Component tests render components with `@vue/test-utils`, mock `api/` modules and stores, and assert rendered output/emits.
- Integration-style flows exist under `src/__tests__/integration/`.

## Linting & Format

- ESLint with `@typescript-eslint` + `eslint-plugin-vue`; keep new code lint-clean.
- Consistent import ordering and type-only imports (`import type`).
- Tailwind class conventions; no stray CSS files unless necessary.

## Accessibility

- Inputs have labels (`:for` matching `id`) and required indicators.
- Interactive elements expose appropriate roles/aria attributes.
- Color contrast handled through the design tokens; dark mode supported.
- Reusable components (DataTable, Dialog) provide accessible empty states and keyboard-friendly interactions where implemented.

## PR Checklist (frontend-relevant)

- [ ] `pnpm install --frozen-lockfile` succeeds (lockfile synced when package.json changes)
- [ ] `pnpm lint` has no new issues
- [ ] `pnpm build` (incl. type check) passes
- [ ] `pnpm test` passes (Vitest)
- [ ] New UI strings added to i18n locales (all supported languages)
- [ ] Dark mode + responsive checked for new components

## Forbidden Patterns

- Using npm to install/manage dependencies (must be pnpm).
- Committing `node_modules` or stray lockfiles.
- Skipping i18n keys (hardcoded strings).
- `@ts-ignore` without justification.

## Common Mistakes

- Adding a dependency to `package.json` without committing `pnpm-lock.yaml` (CI `--frozen-lockfile` fails — see `DEV_GUIDE.md` pitfall #1).
- Mixing npm-generated `node_modules` with pnpm (`EPERM` errors — pitfall #2).
- Type errors surfacing only in CI because local `pnpm build` was skipped.
