"""pytest共通fixture

CI環境では GCP認証情報も functions_framework も無いため、
backend/main.py を import する前に依存をモック化する必要がある。
そのため、import文より前にこのブロックを置いている。
"""

import os
import sys
from unittest.mock import MagicMock

# ============================================================
# CRITICAL: import文よりも前に実行する必要がある
# backend/main.py の import 時点で bigquery.Client() が呼ばれ
# google.auth が認証情報を探しに行ってしまうため、その前に
# google.cloud.bigquery と functions_framework をモックに差替える
# ============================================================

# 環境変数のデフォルト値設定（main.py の os.environ.get(...) 用）
os.environ.setdefault("GCP_PROJECT", "test-project")
os.environ.setdefault("BQ_DATASET_RAW", "stats_raw")
os.environ.setdefault("LIFF_CHANNEL_ID", "1234567890")
os.environ.setdefault("USER_ID_SALT", "test_salt_value")
os.environ.setdefault("ALLOWED_ORIGIN", "https://example.com")

# functions_framework をスタブ化（CIにインストールされない場合の保険）
if "functions_framework" not in sys.modules:
    _ff_stub = MagicMock()
    # @functions_framework.http デコレータを「何もしない通過」にする
    _ff_stub.http = lambda f: f
    sys.modules["functions_framework"] = _ff_stub

# google.cloud.bigquery をスタブ化(認証エラー回避)
_bq_stub = MagicMock()
_bq_stub.Client = MagicMock(return_value=MagicMock())
sys.modules["google.cloud"] = MagicMock()
sys.modules["google.cloud.bigquery"] = _bq_stub

# ============================================================
# ここから通常のpytest設定
# ============================================================

import pytest  # noqa: E402

# backendをimport pathに追加
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


@pytest.fixture(autouse=True)
def env(monkeypatch):
    """全テストで使う環境変数の固定"""
    monkeypatch.setenv("GCP_PROJECT", "test-project")
    monkeypatch.setenv("BQ_DATASET_RAW", "stats_raw")
    monkeypatch.setenv("LIFF_CHANNEL_ID", "1234567890")
    monkeypatch.setenv("USER_ID_SALT", "test_salt_value")
    monkeypatch.setenv("ALLOWED_ORIGIN", "https://example.com")


@pytest.fixture
def mock_bq(monkeypatch):
    """BigQueryクライアントをモック"""
    mock = MagicMock()
    mock.insert_rows_json.return_value = []  # 成功時は空list
    return mock


@pytest.fixture
def mock_verify_ok(monkeypatch):
    """LINE Verify APIを成功でモック"""

    def _verify(*args, **kwargs):
        return ("U1234567890abcdef", None)

    monkeypatch.setattr("main._verify_id_token", _verify)
    return _verify


@pytest.fixture
def mock_verify_fail(monkeypatch):
    def _verify(*args, **kwargs):
        return (None, "invalid_token")

    monkeypatch.setattr("main._verify_id_token", _verify)
    return _verify
