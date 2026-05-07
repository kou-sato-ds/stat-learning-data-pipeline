"""ハッシュ化ロジックのテスト"""

import os

from main import _hash_user_id


def test_hash_deterministic():
    """同じ入力は同じハッシュを返す（join可能性の保証）"""
    h1 = _hash_user_id("U1234567890abcdef")
    h2 = _hash_user_id("U1234567890abcdef")
    assert h1 == h2


def test_hash_length():
    """SHA256は常に64文字16進"""
    h = _hash_user_id("any_user_id")
    assert len(h) == 64
    assert all(c in "0123456789abcdef" for c in h)


def test_hash_different_users():
    """別ユーザーは別ハッシュ"""
    h1 = _hash_user_id("UAAAAAAAAA")
    h2 = _hash_user_id("UBBBBBBBBB")
    assert h1 != h2


def test_hash_salt_changes_output(monkeypatch):
    """saltが変わると同じユーザーでもハッシュが変わる"""
    h1 = _hash_user_id("U1")
    monkeypatch.setenv("USER_ID_SALT", "different_salt")
    # 注: _hash_user_idはモジュール定数のUSER_ID_SALTを使うため、
    # この振る舞いはモジュールリロードしないと完全には検証できない。
    # ここではsalt再現性のドキュメント目的でテストを残す
    import importlib

    import main as m
    importlib.reload(m)
    h2 = m._hash_user_id("U1")
    assert h1 != h2

    # 元に戻す
    monkeypatch.setenv("USER_ID_SALT", "test_salt_value")
    importlib.reload(m)
