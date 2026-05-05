# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- dbt-bigquery導入とSQL層のリファクタリング
- Terraform化（`infra/terraform/`）
- JWKS によるローカルJWT検証への移行（LINE Verify API依存の解消）
- Great Expectationsでデータ品質ゲート
- GitHub ActionsのCD job

## [0.1.0] - 2026-04-15

### Added
- LIFFフロントエンド（解答ログ・写経ログ入力UI、オフラインキュー）
- Cloud Functions: `ingestAnswer` / `ingestShakyo`
- BigQuery raw + mart の Star Schema 構成
- 出題範囲表 (34項目) の `dim_topic` シードデータ
- 分析ビュー: `v_topic_perf_30d`, `v_expected_score`, `v_weak_topics`, `v_weekly_score`
- 分析スクリプト: 一元配置ANOVA、線形回帰スコア予測
- デプロイスクリプト: `scripts/deploy.sh`
- Scheduled Query登録: `scripts/setup_scheduled_query.sh`
- ドキュメント: README, DEPLOYMENT, ARCHITECTURE, DATA_MODEL, KNOWN_LIMITATIONS, ROADMAP
- ADR-0001 〜 ADR-0005
- pytest によるバリデーションロジックのテスト
- GitHub Actions CI（lint + test）

[Unreleased]: ../../compare/v0.1.0...HEAD
[0.1.0]: ../../releases/tag/v0.1.0
