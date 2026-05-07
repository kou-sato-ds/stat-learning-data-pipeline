-- ============================================================
-- 05_analysis_views.sql
-- 合格ライン到達度 / 解答時間ばらつき の分析ビュー
-- ============================================================

-- 直近30日の分野別パフォーマンス
CREATE OR REPLACE VIEW `${PROJECT_ID}.stats_mart.v_topic_perf_30d` AS
SELECT
  f.user_id_hash,
  f.topic_id,
  d.major_category,
  d.minor_category,
  d.weight,
  d.target_pass_rate,
  COUNT(*)                                            AS n_attempt,
  COUNTIF(f.is_correct)                               AS n_correct,
  SAFE_DIVIDE(COUNTIF(f.is_correct), COUNT(*))        AS accuracy,
  AVG(f.time_sec)                                     AS mean_time_sec,
  STDDEV_SAMP(f.time_sec)                             AS sd_time_sec,
  SAFE_DIVIDE(STDDEV_SAMP(f.time_sec), AVG(f.time_sec)) AS cv_time
FROM `${PROJECT_ID}.stats_mart.fact_answer` f
JOIN `${PROJECT_ID}.stats_mart.dim_topic`  d USING (topic_id)
WHERE f.answered_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND f.time_outlier_flag = FALSE
GROUP BY f.user_id_hash, f.topic_id, d.major_category, d.minor_category, d.weight, d.target_pass_rate;

-- 期待スコアと合格ラインカバレッジ
CREATE OR REPLACE VIEW `${PROJECT_ID}.stats_mart.v_expected_score` AS
SELECT
  user_id_hash,
  ROUND(SUM(accuracy * weight) / SUM(weight) * 100, 1) AS expected_score,
  ROUND(SUM(IF(accuracy >= target_pass_rate, weight, 0)) / SUM(weight) * 100, 1)
    AS topic_pass_coverage_pct,
  SUM(n_attempt) AS total_attempts_30d
FROM `${PROJECT_ID}.stats_mart.v_topic_perf_30d`
GROUP BY user_id_hash;

-- 弱点分野ランキング(CV降順 = 解答時間が不安定 = 知識が未定着の疑い)
CREATE OR REPLACE VIEW `${PROJECT_ID}.stats_mart.v_weak_topics` AS
SELECT
  user_id_hash,
  topic_id,
  major_category,
  minor_category,
  n_attempt,
  ROUND(accuracy, 3)            AS accuracy,
  ROUND(mean_time_sec, 1)       AS mean_time_sec,
  ROUND(sd_time_sec, 1)         AS sd_time_sec,
  ROUND(cv_time, 3)             AS cv_time,
  -- 「正解率は届いているがCVが大きい」=危険信号
  IF(accuracy >= target_pass_rate AND cv_time > 0.5, TRUE, FALSE) AS unstable_flag
FROM `${PROJECT_ID}.stats_mart.v_topic_perf_30d`
WHERE n_attempt >= 5;

-- 週次スコア推移(逆算プランニング用のスナップショット)
CREATE OR REPLACE VIEW `${PROJECT_ID}.stats_mart.v_weekly_score` AS
SELECT
  user_id_hash,
  DATE_TRUNC(date_id, WEEK(MONDAY)) AS week_start,
  ROUND(
    SUM(IF(is_correct, weight, 0)) / NULLIF(SUM(weight), 0) * 100,
    1
  ) AS weekly_expected_score,
  COUNT(*) AS n_attempt
FROM `${PROJECT_ID}.stats_mart.fact_answer` f
JOIN `${PROJECT_ID}.stats_mart.dim_topic`  USING (topic_id)
WHERE time_outlier_flag = FALSE
GROUP BY user_id_hash, week_start;
