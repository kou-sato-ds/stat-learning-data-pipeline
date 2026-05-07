#!/usr/bin/env bash
# ============================================================
# scripts/setup_scheduled_query.sh
# raw -> mart のELTを1時間おきに実行するScheduled Queryを登録
# ============================================================
set -euo pipefail
source .env

QUERY=$(envsubst < sql/04_etl_raw_to_mart.sql)

bq query \
  --project_id="${PROJECT_ID}" \
  --location="${BQ_LOCATION}" \
  --use_legacy_sql=false \
  --display_name="stats_liff_etl_hourly" \
  --schedule="every 1 hours" \
  --replace=true \
  "$QUERY"

echo "✅ Scheduled Query 登録完了"
