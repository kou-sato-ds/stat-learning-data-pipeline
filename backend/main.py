"""
Cloud Functions (Gen 2) - Stats LIFF Ingest API

エンドポイント:
  POST /ingestAnswer  解答ログ1件
  POST /ingestShakyo  写経ログ1件

認証:
  Authorization: Bearer <LINE id_token>
  - LINE Verify APIで検証 → audienceがLIFF_CHANNEL_IDに一致することを確認
  - subject(LINE userId)をSHA256でハッシュ化してから保存

依存:
  google-cloud-bigquery, requests, functions-framework
"""

import hashlib
import logging
import os
import uuid
from datetime import UTC, datetime
from typing import Any

import functions_framework
import requests
from flask import Request, jsonify, make_response
from google.cloud import bigquery

# ---------- 設定 ----------
PROJECT_ID = os.environ.get("GCP_PROJECT", "test-project")
DATASET_RAW = os.environ.get("BQ_DATASET_RAW", "stats_raw")
LIFF_CHANNEL_ID = os.environ.get("LIFF_CHANNEL_ID", "0000000000")
USER_ID_SALT = os.environ.get("USER_ID_SALT", "test-salt-not-for-production")
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "*")
LINE_VERIFY_URL = "https://api.line.me/oauth2/v2.1/verify"

bq = bigquery.Client(project=PROJECT_ID)
logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)


# ---------- ユーティリティ ----------
def _cors_headers() -> dict[str, str]:
    return {
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
        "Access-Control-Max-Age": "3600",
    }


def _json_error(status: int, msg: str):
    resp = make_response(jsonify({"error": msg}), status)
    for k, v in _cors_headers().items():
        resp.headers[k] = v
    return resp


def _json_ok(payload: dict[str, Any]):
    resp = make_response(jsonify(payload), 200)
    for k, v in _cors_headers().items():
        resp.headers[k] = v
    return resp


def _verify_id_token(id_token: str) -> tuple[str | None, str | None]:
    """LINEのVerify APIでid_tokenを検証し (sub, error) を返す。"""
    try:
        r = requests.post(
            LINE_VERIFY_URL,
            data={"id_token": id_token, "client_id": LIFF_CHANNEL_ID},
            timeout=5,
        )
        if r.status_code != 200:
            return None, f"verify_failed: {r.status_code} {r.text[:200]}"
        body = r.json()
        if body.get("aud") != LIFF_CHANNEL_ID:
            return None, "aud_mismatch"
        sub = body.get("sub")
        if not sub:
            return None, "no_sub"
        return sub, None
    except Exception as e:
        return None, f"verify_exception: {e}"


def _hash_user_id(line_user_id: str) -> str:
    h = hashlib.sha256()
    h.update((USER_ID_SALT + line_user_id).encode("utf-8"))
    return h.hexdigest()


def _extract_token(req: Request) -> str | None:
    auth = req.headers.get("Authorization", "")
    if auth.lower().startswith("bearer "):
        return auth.split(" ", 1)[1].strip()
    return None


def _validate_answer_payload(p: dict[str, Any]) -> str | None:
    required = ["question_id", "topic_id", "is_correct", "time_sec"]
    for k in required:
        if k not in p:
            return f"missing field: {k}"
    if not isinstance(p["time_sec"], int) or p["time_sec"] < 0 or p["time_sec"] > 7200:
        return "time_sec out of range (0..7200)"
    if not isinstance(p["is_correct"], bool):
        return "is_correct must be bool"
    if (
        "confidence" in p
        and p["confidence"] is not None
        and (not isinstance(p["confidence"], int) or not (1 <= p["confidence"] <= 5))
    ):
        return "confidence must be int 1..5"
    if not isinstance(p["topic_id"], str) or not p["topic_id"].startswith("T"):
        return "topic_id must look like 'T22'"
    return None


def _validate_shakyo_payload(p: dict[str, Any]) -> str | None:
    required = ["topic_id", "target_type", "target_ref", "repetition_count"]
    for k in required:
        if k not in p:
            return f"missing field: {k}"
    if p["target_type"] not in ("formula", "code", "proof"):
        return "target_type must be one of formula/code/proof"
    if not isinstance(p["repetition_count"], int) or p["repetition_count"] <= 0:
        return "repetition_count must be positive int"
    return None


# ---------- ハンドラ本体 ----------
def _handle(req: Request, kind: str):
    if req.method == "OPTIONS":
        resp = make_response("", 204)
        for k, v in _cors_headers().items():
            resp.headers[k] = v
        return resp

    if req.method != "POST":
        return _json_error(405, "method not allowed")

    token = _extract_token(req)
    if not token:
        return _json_error(401, "missing bearer token")

    line_user_id, err = _verify_id_token(token)
    if err or not line_user_id:
        log.warning("token verify failed: %s", err)
        return _json_error(401, f"invalid token: {err}")

    user_id_hash = _hash_user_id(line_user_id)

    try:
        payload = req.get_json(silent=True) or {}
    except Exception:
        return _json_error(400, "invalid json")

    if kind == "answer":
        v = _validate_answer_payload(payload)
        if v:
            return _json_error(400, v)
        row = {
            "answer_id": payload.get("answer_id") or str(uuid.uuid4()),
            "user_id_hash": user_id_hash,
            "question_id": payload["question_id"],
            "topic_id": payload["topic_id"],
            "answered_at": payload.get("answered_at") or datetime.now(UTC).isoformat(),
            "is_correct": payload["is_correct"],
            "time_sec": payload["time_sec"],
            "confidence": payload.get("confidence"),
            "device": payload.get("device"),
            "session_id": payload.get("session_id"),
        }
        table = f"{PROJECT_ID}.{BQ_DATASET_RAW}.answer_log"
    elif kind == "shakyo":
        v = _validate_shakyo_payload(payload)
        if v:
            return _json_error(400, v)
        row = {
            "shakyo_id": payload.get("shakyo_id") or str(uuid.uuid4()),
            "user_id_hash": user_id_hash,
            "topic_id": payload["topic_id"],
            "target_type": payload["target_type"],
            "target_ref": payload["target_ref"],
            "executed_at": payload.get("executed_at") or datetime.now(UTC).isoformat(),
            "repetition_count": payload["repetition_count"],
            "duration_sec": payload.get("duration_sec"),
        }
        table = f"{PROJECT_ID}.{BQ_DATASET_RAW}.shakyo_log"
    else:
        return _json_error(400, "unknown kind")

    errors = bq.insert_rows_json(table, [row])
    if errors:
        log.error("bq insert errors: %s", errors)
        return _json_error(500, "bq insert failed")

    return _json_ok(
        {
            "ok": True,
            "id": row.get("answer_id") or row.get("shakyo_id"),
        }
    )


# ---------- エントリーポイント ----------
@functions_framework.http
def ingestAnswer(request: Request):
    return _handle(request, "answer")


@functions_framework.http
def ingestShakyo(request: Request):
    return _handle(request, "shakyo")
