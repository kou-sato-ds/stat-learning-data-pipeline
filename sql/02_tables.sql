-- ============================================================
-- 02_tables.sql
-- raw層 + mart層（Star Schema）のテーブル定義
-- ============================================================

-- ---------- raw層（Cloud Functionsからの直接書き込み先）----------

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_raw.answer_log` (
  answer_id        STRING NOT NULL,                -- UUID
  user_id_hash     STRING NOT NULL,                -- LINE userIdをSHA256化
  question_id      STRING NOT NULL,
  topic_id         STRING NOT NULL,                -- 例: T22
  answered_at      TIMESTAMP NOT NULL,
  is_correct       BOOL NOT NULL,
  time_sec         INT64 NOT NULL,
  confidence       INT64,                          -- 1-5
  device           STRING,                         -- line_inapp / external_browser
  session_id       STRING,
  ingested_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(answered_at)
CLUSTER BY user_id_hash, topic_id
OPTIONS (description = "解答ログの生データ（重複排除前）");

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_raw.shakyo_log` (
  shakyo_id        STRING NOT NULL,
  user_id_hash     STRING NOT NULL,
  topic_id         STRING NOT NULL,
  target_type      STRING NOT NULL,                -- formula / code / proof
  target_ref       STRING NOT NULL,
  executed_at      TIMESTAMP NOT NULL,
  repetition_count INT64 NOT NULL,
  duration_sec     INT64,
  ingested_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(executed_at)
CLUSTER BY user_id_hash, topic_id
OPTIONS (description = "写経ログの生データ");

-- ---------- mart層（Star Schema）----------

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_mart.dim_topic` (
  topic_id         STRING NOT NULL,
  major_category   STRING NOT NULL,
  minor_category   STRING NOT NULL,
  weight           FLOAT64 NOT NULL,               -- 出題頻度から正規化
  target_pass_rate FLOAT64 NOT NULL                -- 合格に必要な分野別正解率
);

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_mart.dim_user` (
  user_id_hash     STRING NOT NULL,
  display_name     STRING,
  target_exam_date DATE,
  created_at       TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_mart.dim_date` (
  date_id          DATE NOT NULL,
  iso_week         INT64,
  day_of_week      INT64,
  is_weekend       BOOL,
  days_until_exam  INT64
);

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_mart.fact_answer` (
  answer_id         STRING NOT NULL,
  user_id_hash      STRING NOT NULL,
  question_id       STRING NOT NULL,
  topic_id          STRING NOT NULL,
  answered_at       TIMESTAMP NOT NULL,
  date_id           DATE NOT NULL,
  is_correct        BOOL NOT NULL,
  time_sec          INT64 NOT NULL,
  time_outlier_flag BOOL NOT NULL,
  confidence        INT64,
  device            STRING,
  session_id        STRING
)
PARTITION BY date_id
CLUSTER BY user_id_hash, topic_id;

CREATE TABLE IF NOT EXISTS `${PROJECT_ID}.stats_mart.fact_shakyo` (
  shakyo_id        STRING NOT NULL,
  user_id_hash     STRING NOT NULL,
  topic_id         STRING NOT NULL,
  target_type      STRING NOT NULL,
  target_ref       STRING NOT NULL,
  executed_at      TIMESTAMP NOT NULL,
  date_id          DATE NOT NULL,
  repetition_count INT64 NOT NULL,
  duration_sec     INT64
)
PARTITION BY date_id
CLUSTER BY user_id_hash, topic_id;
