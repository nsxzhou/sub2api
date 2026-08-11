# Type Safety

> TypeScript conventions, type organization.

---

## Overview

The frontend is TypeScript (5.6) with strict typing. Types are centralized in `frontend/src/types/` and imported by API modules, stores, and components. Vite uses `vite-plugin-checker` with `vue-tsc` for type checking in the dev/build pipeline.

## Type Organization

- Shared/core types: `frontend/src/types/index.ts` (e.g. `SelectOption`, `BasePaginationResponse<T>`, `User`, `ApiKey`, request/response types).
- Domain-specific types are colocated with their API modules when not shared (e.g. admin types, payment types) or in `types/` files.
- API response types follow backend contracts: paginated responses use `BasePaginationResponse<T>` (`items`, `total`, `page`, `page_size`, `pages`).

## Conventions

- Prefer `interface` for object shapes, `type` for unions/aliases; both are used in the codebase.
- Import types with `import type { ... }` for type-only imports.
- Generic helpers (`PaginatedResponse<T>`) keep API modules strongly typed.
- Functions in `api/` modules annotate parameter and return types (`Promise<PaginatedResponse<ApiKey>>`).
- Enums in backend are mirrored as union string types or const objects in the frontend (avoid `any`).
- `tsconfig.json` strict mode is on; avoid `@ts-ignore` unless absolutely necessary with justification.

## API Typing

- Each API module returns typed data: `const { data } = await apiClient.get<PaginatedResponse<ApiKey>>(...)`.
- Axios interceptors (`client.ts`) add auth headers, locale, timezone, and handle error responses consistently.
- Window config injection is typed via `declare global { interface Window { __APP_CONFIG__?: PublicSettings } }`.

## Forbidden Patterns

- `any` in props/emits/API returns without justification.
- Casting raw `unknown` payloads inline everywhere; prefer centralized type definitions.
- Duplicating the same type in multiple files; put shared types in `types/`.

## Common Mistakes

- Forgetting `import type` → vue-tsc/eslint type import warnings.
- Response type drift between backend and frontend (e.g. field renamed in Go but not updated in `types/`).
- Using `any` for pagination params/filters, losing autocomplete and safety.
