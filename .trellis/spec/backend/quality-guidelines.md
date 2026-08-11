# Quality Guidelines

> Code review standards, testing requirements.

---

## Overview

Quality is enforced by unit/integration tests, `golangci-lint` (v2.7), Go formatting, and a PR checklist documented in `DEV_GUIDE.md`. CI runs these in GitHub Actions (`backend-ci.yml`, `security-scan.yml`).

## Language & Toolchain

- Go version **1.25.7** (CI requirement).
- Linter: `golangci-lint` v2.7 (`go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.7`).
- Formatting: `gofmt`; keep code gofmt-clean (recent commits include `gofmt` fixes).

## Testing Requirements

- **Unit tests**: `cd backend && go test -tags=unit ./...`
- **Integration tests**: `cd backend && go test -tags=integration ./...`
- Both tags are used throughout the codebase; tests are colocated next to source files (`gateway_handler_billing_error_test.go`, `account_repo_integration_test.go`).
- Test files use `_test.go` suffix and meaningful names describing the behavior under test.
- When adding an interface method in `service`, **all test stubs/mocks implementing that interface must be updated** (see `DEV_GUIDE.md` pitfall #6). Search: `grep -r "type.*Stub.*struct" internal/`, `grep -r "type.*Mock.*struct" internal/`.
- Shared test helpers live in `internal/testutil/`.

## Code Review Standards

- Handlers stay thin; business logic goes in `service/`.
- Repositories implement service interfaces; keep the layering (handler → service → repository) intact.
- New endpoints are registered in the appropriate `routes/xxx.go` group with proper middleware (auth, rate limiting, audit) — matching existing routes.
- Error responses follow `middleware.AbortWithError` / `pkg/errors` conventions (see error-handling spec).
- Sensitive data must be redacted/encrypted (AES encryptor in repository, credential redaction in service).
- Comment in Chinese is acceptable and common in this codebase; keep schema header docs and tricky logic commented.

## Forbidden Patterns

- `go:build ignore` style dead code without justification.
- Hand-editing generated Ent code.
- Skipping lint/test before PR.
- Introducing `npm` for frontend (must be pnpm) — frontend changes are covered by frontend quality spec.

## PR Checklist (from DEV_GUIDE.md)

- [ ] `go test -tags=unit ./...` passes
- [ ] `go test -tags=integration ./...` passes
- [ ] `golangci-lint run ./...` has no new issues
- [ ] `pnpm-lock.yaml` synced (if package.json changed)
- [ ] All test stubs updated for new interface methods
- [ ] Generated Ent code committed (if schema changed)

## Common Mistakes

- Forgetting integration test tags → CI fails on integration tests.
- Adding a new dependency without updating `go.mod`/`go.sum` (commit both).
- Over-logging in hot paths or under-logging in error paths.
- Assuming an empty environment variable overrides a viper default. This project does **not** call
  `viper.AllowEmptyEnv(true)`, so an empty env value (e.g. `SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS=${SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS:-}`
  in docker-compose) is treated as **unset**, and the built-in `viper.SetDefault` value wins
  (`backend/internal/config/config.go:1951-1969`). Before documenting env-var behavior, verify what
  the actual effective default is — the built-in default upstream host list stays active until a
  non-empty value is set.
- Documenting startup-warning → root-cause mappings without checking every consumer of the same
  config key. `TOTP_ENCRYPTION_KEY` is shared by TOTP 2FA, payment resume tokens, prompt_guard
  audit tokens, S3 secret storage, and Ollama cloud sessions — one unset key disables all of them.
