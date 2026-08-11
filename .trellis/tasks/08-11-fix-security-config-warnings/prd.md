# 修复生产安全配置警告：TOTP key / URL allowlist / payment token

## Goal

消除 backend 启动日志中的三条安全配置警告，并让生产部署的正确配置路径清晰、可操作（交付配置指引文档，不改代码行为）：

1. `TOTP encryption key auto-generated`（bootstrap + production 双出现）
2. `security.url_allowlist.enabled=false`（allowlist/SSRF 防护被禁用）
3. `payment encryption/signing key is not explicitly configured`（支付 resume tokens 未启用）

## Background

三个警告根因是两个配置项未设置：

- **`TOTP_ENCRYPTION_KEY`**（env）/ `totp.encryption_key`（yaml）同时消除警告 #1 和 #3：
  - `backend/internal/config/config.go:1835-1847` — 未设置时自动生成随机 key 并打警告 #1；生成命令 `openssl rand -hex 32`（64 位 hex，AES-256）
  - `backend/internal/payment/wire.go:35` — 无固定 key 时禁用 payment resume tokens 并打警告 #3
  - 同一 key 的连带影响：TOTP 2FA 重启后失效（config.example.yaml:1031-1040 已文档化）、prompt_guard 审计节点 token 重启失效（`securityaudit/prompt_config_store.go:362`）、S3 secret 无法持久存储（`service/backup_service.go:53`）、Ollama cloud session 无法存储（`service/ollama_cloud_usage.go:72`）
- **`security.url_allowlist.enabled=true`** 消除警告 #2：
  - `backend/internal/config/config.go:1863-1865` 打警告；默认 false（config.go:1951）
  - 启用后行为（`repository/http_upstream.go:579-604`）：代理请求 host 必须匹配 allowlist；`allow_private_hosts=false` 时额外校验解析后 IP 防 SSRF
  - 默认值：`allow_private_hosts=true`、`allow_insecure_http=true`（config.go:1968-1969）；`upstream_hosts` 默认含常见上游（config.go:1952-1962）

现有工具链已支持（配置路径通畅，无需代码改动）：

- `deploy/docker-deploy.sh:105` — 部署时自动生成固定 `TOTP_ENCRYPTION_KEY` 写入 .env
- `deploy/README.md:105,236` — 已有生成命令与变量表行
- `deploy/docker-compose*.yml` — 已透传 `TOTP_ENCRYPTION_KEY` 与 `SECURITY_URL_ALLOWLIST_ENABLED/ALLOW_INSECURE_HTTP/ALLOW_PRIVATE_HOSTS/UPSTREAM_HOSTS`（viper 规则：`.`→`_`，`SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS` → `security.url_allowlist.upstream_hosts`，config.go:1704-1705）；`pricing_hosts`/`crs_hosts` 无 env 透传，只能走 config.yaml
- `deploy/config.example.yaml:136-165` — allowlist 完整注释示例（目前是唯一 allowlist 文档来源）

文档缺口（本次交付的落点）：`deploy/README.md` 的 Environment Variables 表（230-249 行）**完全没有** `SECURITY_URL_ALLOWLIST_*` 行，也没有三警告的因果说明、TOTP key 的连带影响说明、本地开发 vs 生产场景区分。

用户环境：`make dev` 本地运行（无本地 config.yaml、无 env），警告必然出现；本地开发场景警告无害（随机 key 只影响重启后加密数据解密，dev 无持久敏感数据）。

## Requirements

- R1：在 `deploy/README.md` 补充三警告的配置指引：根因映射、key 生成命令、allowlist 配置内容（env 与 config.yaml 两种途径）、配置位置
- R2：明确区分本地开发（make dev，警告无害可忽略）与生产部署（必须配置）两种场景
- R3：Environment Variables 表补齐 `SECURITY_URL_ALLOWLIST_*` 四行
- R4：说明 `TOTP_ENCRYPTION_KEY` 缺失的连带影响（payment resume tokens、2FA、审计 token、S3 secret、Ollama session）
- R5：不改任何代码行为与配置默认值（allowlist 启用是部署方显式选择，避免自定义上游被拒）

## Acceptance Criteria

- [ ] AC1：`deploy/README.md` 新增"生产安全配置"指引，明确写出三条警告各自对应的配置项、`openssl rand -hex 32` 生成命令、配置位置（.env / docker-compose / config.yaml）
- [ ] AC2：指引明确区分本地开发（可忽略）与生产部署（必须配置）两种场景
- [ ] AC3：Environment Variables 表新增 `SECURITY_URL_ALLOWLIST_ENABLED`、`SECURITY_URL_ALLOWLIST_UPSTREAM_HOSTS`、`SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS`、`SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP` 四行并说明默认值
- [ ] AC4：指引说明 `TOTP_ENCRYPTION_KEY` 的连带影响（payment resume tokens / 2FA / 审计 token / S3 secret / Ollama session）
- [ ] AC5：无代码行为与配置默认值改动（git diff 仅限文档文件）

## Out of Scope

- 不改动警告日志内容/级别
- 不改配置默认值（`url_allowlist.enabled` 保持 false、`allow_private_hosts`/`allow_insecure_http` 保持 true）
- 不实现 key 轮换/迁移机制（已有数据用随机 key 加密后换固定 key 的兼容问题：确认无生产数据则忽略；文档中提示"首次部署前设置"）

## Key Decisions

- 交付范围：配置指引文档（用户已确认），非模板默认值调整、非仅口头回答
- 落点：`deploy/README.md`（该文件是部署主文档，已有 Environment Variables 表与部署方法章节）
- 行为不变：allowlist 启用是部署方显式选择，避免破坏现有自定义上游

## Risks / Deferred

- 已有生产数据若曾被自动生成 key 加密，换固定 key 后旧密文不可解密（本次不处理；指引提示首次部署前设置）
- `pricing_hosts`/`crs_hosts` 无 env 透传，allowlist 场景下需 config.yaml 配置（指引中注明）
