"""
analysis/score_projection.py
週次スナップショットから試験日のスコアを単回帰で予測する。
出題範囲の「線形モデル」をそのまま自分の学習データに適用する写経課題。

実行例:
  python analysis/score_projection.py --project your-proj --user-id-hash <hash> --exam 2026-07-31
"""

import argparse
import sys
from datetime import date
import numpy as np
import pandas as pd
from scipy import stats
from google.cloud import bigquery


def fetch_weekly(project: str, user_id_hash: str) -> pd.DataFrame:
    bq = bigquery.Client(project=project)
    sql = f"""
      SELECT week_start, weekly_expected_score, n_attempt
      FROM `{project}.stats_mart.v_weekly_score`
      WHERE user_id_hash = @uid
        AND n_attempt >= 5
      ORDER BY week_start
    """
    job = bq.query(
        sql,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("uid", "STRING", user_id_hash)],
        ),
    )
    return job.to_dataframe()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--user-id-hash", required=True)
    ap.add_argument("--exam", required=True, help="試験日 YYYY-MM-DD")
    args = ap.parse_args()

    df = fetch_weekly(args.project, args.user_id_hash)
    if len(df) < 3:
        print("週次データが3週未満です。学習を続けて再実行してください。")
        return 1

    # x: 経過週、y: 期待スコア
    df["x"] = (pd.to_datetime(df["week_start"]) - pd.to_datetime(df["week_start"].min())).dt.days / 7.0
    x = df["x"].values
    y = df["weekly_expected_score"].values

    slope, intercept, r, p, se = stats.linregress(x, y)
    n = len(x)
    exam_x = (pd.to_datetime(args.exam) - pd.to_datetime(df["week_start"].min())).days / 7.0
    y_hat = slope * exam_x + intercept

    # 予測の95%区間 (簡易: t * residual SE * sqrt(1 + 1/n + (x-x̄)^2/Sxx))
    residuals = y - (slope * x + intercept)
    s_err = np.sqrt(np.sum(residuals**2) / (n - 2)) if n > 2 else float("nan")
    sxx = np.sum((x - x.mean())**2)
    se_pred = s_err * np.sqrt(1 + 1/n + (exam_x - x.mean())**2 / sxx) if sxx > 0 else float("nan")
    t_crit = stats.t.ppf(0.975, df=n-2) if n > 2 else 2.0
    pi = (y_hat - t_crit * se_pred, y_hat + t_crit * se_pred)

    print("=" * 60)
    print(f"観測週数: {n} / 範囲: {df['week_start'].min().date()} 〜 {df['week_start'].max().date()}")
    print(f"回帰式: score = {slope:.2f} * weeks + {intercept:.2f}")
    print(f"R^2 = {r**2:.3f}, p = {p:.4f}, 傾きSE = {se:.3f}")
    print(f"\n試験日({args.exam})の予測スコア: {y_hat:.1f}")
    print(f"95%予測区間: [{pi[0]:.1f}, {pi[1]:.1f}]")
    if pi[0] < 60:
        print("⚠️ 予測区間の下限が60を割っています。学習リソースの集中投下を推奨。")
    else:
        print("✅ 現状ペースで合格圏内")
    return 0


if __name__ == "__main__":
    sys.exit(main())
