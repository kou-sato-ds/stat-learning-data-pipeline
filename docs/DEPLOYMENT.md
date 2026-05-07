# デプロイ手順書

このドキュメントは、初回デプロイの**全手動ステップ**を時系列で並べたものです。

## 0. 前提ツール

ローカル環境に以下が必要です:

```bash
# gcloud CLI
gcloud --version

# Firebase CLI
npm install -g firebase-tools

# bq CLI (gcloudに同梱)
bq version

# envsubst (gettextパッケージに同梱)
envsubst --version
```

macOSなら `brew install google-cloud-sdk firebase-tools gettext` が手っ取り早いです。

---

## 1. GCPプロジェクトの準備

```bash
# プロジェクト作成（既存があればスキップ）
gcloud projects create stats-liff-yourname --name="Stats LIFF"

# プロジェクト選択
gcloud config set project stats-liff-yourname

# 必要なAPIを有効化
gcloud services enable \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  bigquery.googleapis.com \
  bigquerydatatransfer.googleapis.com \
  run.googleapis.com \
  firebasehosting.googleapis.com

# 認証
gcloud auth login
gcloud auth application-default login
```

請求先アカウントを紐付けます（Cloud Functions Gen2にはRun APIとビルドが必要なため）。

---

## 2. LINE Developers Consoleでチャネル作成

1. <https://developers.line.biz/console/> にログイン
2. **Provider** を作成（既存があれば再利用）
3. **LINE Loginチャネル** を新規作成
   - チャネルタイプ: LINE Login
   - アプリタイプ: ウェブアプリ
4. 作成後、**Channel ID** をメモ → `.env` の `LIFF_CHANNEL_ID`
5. 同じチャネル内の **LIFF タブ** で「LIFFアプリを追加」
   - サイズ: Tall（推奨）
   - エンドポイントURL: いったん `https://example.com` で仮置き（後でFirebase URLに更新）
   - Scope: `profile`、`openid`
6. 発行された **LIFF ID** をメモ → `.env` の `LIFF_ID`

---

## 3. `.env` の作成

```bash
cp .env.example .env
```

すべての項目を埋めます。`USER_ID_SALT` は次のように生成:

```bash
openssl rand -hex 32
```

---

## 4. デプロイ実行

```bash
bash scripts/deploy.sh
```

スクリプトは以下を順に実行します:

1. **BigQuery**: データセット → テーブル → `dim_topic` シード → 分析ビュー
2. **Cloud Functions**: `ingestAnswer` / `ingestShakyo` をデプロイし、エンドポイントURLを `.env` に追記
3. **フロントエンド**: `app.js` のプレースホルダを置換 → Firebase Hostingにデプロイ

完了後、コンソールに表示されるFirebase URL（`https://${PROJECT_ID}.web.app/`）をコピー。

---

## 5. LIFFのエンドポイントURL更新

LINE Developers Console → 作成したLIFFアプリ → **エンドポイントURL** をFirebase URLに変更して保存。

---

## 6. Scheduled Queryの登録

```bash
bash scripts/setup_scheduled_query.sh
```

これで毎時 raw → mart のELTが実行されます。

---

## 7. 動作確認

スマホのLINEアプリで、LIFFアプリを開く（友だち追加URLは LINE Developers ConsoleのLIFFアプリ設定画面の「LIFF URL」）。

最初のアクセス時に同意画面が出ます → 承認 → フォームが表示されます。

ダミー解答を1件送信し、BigQueryで確認:

```bash
bq query --nouse_legacy_sql \
  "SELECT * FROM \`${PROJECT_ID}.stats_raw.answer_log\` LIMIT 5"
```

---

## 8. Looker Studioダッシュボード（任意）

1. <https://lookerstudio.google.com/> で「空のレポート」を作成
2. データソース → BigQuery → `${PROJECT_ID}.stats_mart.v_topic_perf_30d` を追加
3. 推奨ビジュアル:
   - **散布図**: x=`accuracy`, y=`cv_time`, バブルサイズ=`n_attempt`（右下=不安定ゾーン）
   - **棒グラフ**: 分野別正解率（`target_pass_rate` を参照線として追加）
   - **スコアカード**: `v_expected_score.expected_score`
   - **時系列**: `v_weekly_score.weekly_expected_score`

---

## トラブルシュート

### Cloud Functions デプロイで `Permission denied`

サービスアカウントに必要な権限を付与:

```bash
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"
```

### CORSエラー

`.env` の `ALLOWED_ORIGIN` がFirebase HostingのURLと一致しているか確認 → Functionsを再デプロイ:

```bash
bash scripts/deploy.sh function
```

### `liff.init` が `INIT_FAILED`

- LIFF IDが正しいか
- LIFFのエンドポイントURLがFirebase URLと完全一致しているか（末尾スラッシュも揃える）
- 「公開」状態になっているか

### BigQuery `MERGE` が「Table not found」

`scripts/deploy.sh bigquery` を再実行。`dim_topic` などが先に作られていない可能性があります。

---

## デプロイ後のメンテナンス

| 操作 | コマンド |
|---|---|
| バックエンドのみ再デプロイ | `bash scripts/deploy.sh function` |
| フロントエンドのみ再デプロイ | `bash scripts/deploy.sh frontend` |
| 出題範囲のweight更新 | `sql/03_seed_dim_topic.sql` を編集 → `bash scripts/deploy.sh bigquery` |
| ANOVA実行 | `python analysis/anova_weak_topics.py --project ... --user-id-hash ...` |
| スコア予測 | `python analysis/score_projection.py --project ... --user-id-hash ... --exam 2026-07-31` |
