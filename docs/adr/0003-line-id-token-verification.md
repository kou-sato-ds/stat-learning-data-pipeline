# ADR-0003: LINE id_token をサーバ側で検証する

- **Status**: Accepted（Phase 2でJWKS検証への移行を予定）
- **Date**: 2026-04-03

## Context

LIFFは `liff.getProfile().userId` でクライアント側からLINE userId を取得できるが、これを直接信用してBigQueryに保存すると、改ざんされたuserIdで他人になりすませるリスクがある。

## Decision

クライアントは `liff.getIDToken()` で発行された **id_token** をAPIリクエストに添付し、サーバ側 (Cloud Functions) は **LINE Verify API** (`https://api.line.me/oauth2/v2.1/verify`) でこれを検証する。検証成功時の `sub` クレームから userId を抽出する。

## Rationale

- LINE userId はディメンションキーになるため、改ざんは即データ汚染に繋がる
- LIFFの `getProfile()` の戻り値は **クライアント側で改変可能** なJSON
- id_token はLINE側の秘密鍵で署名されているため、検証すれば信用できる

## Considered Alternatives

### A. クライアント信頼 (検証なし)

- ✅ 実装コストゼロ
- ❌ なりすまし可能、ポートフォリオレベルとしても弱い

### B. JWKS によるローカルJWT検証

- ✅ 外部API呼び出しが不要、レイテンシ削減、可用性向上
- ❌ 初回実装コストがやや高い、JWKSのキャッシュ戦略も必要
- → **Phase 2 で移行予定**（[KNOWN_LIMITATIONS §3.2](../KNOWN_LIMITATIONS.md)）

## Consequences

- **Positive**: なりすまし対策ができ、データの真正性が保証される
- **Negative**:
  - 毎リクエスト LINE Verify API への呼び出しが発生（+50〜200ms）
  - LINE側がダウンするとアプリも応答不能
- **Mitigations**:
  - Phase 2 で JWKS ローカル検証 + 短期キャッシュに移行
  - 個人利用の現段階ではレイテンシ・可用性ともに許容範囲

## 関連

- [docs/KNOWN_LIMITATIONS.md §3.2](../KNOWN_LIMITATIONS.md) - LINE Verify API依存
