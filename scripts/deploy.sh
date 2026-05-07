#!/usr/bin/env bash
# ============================================================
# deploy.sh - Stats LIFF アプリをまとめてデプロイ
#
# 前提:
#   1. gcloud CLI が認証済 (gcloud auth login, gcloud config set project)
#   2. firebase CLI がインストール済 (npm i -g firebase-tools && firebase login)
#   3. .env ファイルが作成済 (.env.example をコピー)
#   4. LINE Developers Console でチャネル + LIFFアプリは作成済
#
# 使い方:
#   bash scripts/deploy.sh           # 全部デプロイ
#   bash scripts/deploy.sh bigquery  # BigQueryのみ
#   bash scripts/deploy.sh function  # Cloud Functionsのみ
#   bash scripts/deploy.sh frontend  # フロントエンドのみ
# ============================================================
set -euo pipefail

# .env読み込み
if [[ ! -f .env ]]; then
  echo "❌ .env が見つかりません。.env.example をコピーして編集してください。"
  exit 1
fi
set -a; source .env; set +a

# 必須変数チェック
REQUIRED=(PROJECT_ID REGION BQ_LOCATION LIFF_CHANNEL_ID LIFF_ID USER_ID_SALT EXAM_DATE)
for v in "${REQUIRED[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "❌ .env に $v が未設定です"
    exit 1
  fi
done

target="${1:-all}"

# ------------------------------------------------------------
deploy_bigquery() {
  echo "▶ [1/3] BigQuery: データセットとテーブルを作成"

  for f in sql/01_create_dataset.sql sql/02_tables.sql sql/03_seed_dim_topic.sql sql/03b_seed_dim_date.sql sql/05_analysis_views.sql; do
    echo "   running: $f"
    envsubst < "$f" | bq query --project_id="${PROJECT_ID}" --location="${BQ_LOCATION}" --use_legacy_sql=false
  done

  echo "✅ BigQuery 完了"
}

# ------------------------------------------------------------
deploy_function() {
  echo "▶ [2/3] Cloud Functions: ingestAnswer / ingestShakyo をデプロイ"

  pushd backend >/dev/null

  for fn in ingestAnswer ingestShakyo; do
    echo "   deploying: $fn"
    gcloud functions deploy "$fn" \
      --gen2 \
      --runtime=python311 \
      --region="${REGION}" \
      --source=. \
      --entry-point="$fn" \
      --trigger-http \
      --allow-unauthenticated \
      --memory=256Mi \
      --timeout=30s \
      --max-instances=10 \
      --set-env-vars="GCP_PROJECT=${PROJECT_ID},BQ_DATASET_RAW=${BQ_DATASET_RAW},LIFF_CHANNEL_ID=${LIFF_CHANNEL_ID},USER_ID_SALT=${USER_ID_SALT},ALLOWED_ORIGIN=${ALLOWED_ORIGIN}"
  done

  popd >/dev/null

  # エンドポイントURLを取得して.envに反映
  EP_ANSWER=$(gcloud functions describe ingestAnswer --gen2 --region="${REGION}" --format='value(serviceConfig.uri)')
  EP_SHAKYO=$(gcloud functions describe ingestShakyo --gen2 --region="${REGION}" --format='value(serviceConfig.uri)')
  echo "ENDPOINT_ANSWER=$EP_ANSWER"
  echo "ENDPOINT_SHAKYO=$EP_SHAKYO"
  # .envに追記(既存行があれば置換)
  sed -i.bak "/^ENDPOINT_ANSWER=/d;/^ENDPOINT_SHAKYO=/d" .env
  echo "ENDPOINT_ANSWER=$EP_ANSWER" >> .env
  echo "ENDPOINT_SHAKYO=$EP_SHAKYO" >> .env

  echo "✅ Cloud Functions 完了"
}

# ------------------------------------------------------------
deploy_frontend() {
  echo "▶ [3/3] フロントエンド: Firebase Hosting にデプロイ"

  # .env再読込（function deploy後にエンドポイント追記されている）
  set -a; source .env; set +a

  if [[ -z "${ENDPOINT_ANSWER:-}" || -z "${ENDPOINT_SHAKYO:-}" ]]; then
    echo "❌ ENDPOINT_ANSWER / ENDPOINT_SHAKYO が .env にありません。先に function デプロイを実行してください。"
    exit 1
  fi

  # ビルド: app.js のプレースホルダを置換
  rm -rf frontend/dist
  mkdir -p frontend/dist
  cp frontend/index.html frontend/dist/
  cp frontend/style.css frontend/dist/
  sed \
    -e "s|__LIFF_ID__|${LIFF_ID}|g" \
    -e "s|__ENDPOINT_ANSWER__|${ENDPOINT_ANSWER}|g" \
    -e "s|__ENDPOINT_SHAKYO__|${ENDPOINT_SHAKYO}|g" \
    frontend/app.js > frontend/dist/app.js

  # firebase.json が無ければ自動生成
  if [[ ! -f firebase.json ]]; then
    cat > firebase.json <<EOF
{
  "hosting": {
    "public": "frontend/dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
  }
}
EOF
  fi
  if [[ ! -f .firebaserc ]]; then
    cat > .firebaserc <<EOF
{
  "projects": { "default": "${FIREBASE_PROJECT:-$PROJECT_ID}" }
}
EOF
  fi

  firebase deploy --only hosting --project "${FIREBASE_PROJECT:-$PROJECT_ID}"

  echo "✅ フロントエンド完了"
  echo ""
  echo "🔧 最後の手動ステップ:"
  echo "  1. LINE Developers Console > LIFFアプリ > エンドポイントURL を"
  echo "     https://${FIREBASE_PROJECT:-$PROJECT_ID}.web.app/ に設定"
  echo "  2. LIFF URLを LINEアプリで開いて動作確認"
}

# ------------------------------------------------------------
case "$target" in
  all)       deploy_bigquery; deploy_function; deploy_frontend ;;
  bigquery)  deploy_bigquery ;;
  function)  deploy_function ;;
  frontend)  deploy_frontend ;;
  *) echo "Usage: $0 [all|bigquery|function|frontend]"; exit 1 ;;
esac

echo ""
echo "🎉 デプロイ完了"
