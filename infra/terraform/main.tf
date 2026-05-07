# ============================================================
# infra/terraform/main.tf
# Phase 2移行用の雛形。現状はscripts/deploy.sh による gcloud 直叩きを使用。
# 本格移行時はこのモジュールを充足させ、scripts/deploy.sh と並行運用してから切り替える。
# ============================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # backend "gcs" {
  #   bucket = "stats-liff-tfstate"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ----- BigQuery datasets -----
resource "google_bigquery_dataset" "raw" {
  dataset_id  = "stats_raw"
  location    = var.bq_location
  description = "LIFFから直接書き込むraw層（append-only）"
}

resource "google_bigquery_dataset" "mart" {
  dataset_id  = "stats_mart"
  location    = var.bq_location
  description = "Star Schemaで再構成した分析mart層"
}

# ----- Cloud Functions の最小設定 -----
# 注: ソースアーカイブのアップロード・GCS bucket作成は別途必要。
# 完全実装は Phase 2 で対応。
#
# resource "google_cloudfunctions2_function" "ingest_answer" {
#   name        = "ingestAnswer"
#   location    = var.region
#   description = "解答ログをBigQueryに書き込む"
#
#   build_config {
#     runtime     = "python311"
#     entry_point = "ingestAnswer"
#     source { ... }
#   }
#
#   service_config {
#     max_instance_count = 10
#     available_memory   = "256Mi"
#     timeout_seconds    = 30
#     environment_variables = {
#       GCP_PROJECT      = var.project_id
#       BQ_DATASET_RAW   = "stats_raw"
#       LIFF_CHANNEL_ID  = var.liff_channel_id
#       USER_ID_SALT     = var.user_id_salt
#       ALLOWED_ORIGIN   = var.allowed_origin
#     }
#   }
# }
