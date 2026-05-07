# Terraform (Phase 2 用雛形)

このディレクトリは **将来の Terraform 化のための雛形** です。
現状の本番デプロイは `scripts/deploy.sh` による `gcloud` 直叩きで行っています。

## 移行の段取り（[ROADMAP.md](../../docs/ROADMAP.md) Phase 2）

1. `terraform init` でプロバイダ初期化
2. BigQuery dataset を `import` で取り込む
3. Cloud Functions を `import` で取り込む
4. Firebase Hosting は Terraform プロバイダ未対応のため、当面は CLI を併用
5. CIに `terraform plan` を組み込み、差分が出たら警告

## 現時点で含まれているもの

- `main.tf` — BigQuery dataset 2つの定義、Functions のコメントアウト雛形
- `variables.tf` — 主要変数の宣言
- `terraform.tfvars.example` — `terraform.tfvars` のテンプレ

## 使い方（雛形のテストのみ）

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars  # 値を埋める
terraform init
terraform plan
```

> 注意: 既存の dataset がある場合は `terraform import` で取り込まないと作成エラーになります。

## なぜ最初から Terraform にしなかったか

[ADR-0002](../../docs/adr/0002-bigquery-as-warehouse.md) と [KNOWN_LIMITATIONS §6.2](../../docs/KNOWN_LIMITATIONS.md) を参照。
個人プロジェクト初期では `gcloud` 直叩きで十分早く、Terraform の学習・運用コストが当初は釣り合わないと判断しました。
