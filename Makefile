.PHONY: build build-backend build-frontend test test-backend test-frontend test-frontend-critical dev dev-backend dev-frontend dev-deps dev-deps-down dev-config dev-check

FRONTEND_CRITICAL_VITEST := \
	src/api/__tests__/client.spec.ts \
	src/api/__tests__/tokenRefresh.spec.ts \
	src/api/__tests__/channelMonitorV2.spec.ts \
	src/views/auth/__tests__/LinuxDoCallbackView.spec.ts \
	src/views/auth/__tests__/WechatCallbackView.spec.ts \
	src/views/user/__tests__/PaymentView.spec.ts \
	src/views/user/__tests__/PaymentResultView.spec.ts \
	src/views/user/__tests__/ChannelStatusView.mode.spec.ts \
	src/components/user/profile/__tests__/ProfileInfoCard.spec.ts \
	src/views/admin/__tests__/SettingsView.spec.ts \
	src/features/channel-monitor-v2/__tests__/designSystem.structure.spec.ts \
	src/features/channel-monitor-v2/__tests__/monitorFormat.spec.ts \
	src/features/channel-monitor-v2/__tests__/monitorZoom.spec.ts

# 一键编译前后端
build: build-backend build-frontend

# 编译后端（复用 backend/Makefile）
build-backend:
	@$(MAKE) -C backend build

# 编译前端（需要已安装依赖）
build-frontend:
	@pnpm --dir frontend run build

# 运行测试（后端 + 前端）
test: test-backend test-frontend

test-backend:
	@$(MAKE) -C backend test

test-frontend:
	@pnpm --dir frontend run lint:check
	@pnpm --dir frontend run typecheck
	@$(MAKE) test-frontend-critical

test-frontend-critical:
	@pnpm --dir frontend exec vitest run $(FRONTEND_CRITICAL_VITEST)

# =============================================================================
# 开发环境命令（本地开发用）
# =============================================================================
# 依赖：PostgreSQL/Redis 容器（make dev-deps）、backend/config.yaml（make dev-config）
# 用法：
#   make dev-deps      # 启动 PostgreSQL(15432) + Redis(16379) Docker 容器
#   make dev-config    # 生成 backend/config.yaml（自动指向 15432/16379）
#   make dev           # 一键启动后端(:8080) + 前端(:3000)，Ctrl+C 一起停止
#   make dev-backend   # 只启动后端
#   make dev-frontend  # 只启动前端
# =============================================================================

# 一键启动前后端（Ctrl+C 同时退出）
dev: dev-check
	@echo "==> 启动后端 http://localhost:8080 与前端 http://localhost:3000 （Ctrl+C 停止）"
	@trap 'kill $$(jobs -p) 2>/dev/null' INT TERM EXIT; \
	cd backend && go run ./cmd/server/ & \
	cd frontend && pnpm dev & \
	wait

# 只启动后端
dev-backend:
	@cd backend && go run ./cmd/server/

# 只启动前端
dev-frontend:
	@cd frontend && pnpm dev

# 启动本地依赖容器（PostgreSQL + Redis，数据持久化在 Docker 卷）
dev-deps:
	@docker compose -f deploy/docker-compose.dev-deps.yml up -d

# 停止依赖容器（保留数据）
dev-deps-down:
	@docker compose -f deploy/docker-compose.dev-deps.yml down

# 生成 backend/config.yaml（从示例复制，端口改为 PG 15432 / Redis 16379）
dev-config:
	@if [ ! -f backend/config.yaml ]; then \
		cp deploy/config.example.yaml backend/config.yaml && \
		sed -i.bak -e 's/^  host: "localhost"$$/  host: "127.0.0.1"/' -e 's/^  port: 5432$$/  port: 15432/' -e 's/^  port: 6379$$/  port: 16379/' backend/config.yaml && \
		rm -f backend/config.yaml.bak && \
		echo "==> 已生成 backend/config.yaml（PG: 15432, Redis: 16379）"; \
	else \
		echo "==> backend/config.yaml 已存在，跳过生成（如需重生成先删除）"; \
	fi

# dev 前置检查：config.yaml 必须存在
dev-check:
	@test -f backend/config.yaml || (echo "错误：缺少 backend/config.yaml，请先运行: make dev-config" && exit 1)
