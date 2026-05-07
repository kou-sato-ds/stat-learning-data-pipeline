-- ============================================================
-- 04_etl_raw_to_mart.sql
-- raw → mart のELT（MERGEで冪等）
-- Cloud Scheduler等で1時間おきに実行する想定
-- ============================================================

-- ----- fact_answer の更新 -----
MERGE `${PROJECT_ID}.stats_mart.fact_answer` T
USING (
  WITH dedup AS (
    -- answer_idで重複排除（端末オフラインキューの再送対策）
    SELECT * EXCEPT(rn) FROM (
      SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY answer_id ORDER BY ingested_at DESC) AS rn
      FROM `${PROJECT_ID}.stats_raw.answer_log`
      WHERE DATE(answered_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    ) WHERE rn = 1
  ),
  with_outlier AS (
    -- ユーザー × 分野ごとにIQR法で外れ値フラグ
    SELECT
      d.*,
      DATE(answered_at) AS date_id,
      CASE
        WHEN time_sec > p.q3 + 1.5 * (p.q3 - p.q1) THEN TRUE
        WHEN time_sec < p.q1 - 1.5 * (p.q3 - p.q1) THEN TRUE
        ELSE FALSE
      END AS time_outlier_flag
    FROM dedup d
    LEFT JOIN (
      SELECT
        user_id_hash,
        topic_id,
        APPROX_QUANTILES(time_sec, 4)[OFFSET(1)] AS q1,
        APPROX_QUANTILES(time_sec, 4)[OFFSET(3)] AS q3
      FROM `${PROJECT_ID}.stats_raw.answer_log`
      GROUP BY user_id_hash, topic_id
    ) p USING (user_id_hash, topic_id)
  )
  SELECT * FROM with_outlier
) S
ON T.answer_id = S.answer_id
WHEN MATCHED THEN UPDATE SET
  is_correct        = S.is_correct,
  time_sec          = S.time_sec,
  time_outlier_flag = S.time_outlier_flag,
  confidence        = S.confidence
WHEN NOT MATCHED THEN INSERT (
  answer_id, user_id_hash, question_id, topic_id, answered_at, date_id,
  is_correct, time_sec, time_outlier_flag, confidence, device, session_id
) VALUES (
  S.answer_id, S.user_id_hash, S.question_id, S.topic_id, S.answered_at, S.date_id,
  S.is_correct, S.time_sec, S.time_outlier_flag, S.confidence, S.device, S.session_id
);

-- ----- fact_shakyo の更新 -----
MERGE `${PROJECT_ID}.stats_mart.fact_shakyo` T
USING (
  SELECT
    *,
    DATE(executed_at) AS date_id
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY shakyo_id ORDER BY ingested_at DESC) AS rn
    FROM `${PROJECT_ID}.stats_raw.shakyo_log`
    WHERE DATE(executed_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  ) WHERE rn = 1
) S
ON T.shakyo_id = S.shakyo_id
WHEN NOT MATCHED THEN INSERT (
  shakyo_id, user_id_hash, topic_id, target_type, target_ref,
  executed_at, date_id, repetition_count, duration_sec
) VALUES (
  S.shakyo_id, S.user_id_hash, S.topic_id, S.target_type, S.target_ref,
  S.executed_at, S.date_id, S.repetition_count, S.duration_sec
);
