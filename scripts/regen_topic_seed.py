#!/usr/bin/env python3
"""
data/seed/topics.yaml を 単一ソースとして
sql/03_seed_dim_topic.sql を再生成する。

DEパターンの「設定はデータ、コードは生成」を体現するスクリプト。

実行:
  pip install pyyaml
  python scripts/regen_topic_seed.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "seed" / "topics.yaml"
DST = ROOT / "sql" / "03_seed_dim_topic.sql"

HEADER = """-- ============================================================
-- 03_seed_dim_topic.sql (auto-generated; do not edit by hand)
-- source: data/seed/topics.yaml
-- 統計検定2級 出題範囲表に基づく dim_topic 投入
-- 再生成: python scripts/regen_topic_seed.py
-- ============================================================
"""

FOOTER = """
-- dim_dateの初期投入
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
"""


def main() -> int:
    data = yaml.safe_load(SRC.read_text(encoding="utf-8"))
    topics = data.get("topics", [])
    if not topics:
        print("topicsが空です", file=sys.stderr)
        return 1

    rows = []
    for t in topics:
        rows.append(
            "    STRUCT('{id}' AS topic_id, '{major}' AS major_category, "
            "'{minor}' AS minor_category, {weight} AS weight, "
            "{target} AS target_pass_rate)".format(
                id=t["id"],
                major=t["major"],
                minor=t["minor"],
                weight=t["weight"],
                target=t["target_pass_rate"],
            )
        )

    body = (
        "MERGE `${PROJECT_ID}.stats_mart.dim_topic` T\n"
        "USING (\n"
        "  SELECT * FROM UNNEST([\n" + ",\n".join(rows) + "\n  ])\n"
        ") S\n"
        "ON T.topic_id = S.topic_id\n"
        "WHEN MATCHED THEN UPDATE SET\n"
        "  major_category   = S.major_category,\n"
        "  minor_category   = S.minor_category,\n"
        "  weight           = S.weight,\n"
        "  target_pass_rate = S.target_pass_rate\n"
        "WHEN NOT MATCHED THEN INSERT ROW;\n"
    )

    DST.write_text(HEADER + "\n" + body + FOOTER, encoding="utf-8")
    print(f"✅ 生成完了: {DST.relative_to(ROOT)}  ({len(topics)} topics)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
