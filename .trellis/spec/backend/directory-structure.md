# Directory Structure

> How backend code is organized in this project.

---

## Overview

The backend is a Go service using **Gin** for HTTP, **Ent** for ORM, and **Google Wire** for dependency injection. Code follows a strict layered architecture: handler (HTTP) → service (business logic) → repository (data access). The dependency graph is assembled centrally in `cmd/server/wire.go` via ProviderSets.

## Directory Layout

```
backend/
├── cmd/
│   ├── server/               # Main entrypoint + Wire dependency injection (wire.go / wire_gen.go)
│   ├── jwtgen/               # Utility: generate JWT secrets
│   ├── profit-preview/       # Utility: profit preview calculation
│   └── cleanup-ingress-reject-logs/  # Maintenance utility
├── ent/                      # Ent ORM generated code + schemas
│   ├── schema/               # Entity definitions (one file per entity, 40 entities)
│   │   └── mixins/           # Reusable mixins: TimeMixin, SoftDeleteMixin
│   ├── migrate/              # Ent auto-migration code
│   └── <entity>/             # Generated per-entity packages (do not edit)
├── internal/
│   ├── config/               # Configuration structs + ProviderSet
│   ├── domain/               # Domain constants and shared models
│   ├── handler/              # HTTP handlers (thin layer)
│   │   ├── admin/            # Admin panel handlers
│   │   └── dto/              # Request/response DTOs
│   ├── integration/          # External system integrations (e2e helpers)
│   ├── middleware/           # Gin middleware (auth, logging, CORS, rate limit)
│   ├── model/                # Internal domain models
│   ├── payment/              # Built-in payment providers (EasyPay, Alipay, WeChat, Stripe)
│   ├── pkg/                  # Reusable packages (claude, openai, gemini, errors, logger, ...)
│   ├── platform/             # Upstream platform clients (claude/, openai/, gemini/, grok/, antigravity/)
│   ├── repository/           # Data access layer (Ent + Redis), implements service interfaces
│   ├── securityaudit/        # Prompt audit / security services
│   ├── server/               # Gin router assembly + route registrations
│   │   └── routes/           # Route groups: gateway.go, user.go, admin.go, auth.go, payment.go
│   ├── service/              # Business logic layer (interfaces + implementations)
│   ├── setup/                # First-run setup wizard (CLI + auto-setup)
│   ├── testutil/             # Shared test helpers
│   ├── util/                 # Generic utilities
│   └── web/                  # Embedded frontend serving
├── migrations/               # SQL migration scripts (001_init.sql, ...)
├── config.yaml               # Runtime configuration
└── go.mod / go.sum
```

## Module Organization

- **API endpoints** are defined in `internal/server/routes/`, grouped by surface: `gateway.go` (AI API proxy), `user.go` (authenticated user panel), `admin.go` (admin panel), `auth.go` (authentication/OAuth), `payment.go` (payment flows).
- **Business logic lives in `internal/service/`**. Services expose interfaces (e.g. `AccountRepository`, `GatewayService`) consumed by handlers and implemented by repository/handler-adjacent code.
- **HTTP handling lives in `internal/handler/`**. Handlers are thin: they parse requests, call services, and render responses. Gateway-specific handlers include `gateway_handler.go` and `openai_gateway_handler.go`.
- **Data access lives in `internal/repository/`**. Repositories own Ent client queries and Redis caching. Repository types implement service interfaces (e.g. `accountRepository` implements `service.AccountRepository`).
- **Upstream clients live in `internal/platform/`** (Claude, OpenAI, Gemini, Grok, Antigravity) and **`internal/pkg/`** for protocol-level helpers (e.g. `pkg/openai`, `pkg/claude`, `pkg/geminicli`).

## Naming Conventions

- Files are `snake_case.go` (Go convention), e.g. `gateway_handler.go`, `api_key_repo.go`.
- Handlers: `XxxHandler` struct with methods bound to routes; files named `xxx_handler.go`.
- Services: `XxxService` struct + constructor `NewXxxService`; files `xxx_service.go`.
- Repositories: `xxx_repo.go`; private structs implementing exported interfaces (`accountRepository` implements `service.AccountRepository`); constructors return the interface type.
- Schema files: one per entity, singular lowercase (`user.go`, `api_key.go`, `usage_log.go`).
- Route registration: `RegisterXxxRoutes` in `internal/server/routes/xxx.go`.

## Examples

- Well-organized route group: `backend/internal/server/routes/gateway.go` — protocol-specific middleware chain then handler dispatch.
- Reference service: `backend/internal/service/gateway_service.go` (core gateway logic).
- Reference repository: `backend/internal/repository/account_repo.go` (Ent + SQL + scheduler cache).
