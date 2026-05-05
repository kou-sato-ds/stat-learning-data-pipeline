# Contributing

このプロジェクトは個人ポートフォリオですが、**改善案やバグ報告を歓迎** します。

## バグ報告 / 機能要望

[Issues](../../issues) から、用意されているテンプレートを使って起票してください。

## 開発フロー

```bash
# 1. 開発依存のインストール
make setup

# 2. 機能ブランチを切る
git checkout -b feat/your-feature

# 3. ローカルで lint と test を通す
make check

# 4. PR作成
git push origin feat/your-feature
```

## コーディング規約

| 言語 | ツール | 設定 |
|---|---|---|
| Python | `ruff` (lint + format) | `pyproject.toml` |
| SQL | `sqlfluff` (推奨、CIには未統合) | dialect: `bigquery` |
| JavaScript | フォーマッタ未統合 | Phase 2で `prettier` 検討 |

## コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) に概ね沿う。

```
feat(backend): add JWKS verification path
fix(frontend): handle online event during init
docs(adr): add ADR-0006 for dbt migration
chore(deps): bump functions-framework to 3.5
```

## ブランチ命名

- `feat/...` 機能追加
- `fix/...` バグ修正
- `docs/...` ドキュメントのみ
- `refactor/...` 挙動を変えないリファクタ
- `test/...` テスト追加

## レビュー基準

- 主要な設計判断には **ADRを追加**
- 既存ADRと矛盾する変更は、新しいADRで上書きを宣言
- テストの追加もしくは変更がある場合、CIがすべてグリーン

## ローカル動作確認

```bash
# Python関連
make test        # pytest
make lint        # ruff check

# シェルスクリプトの構文確認
make lint-sh

# SQLのdry-run（要 gcloud auth）
make sql-dryrun
```
