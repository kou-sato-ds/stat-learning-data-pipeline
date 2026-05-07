# ADR-0001: Record Architecture Decisions

- **Status**: Accepted
- **Date**: 2026-04-01
- **Context**: 個人プロジェクトでも、設計の意思決定を後から振り返れる形で残したい。
- **Decision**: Architecture Decision Record (ADR) を `docs/adr/` 配下に置く。フォーマットは [MADR](https://adr.github.io/madr/) の最小形式に近い。
- **Consequences**:
  - 各重要判断について `Status / Context / Decision / Consequences` の4項目を残す
  - 過去のADRは原則 immutable。覆す場合は **新しいADRを書いて参照** する
  - PRレビューで設計判断を議論する際の起点になる
