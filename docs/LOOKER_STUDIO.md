# Looker Studio ダッシュボード仕様

このプロジェクトのダッシュボードは Looker Studio で構築します。
レポート自体は Looker Studio の URL でしか共有できませんが、**ビジュアル要件をテキスト化**しておくことで再現性を担保します。

## ページ構成

### 📍 Page 1: 現在地サマリ

| ビジュアル | 種別 | データソース | 設定 |
|---|---|---|---|
| 期待スコア | スコアカード | `v_expected_score` | 値: `expected_score`、目標値60に参照線 |
| 合格ライン到達分野% | スコアカード | `v_expected_score` | 値: `topic_pass_coverage_pct` |
| 累計学習量 | スコアカード | `v_expected_score` | 値: `total_attempts_30d` |
| 試験まで残日数 | スコアカード | `dim_date` | フィルタ: `date_id = CURRENT_DATE()`、値: `days_until_exam` |

### 📈 Page 2: 分野別パフォーマンス

| ビジュアル | 種別 | 設定 |
|---|---|---|
| 分野別正解率 | 棒グラフ | x: `minor_category`、y: `accuracy`、参照線: `target_pass_rate` |
| 不安定ゾーン | 散布図 | x: `accuracy`、y: `cv_time`、サイズ: `n_attempt`、色: `unstable_flag` |
| 分野別サマリ | 表 | `v_topic_perf_30d` 全列、CV降順 |

### 📉 Page 3: 時系列トレンド

| ビジュアル | 種別 | 設定 |
|---|---|---|
| 週次スコア推移 | 折れ線 | x: `week_start`、y: `weekly_expected_score`、参照線: 60と70 |
| 学習量の推移 | 棒グラフ | x: 日次、y: `n_attempt`、累積モード |
| 写経実施回数 | 折れ線 | `fact_shakyo` を集計 |

### 🎯 Page 4: 弱点ダッシュボード

| ビジュアル | 種別 | 設定 |
|---|---|---|
| Unstable分野リスト | 表 | `v_weak_topics WHERE unstable_flag=TRUE` |
| Top10弱点（CV順） | 表 | `v_weak_topics ORDER BY cv_time DESC LIMIT 10` |
| 写経 vs 解答時間ばらつき | 散布図 | x: `repetition_count`、y: `cv_time` |

## 推奨フィルタ（全ページ共通）

- 期間（直近7日 / 30日 / 全期間）
- 分野（major_category）

## 配色

- **合格ライン (60点)**: グレー破線
- **目標 (70点)**: 緑実線
- **不安定フラグ**: 赤
- **正解**: LINE緑 (#06C755)
- **不正解**: 赤

## 再現手順（簡略版）

1. <https://lookerstudio.google.com/> で「空のレポート」
2. データソース追加 → BigQuery → プロジェクト → `stats_mart` → 各ビュー
3. このドキュメントのページ構成通りにビジュアルを配置
4. レポート → 共有 → リンクを取得して README からリンク

## 将来構想

- **テンプレートのJSON化**: Looker Studioは公式にテンプレ機能を提供しているが、APIでの完全自動構築は未対応。Phase 3でカスタムフロントエンド化を検討。
