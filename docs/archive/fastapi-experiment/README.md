# 📦 FastAPI 実験アーカイブ

このディレクトリには、本プロジェクトの**初期段階で試行した FastAPI ベースの実装**が保存されています。
後継として **Cloud Functions / BigQuery 構成** に移行したため、ここはあくまで歴史資料として残しています。

> ⚠️ このコードは**動作保証外**です。最新の実装は本リポジトリのルート (`backend/`, `frontend/`, `sql/`) を参照してください。

## なぜ FastAPI 構成を採用しなかったか

詳細は [`docs/adr/0006-migration-from-fastapi-to-cloud-functions.md`](../../adr/0006-migration-from-fastapi-to-cloud-functions.md) に記録しています。

要点だけ書くと:

| 項目 | FastAPI 構成（旧） | Cloud Functions 構成（新） |
|---|---|---|
| 主な役割 | クイズ問題の **配信API** | 学習ログの **収集パイプライン** |
| インフラ | サーバー常時稼働 (uvicorn) | サーバーレス (Gen2) |
| データ層 | CSV ファイル | BigQuery (Star Schema) |
| デプロイ | 手動運用前提 | `make deploy` で完結 |
| 分析機能 | なし | 期待スコア・分散分析・回帰予測 |
| LIFF統合 | 別途必要 | 標準対応 (id_token 検証含む) |

「**問題を出すアプリ**」から「**自分の学習を分析する基盤**」へと、プロジェクトの主軸が変わったため、技術スタックも刷新しました。

## ディレクトリ内訳

- `backend/main.py` - FastAPI 本体（Pydantic で型定義したクイズAPI）
- `backend/data/quiz_data.csv` - 統計検定2級向けクイズ40問
- `backend/requirements.txt` - 当時の依存（pandas / scikit-learn / torch 等を含む大きな依存ツリー）
- `backend/.env.example` - 当時の環境変数テンプレ

## なぜ消さずに残しているか

3つの理由があります:

1. **意思決定の変遷を見せる**: ポートフォリオとして「最初こうだった、こう判断して変えた」という流れは、技術選定の柔軟性を示す材料
2. **クイズデータの再利用**: `quiz_data.csv` は今後アプリ内に組み込む可能性あり（[ROADMAP](../../ROADMAP.md) 参照）
3. **再起動リスクへの保険**: 万が一 Cloud 構成で詰まった時に、ローカルで動かせる FastAPI 版があると安心
