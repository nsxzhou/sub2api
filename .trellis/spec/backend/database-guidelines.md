# Database Guidelines

> ORM, migrations, query patterns, naming conventions.

---

## Overview

The backend uses **Ent ORM** (entgo.io/ent) against **PostgreSQL 15+**, with **Redis** for caching, rate limiting, sessions, and queues. Schema is defined in Go (`backend/ent/schema/`), generated into `backend/ent/`, and changes are applied through SQL migration scripts in `backend/migrations/`.

## ORM / Ent Patterns

- One schema file per entity in `backend/ent/schema/` (40 entities currently).
- Every schema uses `mixins.TimeMixin{}` for `created_at` / `updated_at`; most business entities also use `mixins.SoftDeleteMixin{}` for `deleted_at`-based soft delete.
- **Soft delete is implemented via Ent interceptors/hooks**: queries auto-filter `deleted_at IS NULL`; delete becomes `UPDATE ... SET deleted_at = NOW()`. Use `SkipSoftDelete(ctx)` to bypass when truly needed.
- Unique constraints that must survive soft-delete reuse are implemented as **partial indexes** (`WHERE deleted_at IS NULL`), see `migrations/016_soft_delete_partial_unique_indexes.sql`.
- Some entities intentionally use hard delete (e.g. `payment_order`, `subscription_plan`) — documented in the schema file header; respect the documented rationale.
- Schema documentation comments are written in Chinese and explain entity purpose and deletion policy.

## Migrations

- SQL migration scripts live in `backend/migrations/` and are numbered (`001_init.sql`, `002_...`, ...).
- After editing `ent/schema/*.go`, ALWAYS run `go generate ./ent` (regenerates `backend/ent/`) and commit generated files.
- New schema changes require a matching SQL migration script for existing deployments; keep `migrations/` in sync with schema.

## Query Patterns

- Repositories use the generated Ent client (`dbent.Client`) and typed queries (e.g. `client.Account.Query().Where(...)`).
- Complex queries use raw SQL via the `sql` executor passed into repositories (see `accountRepository` which holds `sqlq sqlExecutor`).
- Pagination uses the shared `internal/pkg/pagination` package (`PaginationParams` / `PaginationResult`).
- Redis caching is used at the repository/service boundary for hot paths (e.g. `api_key_cache.go`, scheduler snapshots) with cache invalidation on writes.
- Usage logs (`usage_log`) are append-only: no updates or deletes.

## Naming Conventions

- Tables/entities: singular lowercase (ent `user`, `api_key`, `usage_log`, `payment_order`).
- Fields: snake_case in DB, mapped through ent fields; timestamps `created_at`/`updated_at`/`deleted_at` from mixins.
- Migration files: `NNN_description.sql` with zero-padded sequence numbers.

## Forbidden Patterns

- Do not hand-edit generated code under `backend/ent/<entity>/`; regenerate instead.
- Do not add new entities without both the schema file and a migration script.
- Do not use `SELECT *` style untyped access in repositories where typed ent queries exist.
- Do not delete rows for soft-deleted entities unless explicitly intended (hard-delete entities are the documented exception).

## Common Mistakes

- Changing `ent/schema` but forgetting `go generate ./ent` → schema changes never take effect (see `DEV_GUIDE.md` pitfall #9).
- Forgetting to commit generated `ent/` files → CI/build failures.
- Adding an interface method in `service` without updating every test stub/mock that implements it (see `DEV_GUIDE.md` pitfall #6).
