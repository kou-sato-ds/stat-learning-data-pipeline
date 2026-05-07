# ADR-0002: データウェアハウスにBigQueryを選ぶ

- **Status**: Accepted
- **Date**: 2026-04-02

## Context

個人の学習ログ（年間〜10万行程度）を蓄積し、SQLで分析できる基盤が必要。
候補は次の3つ:

1. **SQLite** (ローカル): 起動コストゼロ、無料、運用ゼロ
2. **BigQuery**: GCPに統合、列指向、無料枠が広い
3. **Cloud SQL (Postgres)**: トランザクション強い、コスト中

## Decision

**BigQueryを採用**。

## Rationale

- **列指向 + パーティション**: 分野別・日次の集計が主要クエリで、列指向の利点が大きい
- **Cloud Functions との統合**: `google-cloud-bigquery` で1行で書ける
- **無料枠**: 月10GBストレージ、月1TBクエリ。個人利用なら数年分まで無料
- **Scheduled Query**: cron的なETLが標準機能でついてくる
- **将来dbt移行が容易**: dbt-bigqueryが成熟

## Considered Alternatives

### SQLite
- ✅ 圧倒的にシンプル
- ❌ LIFFからのリモート書き込みには別途API + サーバホスティングが必要 → 結局Cloud Functionsを立てる必要があり、それなら BigQuery 直結のほうが楽
- ❌ 集計ビューやMERGEがBigQueryほどリッチでない

### Cloud SQL (Postgres)
- ✅ トランザクション、外部キー制約が使える
- ❌ 個人利用ではOLTP的整合性は不要
- ❌ 常時稼働インスタンスでコストがBigQueryより高くなりがち（最低$10/月程度）

## Consequences

- **Positive**: 列指向の恩恵で集計が速い、運用負荷ゼロ
- **Negative**:
  - リアルタイム性に欠ける（streaming insertでも数秒の遅延）
  - 外部キー制約がないため、データ整合性はアプリ層で担保
- **Mitigations**:
  - リアルタイム性は要件外と判断（学習ログは事後分析が中心）
  - データ整合性はバリデーション層 + ETLの `MERGE` で吸収
