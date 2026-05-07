-- ============================================================
-- 01_create_dataset.sql
-- BigQuery: データセット作成（raw層 / mart層）
-- ============================================================

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.stats_raw`
OPTIONS(
  description = "LIFFから直接書き込むraw層（append-only）",
  location    = "${BQ_LOCATION}"
);

CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.stats_mart`
OPTIONS(
  description = "Star Schemaで再構成した分析mart層",
  location    = "${BQ_LOCATION}"
);
