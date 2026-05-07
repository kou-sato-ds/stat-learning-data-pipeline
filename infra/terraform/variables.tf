variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "region" {
  description = "Cloud Functionsのデプロイリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "bq_location" {
  description = "BigQueryのロケーション"
  type        = string
  default     = "asia-northeast1"
}

variable "liff_channel_id" {
  description = "LINE LoginチャネルID(audience検証に使用)"
  type        = string
  sensitive   = true
}

variable "user_id_salt" {
  description = "user_idハッシュ化のソルト"
  type        = string
  sensitive   = true
}

variable "allowed_origin" {
  description = "CORS許可オリジン"
  type        = string
}
