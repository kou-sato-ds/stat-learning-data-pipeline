# ==============================================================
# Stats LIFF - 開発・デプロイ用Makefile
# ==============================================================
.DEFAULT_GOAL := help
SHELL := /bin/bash

# .envがあれば読み込む（一部targetで使用）
-include .env
export

PYTHON ?= python3
PIP    ?= pip

.PHONY: help setup lint format test cov check lint-sh sql-dryrun \
        deploy deploy-bq deploy-fn deploy-fe schedule clean

help: ## このヘルプを表示
	@echo "Stats LIFF - 利用可能なターゲット:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ---------- 開発 ----------
setup: ## 依存パッケージをインストール（dev含む）
	$(PIP) install -U pip
	$(PIP) install -r backend/requirements.txt
	$(PIP) install -r requirements-dev.txt

lint: ## ruff lint
	ruff check backend analysis

format: ## ruff format（書き換え）
	ruff format backend analysis

format-check: ## ruff formatチェックのみ
	ruff format --check backend analysis

test: ## pytestを実行
	pytest backend/tests

cov: ## カバレッジ付きでpytest
	pytest backend/tests --cov=backend --cov-report=term-missing --cov-report=html

check: lint format-check test ## CI相当のチェックを全実行

lint-sh: ## shellscriptのlint
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck未インストール"; exit 1; }
	shellcheck scripts/*.sh

sql-dryrun: ## SQLをBigQueryでdry-run（要 .env と gcloud認証）
	@if [ -z "$$PROJECT_ID" ]; then echo "❌ .env のPROJECT_IDを設定してください"; exit 1; fi
	@for f in sql/*.sql; do \
	  echo "▶ $$f"; \
	  envsubst < $$f | bq query --use_legacy_sql=false --dry_run --project_id=$$PROJECT_ID || exit 1; \
	done

# ---------- デプロイ ----------
deploy: ## 全部デプロイ（BigQuery → Functions → Frontend）
	bash scripts/deploy.sh all

deploy-bq: ## BigQueryのみ
	bash scripts/deploy.sh bigquery

deploy-fn: ## Cloud Functionsのみ
	bash scripts/deploy.sh function

deploy-fe: ## フロントエンドのみ
	bash scripts/deploy.sh frontend

schedule: ## ETL Scheduled Queryを登録
	bash scripts/setup_scheduled_query.sh

# ---------- 後片付け ----------
clean: ## ビルド成果物・キャッシュ削除
	rm -rf frontend/dist .pytest_cache htmlcov .coverage .ruff_cache
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
