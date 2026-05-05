# Security Policy

## サポート対象

このプロジェクトは個人ポートフォリオであり、production-grade のSLAは提供していません。
ただし、以下のセキュリティ事項は真摯に対応します。

## 報告手順

セキュリティ脆弱性を発見した場合は **Issuesで公開せず**、以下のいずれかでご連絡ください。

- GitHub Security Advisories の Private Vulnerability Reporting
- リポジトリ作成者のプロフィールページに記載の連絡先

48時間以内に初回返信、可能な限り14日以内に対応方針を共有します。

## スコープ

| カテゴリ | スコープ内 | スコープ外 |
|---|---|---|
| Cloud Functions のid_token検証ロジック | ✅ | LINEプラットフォーム自体 |
| `USER_ID_SALT` の取り扱い | ✅ | GCPサービスの脆弱性 |
| LIFFフロントエンドのXSS | ✅ | LINEアプリ自体 |
| BigQuery のIAM設定 | ✅ | BigQuery自体 |

## 既知の制約

セキュリティに関する**既知の妥協点**は [docs/KNOWN_LIMITATIONS.md §3](docs/KNOWN_LIMITATIONS.md) に開示しています:

- Cloud Functions が `--allow-unauthenticated` で公開されている
- LINE Verify APIに依存しているため、LINE側障害時に検証ができない
- レート制限が未実装

これらは Phase 2 で対応予定です ([ROADMAP.md](docs/ROADMAP.md))。

## 推奨設定

このリポジトリをforkして自分の環境にデプロイする際は、以下を必ず実施してください。

1. **`USER_ID_SALT` を再生成**: `openssl rand -hex 32`
2. **`.env` を絶対にコミットしない**: `.gitignore` で除外済み
3. **`ALLOWED_ORIGIN` を本番URLのみに制限**: `*` のままにしない
4. **GCPプロジェクトをポートフォリオ専用に分離**: 既存プロジェクトと混在させない
