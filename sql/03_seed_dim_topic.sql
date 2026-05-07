-- ============================================================
-- 03_seed_dim_topic.sql (auto-generated; do not edit by hand)
-- source: data/seed/topics.yaml
-- 統計検定2級 出題範囲表に基づく dim_topic 投入
-- 再生成: python scripts/regen_topic_seed.py
-- ============================================================

MERGE `${PROJECT_ID}.stats_mart.dim_topic` T
USING (
  SELECT * FROM UNNEST([
    STRUCT('T01' AS topic_id, 'データソース' AS major_category, '身近な統計' AS minor_category, 0.2 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T02' AS topic_id, 'データの分布' AS major_category, 'データの分布の記述' AS minor_category, 0.3 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T03' AS topic_id, 'データの分布' AS major_category, 'データの分布の記述(発展)' AS minor_category, 0.5 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T04' AS topic_id, '1変数データ' AS major_category, '代表値と散布度' AS minor_category, 0.8 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T05' AS topic_id, '1変数データ' AS major_category, '散らばりの把握(箱ひげ図)' AS minor_category, 0.6 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T06' AS topic_id, '1変数データ' AS major_category, '散らばりの把握(その他)' AS minor_category, 0.4 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T07' AS topic_id, '1変数データ' AS major_category, '中心と散らばりの活用' AS minor_category, 0.7 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T08' AS topic_id, '2変数以上のデータ' AS major_category, '散布図と相関' AS minor_category, 0.9 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T09' AS topic_id, '2変数以上のデータ' AS major_category, 'カテゴリカルデータ' AS minor_category, 0.4 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T10' AS topic_id, 'データの活用' AS major_category, '単回帰と予測' AS minor_category, 0.6 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T11' AS topic_id, 'データの活用' AS major_category, '時系列データの処理' AS minor_category, 0.5 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T12' AS topic_id, '推測のためのデータ収集法' AS major_category, '観察研究と実験研究' AS minor_category, 0.4 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T13' AS topic_id, '推測のためのデータ収集法' AS major_category, '標本調査と無作為抽出' AS minor_category, 0.5 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T14' AS topic_id, '推測のためのデータ収集法' AS major_category, '実験' AS minor_category, 0.3 AS weight, 0.55 AS target_pass_rate),
    STRUCT('T15' AS topic_id, '確率モデルの導入' AS major_category, '確率' AS minor_category, 0.8 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T16' AS topic_id, '確率モデルの導入' AS major_category, '確率変数(変数型)' AS minor_category, 0.3 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T17' AS topic_id, '確率モデルの導入' AS major_category, '確率変数(基本)' AS minor_category, 0.9 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T18' AS topic_id, '確率モデルの導入' AS major_category, '確率変数(応用)' AS minor_category, 0.5 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T19' AS topic_id, '確率モデルの導入' AS major_category, '確率分布' AS minor_category, 0.8 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T20' AS topic_id, '推測' AS major_category, '標本分布(基本)' AS minor_category, 0.8 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T21' AS topic_id, '推測' AS major_category, '標本分布(応用)' AS minor_category, 0.4 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T22' AS topic_id, '推測' AS major_category, '標本分布(正規母集団)' AS minor_category, 1.0 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T23' AS topic_id, '推測' AS major_category, '推定(基本)' AS minor_category, 0.9 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T24' AS topic_id, '推測' AS major_category, '推定(1つの母集団)' AS minor_category, 0.7 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T25' AS topic_id, '推測' AS major_category, '推定(2つの母集団)' AS minor_category, 0.5 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T26' AS topic_id, '推測' AS major_category, '仮説検定(基本)' AS minor_category, 1.0 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T27' AS topic_id, '推測' AS major_category, '仮説検定(応用)' AS minor_category, 0.5 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T28' AS topic_id, '推測' AS major_category, '仮説検定(1つの母集団)' AS minor_category, 0.7 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T29' AS topic_id, '推測' AS major_category, '仮説検定(2つの母集団)' AS minor_category, 0.7 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T30' AS topic_id, '推測' AS major_category, '仮説検定(適合度/独立性)' AS minor_category, 0.7 AS weight, 0.65 AS target_pass_rate),
    STRUCT('T31' AS topic_id, '線形モデル' AS major_category, '回帰分析(基本)' AS minor_category, 0.8 AS weight, 0.7 AS target_pass_rate),
    STRUCT('T32' AS topic_id, '線形モデル' AS major_category, '回帰分析(応用)' AS minor_category, 0.5 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T33' AS topic_id, '線形モデル' AS major_category, '実験計画の概念の理解' AS minor_category, 0.4 AS weight, 0.6 AS target_pass_rate),
    STRUCT('T34' AS topic_id, '活用' AS major_category, '統計ソフトウェアの活用' AS minor_category, 0.4 AS weight, 0.55 AS target_pass_rate)
  ])
) S
ON T.topic_id = S.topic_id
WHEN MATCHED THEN UPDATE SET
  major_category   = S.major_category,
  minor_category   = S.minor_category,
  weight           = S.weight,
  target_pass_rate = S.target_pass_rate
WHEN NOT MATCHED THEN INSERT ROW;

-- dim_dateの初期投入
