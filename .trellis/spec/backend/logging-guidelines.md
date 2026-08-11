# Logging Guidelines

> Log levels, format, what to log.

---

## Overview

The backend uses **structured logging** with `zap` (uber-go/zap) under `internal/pkg/logger`, which also bridges to `log/slog` (`slog_handler.go`) and the standard library. Logging is initialized at startup via `logger.InitBootstrap()` and flushed via `logger.Sync()`.

## Format

- **Structured key-value logs** with `zap.Field` (e.g. `zap.String`, `zap.Int64`, `zap.Any`, `zap.Error`).
- Message strings use dot-separated event names in English, e.g. `"gateway.user_slot_acquire_failed"`, `"gateway.billing_eligibility_check_failed"`.
- Bootstrap/startup logging uses `log` / `slog` before the logger is fully configured.

## Levels

- `Debug` — request payload dumps, detailed routing diagnostics (enabled in non-release mode).
- `Info` — normal lifecycle events: request completion, billing events, cache refreshes.
- `Warn` — recoverable anomalies: failover, retry, degraded paths, slot acquisition failures.
- `Error` — unrecoverable failures that need investigation.

## What to Log

Always include enough context to correlate a request:

- `user_id`, `api_key_id`, `group_id` (as `zap.Int64`)
- `model`, `stream` flags
- `session_hash` / session binding info
- upstream account ID, platform, error details (`zap.Error`)
- request IDs where present

Use request-scoped loggers derived from the request context (`reqLog = baseLog.With(...)`) so fields stay consistent within one request lifecycle.

## Sensitive Data

- **Never log credentials, tokens, cookies, or account secrets.**
- Credential redaction is enforced via `internal/service/account_credentials_redact.go`; keep redaction logic centralized there.
- Do not log full Authorization headers or raw OAuth tokens.

## Runtime Logging Config

Admin-facing runtime log level configuration is supported (see ops routes `/ops/runtime/logging` and `opsService`); respect configured levels when emitting logs.

## Forbidden Patterns

- `fmt.Println` / ad-hoc logging outside `pkg/logger` unless it is a bootstrap path.
- Logging raw secrets or full request bodies without redaction.
- Inconsistent field naming across packages (use the shared context keys in `pkg/ctxkey`).

## Common Mistakes

- Forgetting to add correlation fields (`user_id`, `api_key_id`) → hard to trace a request through logs.
- Logging at `Info` for per-request hot paths in production → log noise; prefer `Debug` for high-frequency detail.
