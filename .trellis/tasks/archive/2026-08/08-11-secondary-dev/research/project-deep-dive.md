# Sub2API 项目深读（第一版）

> 目的：快速建立对项目的整体认知，作为简历表述与后续二开的底稿。
> 信息来源：README_CN.md、DEV_GUIDE.md、backend/ 与 frontend/ 源码、docs/、ent schema。
> 版本：2026-08-11（基于当前 main，上游 Wei-Shaw/sub2api）

## 1. 项目定位

Sub2API 是一个 **AI API 网关平台（订阅配额分发管理）**：平台管理员接入多种上游 AI 账号（Claude / OpenAI / Gemini / Grok / Antigravity 等，支持 OAuth、API Key 等凭证），将账号池抽象为"分组 + 配额"，向终端用户分发 API Key；用户用平台 API Key 调用 OpenAI/Claude/Gemini 兼容接口，平台负责**鉴权、计费、调度、负载均衡、请求转发**。

一句话简历表述：*AI API 网关，聚合多上游账号凭证，通过 API Key 向用户提供统一的多协议（OpenAI / Anthropic / Gemini 兼容）AI 接口，含 Token 级计费、智能账号调度、并发/速率限制、内置支付。*

## 2. 技术栈

| 层 | 技术 |
|---|---|
| 后端 | Go 1.25.7、Gin、Ent ORM（40 个 schema）、Google Wire 依赖注入、zap 日志、Redis |
| 前端 | Vue 3.4 + TypeScript + Vite 5 + Tailwind + Pinia + vue-i18n（多语言）+ Chart.js |
| 数据 | PostgreSQL（migrations 001~008+，SQL 迁移）、Redis（缓存/队列/限流） |
| 工程 | golangci-lint v2.7、go test -tags=unit/integration、pnpm（前端必须 pnpm） |

## 3. 总体架构（请求链路）

```
客户端 (Claude Code / Codex / OpenAI SDK / Gemini CLI ...)
   │  OpenAI / Anthropic / Gemini 兼容 API
   ▼
┌──────────────────────────────────────────────────────────────┐
│ Gin 网关                                                        │
│  ├─ 中间件链：RequestLogger → SessionBinding → Logger → CORS   │
│  │   → SecurityHeaders(CSP) → ServerTiming                    │
│  ├─ 鉴权：API Key Auth（Bearer / x-api-key）→ 订阅/配额检查      │
│  ├─ 路由：/v1/...（gateway / user / admin / auth / payment）     │
│  └─ Handler 层（GatewayHandler / OpenAIGatewayHandler / ...）   │
└──────────────────────────────────────────────────────────────┘
   ▼ Service 层（GatewayService / OpenAIGatewayService / Scheduler ...）
     调度选账号（分组→平台→账号池，粘性会话、并发控制、故障转移）
   ▼ 上游调用（Claude / OpenAI / Gemini / Grok / Antigravity / Bedrock ...）
   ▼ 响应回传 + UsageLog 落库（Token 级计费、用量统计）
```

## 4. 后端分层（backend/internal/）

| 包 | 职责 | 代表文件 |
|---|---|---|
| `cmd/server/` | 入口 + Wire 依赖注入 | main.go、wire.go、wire_gen.go |
| `internal/config/` | 配置加载 | config.yaml 对应结构 |
| `internal/server/` | Gin 路由装配、中间件 | router.go、routes/{gateway,user,admin,auth,payment}.go、middleware/ |
| `internal/handler/` | HTTP 处理（薄层） | gateway_handler.go、openai_gateway_handler.go、admin/、user 系列 |
| `internal/service/` | 业务逻辑（核心） | gateway_service.go、account_service.go、openai_gateway_service.go、scheduler_*、billing 系列 |
| `internal/repository/` | 数据访问 + Redis 缓存 | account_repo.go、api_key_repo.go、api_key_cache.go |
| `internal/domain/` | 领域常量/模型 | constants.go、reasoning_effort.go |
| `internal/model/` | DTO/请求模型 | — |
| `internal/payment/` | 内置支付（易支付/支付宝/微信/Stripe） | — |
| `internal/platform/` | 上游平台客户端封装 | claude/ openai/ gemini/ grok/ antigravity/ |
| `internal/securityaudit/` | 提示词审计/安全 | — |
| `internal/integration/` | 外部系统集成 | — |
| `ent/` | Ent 生成代码 + schema（40 实体） | schema/*.go、migrate |
| `migrations/` | SQL 迁移脚本 | 001_init.sql ... |

**依赖注入**：Google Wire 将 config → repository → service → handler → server 各层 ProviderSet 组装成 Application（见 wire.go）。

## 5. 核心数据模型（ent schema 关键实体）

- `user` — 用户（软删除、部分唯一索引）
- `api_key` — 平台 API Key（绑定用户/分组、配额、限流、最后使用时间）
- `account` — 上游账号（平台、凭证类型 api_key/oauth/cookie、调度状态、分组）
- `group` — 分组（把账号聚合成逻辑资源，用户 Key 绑定分组）
- `usage_log` — 只追加的用量日志（token 用量、成本、请求明细）
- `payment_order` / `payment_provider_instance` / `payment_audit_log` — 支付订单与审计
- `subscription_plan` / `user_subscription` — 订阅套餐与用户订阅
- `user_platform_quota` — 用户按平台的配额
- `redeem_code` / `promo_code` — 兑换码/优惠码
- `channel_monitor*` — 渠道监控（V2 系列）
- `batch_image_*` — 批量图片任务（Gemini batch MVP）
- `composite_model_route` — 组合分组模型路由
- `error_passthrough_rule` — 错误透传规则
- `security_secret` / `tls_fingerprint_profile` / `pending_auth_session` / `auth_identity*` — 安全与认证体系

## 6. 核心业务链路

### 6.1 网关请求（核心中的核心）
1. **鉴权**：`middleware/api_key_auth.go` 提取 Bearer / x-api-key → 校验 Key 有效性、用户状态、IP 限制；计费执行（过期/配额/订阅/余额）分 `skipBilling` 开关。
2. **归一化**：`InboundEndpointMiddleware` 归一化协议端点；composite 中间件按模型解析目标平台。
3. **调度**：`GatewayService`/`OpenAIGatewayService` + scheduler 系列——按分组→平台→账号池选账号，支持粘性会话（session hash）、并发控制、故障转移（maxAccountSwitches）、容量/利润准入。
4. **转发**：`gateway_forward*.go` / `openai_*` 系列封装上游协议（含流式 SSE、WebSocket、Responses API、图片、工具改写等大量兼容逻辑）。
5. **计费**：`gateway_usage_billing.go` / `openai_gateway_usage.go` → UsageLog 落库；Token 级定价、倍率、利润控制。

### 6.2 用户/管理面
- 用户：注册/登录/OAuth（微信、钉钉、LinuxDo、OIDC）、TOTP、passkey、API Key 管理、用量、订阅、支付、兑换码、邀请返利。
- 管理后台：账号管理、渠道监控、分组、API Key、用户、用量、订单、公告、风控、审计日志、系统设置、备份。

### 6.3 支付
内置支付系统：EasyPay 易支付 / 支付宝官方 / 微信官方 / Stripe / Airwallex（前端组件），用户自助充值；`docs/PAYMENT_CN.md`、`docs/ADMIN_PAYMENT_INTEGRATION_API.md` 详述对接方式。

## 7. 前端结构（frontend/src/）

| 目录 | 内容 |
|---|---|
| `views/` | 页面：`admin/`（97 文件，管理后台）、`user/`（34，用户面板）、`auth/`（认证）、`setup/`（初始化向导）、`public/`、Home/KeyUsage/ModelPlaza |
| `components/` | 294 个：admin/common/account/user/payment/auth/layout/charts/keys/channels 等 |
| `api/` | axios 封装：`client.ts` + 按域拆分（admin/*、keys、usage、payment、subscriptions...） |
| `stores/` | Pinia：auth、app、payment、subscriptions、adminSettings、adminCompliance 等 |
| `router/` | Vue Router：setup/public/auth/user/admin 分区 + 导航守卫（登录态、feature-access、title） |
| `i18n/` | 多语言（中英日等 41 文件） |
| `utils/`、`composables/` | 工具与组合式函数 |

## 8. 关键文件地图（二开最常碰）

| 想改什么 | 找哪里 |
|---|---|
| 新增网关 API 端点 | `backend/internal/server/routes/gateway.go` + `handler/gateway_handler.go` |
| 新协议/新平台 | `service/openai_gateway_*.go`、`internal/platform/` |
| 调度/选号逻辑 | `service/gateway_scheduling.go`、`service/scheduler_*.go` |
| 计费规则 | `service/gateway_usage_billing.go`、`service/openai_gateway_usage.go` |
| 数据模型 | `backend/ent/schema/*.go`（改后 `go generate ./ent` + 迁移） |
| 前端新页面 | `frontend/src/views/` + `router/index.ts` + `api/` |
| 支付 | `internal/payment/` + `frontend/src/views/user/*Payment*` |

## 9. 二开切入点候选（待用户选择）

- A. 网关层新功能（协议兼容、模型路由、请求改写）
- B. 计费/风控（新计费维度、风控规则、审计）
- C. 管理后台增强（新监控看板、批量操作、报表导出）
- D. 用户侧体验（新页面、通知、订阅套餐）
- E. 运维/部署（告警、健康检查、可观测性）
- F. 先只做"理解"：完善本项目文档 + 简历表述，暂不改码

## 10. 简历表述素材（草稿）

- 独立完成 AI API 网关二开：基于 Go + Ent + Gin 与 Vue3 构建，聚合 Claude/OpenAI/Gemini/Grok 多上游账号，实现 API Key 分发、Token 级计费、智能调度、并发控制与内置支付。
- 深入上游 40+ 数据实体与 2300+ Go 文件，定位并实现 XX 功能（待二开后填充）。
