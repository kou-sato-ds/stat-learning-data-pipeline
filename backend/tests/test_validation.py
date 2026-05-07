"""ペイロードバリデーションのテスト"""

import pytest

from main import _validate_answer_payload, _validate_shakyo_payload


class TestAnswerPayload:
    def test_valid(self):
        p = {
            "question_id": "Q01",
            "topic_id": "T22",
            "is_correct": True,
            "time_sec": 45,
            "confidence": 4,
        }
        assert _validate_answer_payload(p) is None

    def test_missing_required(self):
        p = {"question_id": "Q01", "topic_id": "T22"}
        err = _validate_answer_payload(p)
        assert err is not None
        assert "missing field" in err

    @pytest.mark.parametrize("bad_time", [-1, 7201, 99999, 1.5, "30"])
    def test_invalid_time_sec(self, bad_time):
        p = {
            "question_id": "Q01",
            "topic_id": "T22",
            "is_correct": True,
            "time_sec": bad_time,
        }
        err = _validate_answer_payload(p)
        assert err is not None
        assert "time_sec" in err

    @pytest.mark.parametrize("bad_correct", [1, "true", 0, None])
    def test_invalid_is_correct(self, bad_correct):
        p = {
            "question_id": "Q01",
            "topic_id": "T22",
            "is_correct": bad_correct,
            "time_sec": 30,
        }
        err = _validate_answer_payload(p)
        assert err is not None
        assert "is_correct" in err

    @pytest.mark.parametrize("bad_conf", [0, 6, -1, 3.5, "5"])
    def test_invalid_confidence(self, bad_conf):
        p = {
            "question_id": "Q01",
            "topic_id": "T22",
            "is_correct": True,
            "time_sec": 30,
            "confidence": bad_conf,
        }
        err = _validate_answer_payload(p)
        assert err is not None
        assert "confidence" in err

    def test_confidence_optional(self):
        p = {
            "question_id": "Q01",
            "topic_id": "T22",
            "is_correct": True,
            "time_sec": 30,
        }
        assert _validate_answer_payload(p) is None

    @pytest.mark.parametrize("bad_topic", ["22", "X22", "", 22, "TT22"])
    def test_invalid_topic_id(self, bad_topic):
        p = {
            "question_id": "Q01",
            "topic_id": bad_topic,
            "is_correct": True,
            "time_sec": 30,
        }
        err = _validate_answer_payload(p)
        assert err is not None
        assert "topic_id" in err


class TestShakyoPayload:
    def test_valid(self):
        p = {
            "topic_id": "T22",
            "target_type": "formula",
            "target_ref": "F-22-CLT",
            "repetition_count": 3,
        }
        assert _validate_shakyo_payload(p) is None

    @pytest.mark.parametrize("ttype", ["formula", "code", "proof"])
    def test_target_type_allowed(self, ttype):
        p = {
            "topic_id": "T22",
            "target_type": ttype,
            "target_ref": "ref",
            "repetition_count": 1,
        }
        assert _validate_shakyo_payload(p) is None

    @pytest.mark.parametrize("ttype", ["other", "", "FORMULA", None])
    def test_target_type_disallowed(self, ttype):
        p = {
            "topic_id": "T22",
            "target_type": ttype,
            "target_ref": "ref",
            "repetition_count": 1,
        }
        err = _validate_shakyo_payload(p)
        assert err is not None
        assert "target_type" in err

    @pytest.mark.parametrize("rep", [0, -1, "3", 1.5])
    def test_invalid_repetition_count(self, rep):
        p = {
            "topic_id": "T22",
            "target_type": "code",
            "target_ref": "ref",
            "repetition_count": rep,
        }
        err = _validate_shakyo_payload(p)
        assert err is not None
        assert "repetition_count" in err
