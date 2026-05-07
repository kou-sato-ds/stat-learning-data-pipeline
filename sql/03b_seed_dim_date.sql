-- ============================================================
-- 03b_seed_dim_date.sql (auto-split from 03)
-- DECLARE は先頭に置く必要があるため、このファイルに分離
-- ============================================================

DECLARE exam_date DATE DEFAULT DATE('${EXAM_DATE}');

MERGE `${PROJECT_ID}.stats_mart.dim_date` T
USING (
  SELECT
    d AS date_id,
    EXTRACT(ISOWEEK FROM d) AS iso_week,
    EXTRACT(DAYOFWEEK FROM d) AS day_of_week,
    EXTRACT(DAYOFWEEK FROM d) IN (1, 7) AS is_weekend,
    DATE_DIFF(exam_date, d, DAY) AS days_until_exam
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-01-01', '2026-12-31')) AS d
) S
ON T.date_id = S.date_id
WHEN NOT MATCHED THEN INSERT ROW;
