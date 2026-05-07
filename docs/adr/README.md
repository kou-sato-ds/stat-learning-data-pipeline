# Architecture Decision Records

このプロジェクトの設計判断を記録したログです。
各ADRは原則 immutable で、覆す場合は新しいADRを書いて参照します。

## 目次

| 番号 | タイトル | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | ADRを採用する | Accepted |
| [0002](0002-bigquery-as-warehouse.md) | データウェアハウスにBigQueryを選ぶ | Accepted |
| [0003](0003-line-id-token-verification.md) | LINE id_token をサーバ側で検証する | Accepted（Phase 2でJWKSへ） |
| [0004](0004-firebase-hosting-for-liff.md) | LIFFのホスティングにFirebase Hostingを選ぶ | Accepted |
| [0005](0005-star-schema.md) | Star Schemaを採用する | Accepted |
| [0006](0006-migration-from-fastapi-to-cloud-functions.md) | FastAPI/Pandas構成から Cloud Functions/BigQuery構成への移行 | Accepted |

## 新規追加方法

1. `_template.md` をコピーして `NNNN-short-slug.md` にリネーム
2. 番号は連番。欠番禁止
3. PR内で議論し、レビュー後に `Status: Accepted` で merge
4. このREADMEの目次にも追加
