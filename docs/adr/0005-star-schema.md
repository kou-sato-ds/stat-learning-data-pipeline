# ADR-0005: Star Schemaを採用する

- **Status**: Accepted
- **Date**: 2026-04-05

## Context

学習ログの分析クエリは「分野別 × 期間別」「ユーザー別 × 分野別」のような **次元組み合わせ** が中心になる。
データモデリングとして次の3案を検討した:

1. **One Big Table (OBT)**
2. **Star Schema** (ファクト + ディメンション)
3. **Snowflake Schema** (ディメンションをさらに正規化)

## Decision

**Star Schema** を採用。

## Rationale

- 出題範囲表（大項目・小項目）は **ほぼ静的** で、ディメンション化に向く
- weight や target_pass_rate を後から微調整したいとき、ディメンション側だけ更新すればよい
- BigQueryのクラスタリングと相性が良い (`topic_id` でクラスタ化)
- Looker Studio のJOINが直感的

## Considered Alternatives

### One Big Table (OBT)

- ✅ JOINなしでクエリが書ける（速い、シンプル）
- ❌ weight更新時に全行UPDATE → コスト・冪等性ともに不利
- ❌ 出題範囲のメンテが他のログ列を巻き込んでスキーマ進化が辛い

### Snowflake Schema

- ✅ 完全正規化で更新時の異常を防げる
- ❌ 個人利用ではディメンション階層が浅く（大項目・小項目の2段のみ）、正規化のメリットが小さい
- ❌ クエリが複雑になり、SQLが読みにくい

## Consequences

- **Positive**:
  - 分析クエリがほぼテンプレート化できる
  - dim_topic を改訂すると全ファクトに即反映される
- **Negative**:
  - JOINコストが OBT より発生
  - weight 改訂時の **時系列遡及** ができない（SCD Type-1のため）
- **Mitigations**:
  - 個人利用ではJOINコストは無視できるレベル
  - weight改訂を時系列で追いたくなったらSCD Type-2への移行を検討（[ROADMAP.md](../ROADMAP.md) Phase 3）
