# 二次开发规划（sub2api）

## Goal

用户希望以 sub2api 为二开项目写入个人简历：先深入了解项目架构，再进行二次开发（期间可能新增个人功能）。本任务处于 Trellis Phase 1 规划：收敛目标、范围、验收标准后产出 `design.md` + `implement.md` 再进入实现。

## Background（已确认事实，来源：仓库检查）

### 项目概况
- Sub2API —— AI API 网关平台（订阅配额分发管理），上游 `Wei-Shaw/sub2api`，本地 remote 即上游；`DEV_GUIDE.md` 记录 fork `bayma888/sub2api-bmai`。
- 技术栈：Go 1.25（Ent ORM + Gin）+ Vue 3 + TypeScript + Vite + Tailwind + Pinia + vue-i18n；PostgreSQL + Redis；前端包管理必须用 pnpm。
- 后端：`backend/internal/` 分层清晰（handler → service → repository → domain/model），含 payment、platform、integration、securityaudit 等模块；2327 个 Go 文件，40 个 ent schema，migrations 001~008+。
- 前端：738 个文件，views 164、components 294、api 74、i18n 41（多语言）、stores 13；含 Stripe/Airwallex 支付组件、Chart.js 图表、虚拟滚动、拖拽等依赖。
- 已有二开产物文档：docs/PAYMENT_CN.md、ADMIN_PAYMENT_INTEGRATION_API.md、ASYNC_IMAGE_TASKS.md、BATCH_IMAGE_MVP.md、COMPOSITE_GROUPS.md。
- 引导任务 `00-bootstrap-guidelines`（in_progress）：`.trellis/spec/backend|frontend/` 规范未填充。

### 用户意图与决策记录
- 简历目标：把 sub2api 二开作为个人简历项目。
- 当前对项目不熟悉，需要先深入了解（架构、数据流、核心模块）——用户明确要求先做项目深读。
- 二开期间可能新增自己的功能。
- **决策 2026-08-11：不做 React 重构前端**（用户确认放弃，理由：全量重写 738 文件成本过高）。前端保持 Vue 3，二开在前端的工作以 Vue 生态内新增/修改功能为主。

## Requirements（草案，待收敛）

- R1 产出项目深读文档（架构图、核心链路、模块清单、关键代码位置），支撑简历表述与后续开发
- R2 基于理解的二开（具体功能待定）
- R3 （已取消）React 重构前端 —— 2026-08-11 用户确认不做

## Acceptance Criteria

- [ ] TBD

## Open Questions（阻塞规划）

- [ ] 二开具体功能点（待深读完成后由用户从理解中选出）
- [ ] 二开基线：fork 后独立仓库，还是本地分支开发（用户询问过 fork，尚未最终确认）
- [ ] 是否同步上游更新（上游活跃）

## Out of Scope（初判，待确认）

- 不修改上游仓库（二开仅在 fork/本地分支进行）
- 不做 React 重构（用户已确认）
- 不重写后端（除非用户后续提出）

## Notes

- 遵循 DEV_GUIDE.md：pnpm、Go 1.25.7、golangci-lint v2.7、ent 改动后 `go generate ./ent`、PR 前 checklist。
- 复杂任务：需 `design.md` + `implement.md`；本任务预计为复杂任务。
