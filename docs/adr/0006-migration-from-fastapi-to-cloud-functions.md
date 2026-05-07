# ADR-0006: FastAPI/Pandas構成から Cloud Functions/BigQuery構成への移行

- **Status**: Accepted
- **Date**: 2026-05-07
- **Supersedes**: なし（プロジェクト全体の方向転換）

## Context

プロジェクト発足当初、本リポジトリは **FastAPI でクイズ問題を配信するREST API** として始まった。
しかしプロジェクトを進める中で、**プロダクトの目的そのものが変質した** ことに気づいた:

| | 当初の目的 | 実際にやりたかったこと |
|---|---|---|
| 主体 | 問題を**配信する** | 自分の学習を**分析する** |
| データの流れ | サーバー → ユーザー | ユーザー → サーバー → 分析 |
| 主役 | 問題コンテンツ | 学習行動ログ |

つまり、**「問題集アプリ」ではなく「自分専用の学習ダッシュボード」**を作りたかったのである。
この気づきにより、技術スタックの全面見直しが必要になった。

## Decision

**FastAPI/pandas/CSV 構成を捨て、Cloud Functions Gen2 / BigQuery / Firebase Hosting 構成に全面移行する。**

旧FastAPI実装は削除せず、`docs/archive/fastapi-experiment/` に資料として保存する。

## Rationale

### 移行を決めた4つの理由

#### 理由1: データの「向き」が変わった

- **旧構成**: サーバー側のCSVを**配信する** (read-heavy)
- **新構成**: クライアント側の行動ログを**蓄積する** (write-heavy + analytical)

CSVベースでは10万行を超えると pandas の読み込みが遅くなり、集計クエリも書きづらい。BigQuery なら列指向ストレージとSQL集計で、年間100万行でも数秒で集計できる。

#### 理由2: 常時稼働の必要性が消えた

- **旧構成**: uvicorn を常時起動しないと API が応答しない
- **新構成**: イベント駆動 (リクエスト時のみ起動)

学習ログ送信は1日多くて数十回。常時稼働サーバーは過剰投資だった。Cloud Functions Gen2 のコールドスタート 2〜3 秒は許容範囲。

#### 理由3: 分析機能が標準で組み込まれる

- **旧構成**: 集計や統計分析は別途 pandas / scipy で書く必要があった
- **新構成**: BigQuery の SQL でほぼ完結、Looker Studio が無料で使える

統計検定2級の合格判定（期待スコア / 分野別CV / 単回帰予測）が、SQLビューと Python スクリプト数本で表現できるようになった。

#### 理由4: LIFF との親和性

- **旧構成**: LIFF と統合するには別途 OAuth ロジックを書く必要があった
- **新構成**: id_token 検証ロジックを Cloud Functions に組み込み済み

LINE Verify API へのトークン検証→ハッシュ化→BigQuery書込みが、`backend/main.py` 1ファイルで完結する。

### 移行後の構成
詳細は [`README.md`](../../README.md) と [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) 参照。

## Considered Alternatives

### A. FastAPI 構成のまま継続する

- ✅ 既存コードがそのまま使える、追加学習コストなし
- ❌ クイズ配信専用設計のため、ログ収集には根本的に不向き
- ❌ 常時稼働サーバーのコスト・運用負荷
- ❌ 集計分析のたびに pandas スクリプトを書くことになる

### B. AWS Lambda + DynamoDB に移行する

- ✅ サーバーレス化のメリットは得られる
- ❌ DynamoDB は集計クエリが弱く、分析には向かない
- ❌ Looker Studio に該当する無料BIツールが AWS にはない
- ❌ 別途 Athena + S3 構成にすると複雑度が増す

### C. オンプレミス（自宅PC）で運用

- ✅ 完全コントロール、無料
- ❌ LIFF はHTTPSエンドポイント必須 → トンネリングサービス必要
- ❌ PCを24h起動する必要がある
- ❌ ポートフォリオとして「クラウドで動くもの」を見せたい

## Consequences

### Positive

- **目的とアーキテクチャが一致** した: ログ収集→蓄積→分析の流れが自然に表現できる
- **インフラコストがほぼゼロ** に: BigQuery 月10GB 無料枠、Cloud Functions も同様、Firebase Hosting も無料枠内
- **IaC化の準備が整った**: `scripts/deploy.sh` を Terraform 化する道筋が見えている（[ROADMAP](../ROADMAP.md) Phase 2）
- **分析機能が即座に使える**: SQL ビュー4本（`v_topic_perf_30d` 等）で合格判定の素材が揃う

### Negative

- **学習コスト**: gcloud / firebase / BigQuery / LIFF の同時習得が必要だった（ただし習得する価値は十分にあった）
- **コールドスタートのレイテンシ**: 初回送信時 2〜3秒の遅延（実害なし、移動中UXとしては許容）
- **クラウドベンダーロックイン**: BigQuery / Firebase Hosting への依存が増えた

### Mitigations

- 旧 FastAPI 実装は `docs/archive/fastapi-experiment/` に保管。万が一の再起動リスクへの保険とする
- ベンダーロックインは [`docs/KNOWN_LIMITATIONS.md`](../KNOWN_LIMITATIONS.md) で開示済み

## 学んだ教訓

### 「最初の構成」に固執しないこと

最初に作った FastAPI 実装は、それ自体は正しく動いていた。しかし「**目的に合っていない動くもの**」より「**目的に合った動くもの**」のほうが価値がある。

技術選定とは「最初の判断を守ること」ではなく「**目的が変わったら勇気を持って組み直すこと**」だと体感した。

### サンクコストに引きずられない

FastAPI の実装には数日かけていた。捨てるのは惜しかった。しかし「捨てる」のではなく「**アーカイブとして残す**」ことで、サンクコストとプロダクト価値の両立ができた。

### 振り返るための記録を残す

このADR自体が、半年後の自分に「なぜ Cloud Functions に乗り換えたのか」を思い出させるための記録である。
**後の自分は、今の自分ほどコンテキストを覚えていない。**

## 関連

- [`docs/archive/fastapi-experiment/README.md`](../archive/fastapi-experiment/README.md) - 旧実装の説明
- [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) - 新構成の詳細
- [`docs/KNOWN_LIMITATIONS.md`](../KNOWN_LIMITATIONS.md) - 新構成の制約
