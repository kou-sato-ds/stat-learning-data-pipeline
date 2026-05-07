"""pytest共通fixture"""

import os
import sys
from unittest.mock import MagicMock

import pytest

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
