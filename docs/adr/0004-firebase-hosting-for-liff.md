# ADR-0004: LIFFのホスティングにFirebase Hostingを選ぶ

- **Status**: Accepted
- **Date**: 2026-04-04

## Context

LIFFアプリの **エンドポイントURL** にHTTPS必須・常時公開のホスティングが必要。

## Decision

**Firebase Hosting** を採用。

## Rationale

- **無料枠**: 1GB配信、10GBストレージ。個人ポートフォリオなら確実に範囲内
- **HTTPS自動**: LIFF登録時に必要で、Let's Encryptが自動更新
- **CLI完結**: `firebase deploy --only hosting` で完了
- **GCPプロジェクトと統合**: BigQueryやFunctionsと同じプロジェクトに置ける
- **CDN込み**: 世界各地のエッジから配信され、移動中の体感速度が良い

## Considered Alternatives

### Cloud Storage + Cloud CDN

- ✅ 同じGCP内で完結
- ❌ HTTPS設定が手動、ドメイン紐付けの手間が大きい

### Cloud Run (静的配信用)

- ✅ Functionsと統一感がある
- ❌ 静的ファイルにコンテナを使うのは過剰
- ❌ コールドスタートあり

### Vercel / Netlify

- ✅ 開発体験が極めて良い
- ❌ GCP外に出ると `gcloud` 系の統合管理が崩れる

## Consequences

- **Positive**: HTTPS取得・CDN配信を考えなくていい
- **Negative**:
  - Firebase CLIのログインが必要（`gcloud auth` と独立）
  - `firebase.json` がリポジトリに必要
- **Mitigations**:
  - `scripts/deploy.sh` が `firebase.json` と `.firebaserc` を自動生成
  - `.gitignore` で `.firebaserc` 等を除外（プロジェクト固有のため）
