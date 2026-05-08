"""
analysis/anova_weak_topics.py
解答時間の分散分析(ANOVA)で弱点分野を統計的に特定する。

実行例:
  pip install google-cloud-bigquery pandas scipy
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json
  python analysis/anova_weak_topics.py --user-id-hash <hash> --project <proj>
"""

import argparse
import sys

import numpy as np
import pandas as pd
from google.cloud import bigquery
from scipy import stats


def fetch(project: str, user_id_hash: str) -> pd.DataFrame:
    bq = bigquery.Client(project=project)
    sql = f"""
      SELECT topic_id, time_sec, is_correct
      FROM `{project}.stats_mart.fact_answer`
      WHERE user_id_hash = @uid
        AND time_outlier_flag = FALSE
    """
    job = bq.query(
        sql,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("uid", "STRING", user_id_hash)],
        ),
    )
    return job.to_dataframe()


def iqr_filter(s: pd.Series, k: float = 1.5) -> pd.Series:
    q1, q3 = s.quantile([0.25, 0.75])
    iqr = q3 - q1
    return s[(s >= q1 - k * iqr) & (s <= q3 + k * iqr)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--user-id-hash", required=True)
    ap.add_argument(
        "--correct-only",
        action="store_true",
        help="正解のみ対象（不正解は思考時間のシグナルが乱れるため）",
    )
    args = ap.parse_args()

    df = fetch(args.project, args.user_id_hash)
    if df.empty:
        print("データがありません。")
        return 1
    if args.correct_only:
        df = df[df["is_correct"]]

    # 分野ごとに5件以上ある分野のみ対象、IQRで二重防御
    groups, labels = [], []
    for tid, g in df.groupby("topic_id"):
        cleaned = iqr_filter(g["time_sec"])
        if len(cleaned) >= 5:
            groups.append(cleaned.values)
            labels.append(tid)

    if len(groups) < 2:
        print("分散分析対象の分野が2つ未満です。データを増やしてください。")
        return 1

    # 等分散性
    levene = stats.levene(*groups)
    f_one = stats.f_oneway(*groups)

    print("=" * 60)
    print(f"対象分野数: {len(groups)} / 全データ: {sum(len(g) for g in groups)}件")
    print(f"Levene検定 (等分散性): W={levene.statistic:.3f}, p={levene.pvalue:.4f}")
    print(f"一元配置ANOVA: F={f_one.statistic:.3f}, p={f_one.pvalue:.4f}")
    if f_one.pvalue < 0.05:
        print("→ 分野間で解答時間に有意差あり: 学習リソースの配分を見直す根拠になる")
    else:
        print("→ 分野間で解答時間に有意差なし")

    # 分野ごとの統計を変動係数でソート
    print("\n--- 分野別ランキング (変動係数CV降順) ---")
    rows = []
    for tid, g in zip(labels, groups, strict=False):
        rows.append(
            {
                "topic_id": tid,
                "n": len(g),
                "mean_sec": round(np.mean(g), 1),
                "sd_sec": round(np.std(g, ddof=1), 1),
                "cv": round(np.std(g, ddof=1) / np.mean(g), 3),
            }
        )
    table = pd.DataFrame(rows).sort_values("cv", ascending=False)
    print(table.to_string(index=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
