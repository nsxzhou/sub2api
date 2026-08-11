# Error Handling

> How errors are caught, logged, and returned.

---

## Overview

Two error surfaces exist:

1. **Panel/Admin/User API** — JSON errors in a standard shape.
2. **Gateway (AI proxy) API** — protocol-specific error formats (OpenAI-compatible, Anthropic-compatible, Google-compatible), because downstream SDKs parse them.

## Standard Panel Error Shape

Middleware provides a canonical shape:

```go
// backend/internal/server/middleware/middleware.go
type ErrorResponse struct {
    Code    string `json:"code"`
    Message string `json:"message"`
}

func AbortWithError(c *gin.Context, statusCode int, code, message string) {
    c.JSON(statusCode, NewErrorResponse(code, message))
    c.Abort()
}
```

Usage: middleware and handlers call `middleware.AbortWithError(c, http.StatusBadRequest, "INVALID_REQUEST", "...")` or domain-specific codes such as `INVALID_API_KEY`, `INVALID_AUTH_RATE_LIMITED`.

## Application Errors (pkg/errors)

`internal/pkg/errors` defines `ApplicationError` (alias `Error`) with:

- `Code` — expected to be an HTTP status code (400/401/403/404/409/500)
- `Reason` — machine-readable reason string
- `Message` — user-facing message
- `Metadata` — optional structured metadata
- `cause` — wrapped underlying error (`WithCause`, `Unwrap`, `Is`)

Services return `(value, error)` and wrap context with `fmt.Errorf("create account: %w", err)`. Handlers translate service errors into HTTP responses; the package provides `errors/http.go` helpers for converting `ApplicationError` to status/body.

## Gateway Error Handling

- Middleware writers are protocol-aware: `GatewayErrorWriter` variants exist (`AnthropicErrorWriter`, `GoogleErrorWriter`, OpenAI-compatible writers) so error bodies match what SDKs expect.
- OpenAI-compatible quota errors use the `insufficient_quota` shape (see `abortWithOpenAIQuotaError` in `middleware.go`).
- Gateway failover/retry distinguishes retryable upstream errors (502 etc.) from hard client errors (400) — e.g. upstream deterministic 400s must NOT be normalized into retryable 502 (see recent commits).
- Stream errors are handled in stream-specific helpers (`openai_stream_validation.go`, `gateway_upstream_response.go`).

## Logging Errors

- All non-trivial error paths log with structured context: `reqLog.Warn("gateway.user_slot_acquire_failed", zap.Error(err))`.
- Sensitive credential material must never be logged (see `account_credentials_redact.go`).

## Forbidden Patterns

- Do not leak internal error details (SQL, credentials, stack traces) into client-facing messages.
- Do not return raw Go error strings as the `message` for gateway endpoints; map to protocol shapes.
- Do not swallow errors without logging; if intentionally ignored, add a comment explaining why.

## Common Mistakes

- Returning OpenAI error shape to Anthropic clients (or vice versa) — always use the platform-appropriate writer.
- Treating upstream 400 (client error) as retryable — it should be passed through, not retried as 502.
- Forgetting `c.Abort()` after writing an error in middleware.
