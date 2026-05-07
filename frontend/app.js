/* ==========================================================
 * 統計検定2級 学習ログ LIFFアプリ
 * - LIFF初期化 + id_token取得
 * - 解答ログ/写経ログを Cloud Functions に送信
 * - オフライン時はlocalStorageキュー、復帰時に自動flush
 * ========================================================== */

// ===== 設定 (deploy時に置換される) =====
const LIFF_ID         = "__LIFF_ID__";
const ENDPOINT_ANSWER = "__ENDPOINT_ANSWER__";
const ENDPOINT_SHAKYO = "__ENDPOINT_SHAKYO__";

// 出題範囲表(dim_topicと同期。スキーマ更新時はSQL側と一緒に直す)
const TOPICS = [
  { id: "T03", label: "データの分布の記述" },
  { id: "T04", label: "代表値と散布度" },
  { id: "T05", label: "箱ひげ図" },
  { id: "T06", label: "散らばり(その他)" },
  { id: "T07", label: "中心と散らばりの活用" },
  { id: "T08", label: "散布図と相関" },
  { id: "T09", label: "カテゴリカルデータ" },
  { id: "T10", label: "単回帰と予測" },
  { id: "T11", label: "時系列" },
  { id: "T12", label: "観察研究と実験研究" },
  { id: "T13", label: "標本調査と無作為抽出" },
  { id: "T14", label: "実験" },
  { id: "T15", label: "確率" },
  { id: "T16", label: "確率変数(変数型)" },
  { id: "T17", label: "確率変数(基本)" },
  { id: "T18", label: "確率変数(応用)" },
  { id: "T19", label: "確率分布" },
  { id: "T20", label: "標本分布(基本)" },
  { id: "T21", label: "標本分布(応用)" },
  { id: "T22", label: "標本分布(正規母集団)" },
  { id: "T23", label: "推定(基本)" },
  { id: "T24", label: "推定(1つの母集団)" },
  { id: "T25", label: "推定(2つの母集団)" },
  { id: "T26", label: "仮説検定(基本)" },
  { id: "T27", label: "仮説検定(応用)" },
  { id: "T28", label: "仮説検定(1つの母集団)" },
  { id: "T29", label: "仮説検定(2つの母集団)" },
  { id: "T30", label: "仮説検定(適合度/独立性)" },
  { id: "T31", label: "回帰分析(基本)" },
  { id: "T32", label: "回帰分析(応用)" },
  { id: "T33", label: "実験計画" },
  { id: "T34", label: "統計ソフトウェアの活用" },
];

// ===== グローバル =====
const PENDING_KEY = "stats_liff_pending_v1";
const SESSION_KEY = "stats_liff_session_v1";
const TODAY_KEY   = "stats_liff_today_v1";
let idToken = null;
let timerStartedAt = null;

// ===== UIユーティリティ =====
const $ = (sel) => document.querySelector(sel);

function showError(msg) {
  const el = $("#error-banner");
  el.textContent = msg;
  el.classList.remove("hidden");
  setTimeout(() => el.classList.add("hidden"), 6000);
}

function showInfo(msg) {
  const el = $("#info-banner");
  el.textContent = msg;
  el.classList.remove("hidden");
  setTimeout(() => el.classList.add("hidden"), 4000);
}

function fillTopicSelects() {
  for (const sel of [$("#f-topic-id"), $("#s-topic-id")]) {
    sel.innerHTML = "";
    for (const t of TOPICS) {
      const opt = document.createElement("option");
      opt.value = t.id;
      opt.textContent = `${t.id}: ${t.label}`;
      sel.appendChild(opt);
    }
  }
}

function setupTabs() {
  document.querySelectorAll(".tab").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".tab").forEach((b) => b.classList.remove("active"));
      document.querySelectorAll(".tab-panel").forEach((p) => p.classList.remove("active"));
      btn.classList.add("active");
      $(`#tab-${btn.dataset.tab}`).classList.add("active");
    });
  });
}

// ===== セッション管理 =====
function getOrCreateSessionId() {
  let sid = sessionStorage.getItem(SESSION_KEY);
  if (!sid) {
    sid = crypto.randomUUID();
    sessionStorage.setItem(SESSION_KEY, sid);
  }
  return sid;
}

// ===== タイマー =====
function setupTimer() {
  $("#btn-start-timer").addEventListener("click", () => {
    timerStartedAt = performance.now();
    $("#timer-hint").textContent = "計測中... 解答後に「送信」で自動入力";
    $("#f-time-sec").value = "";
  });
  // 自信度スライダーの表示
  $("#f-confidence").addEventListener("input", (e) => {
    $("#f-confidence-display").textContent = e.target.value;
  });
}

function autoFillTimeSec() {
  if (timerStartedAt) {
    const sec = Math.round((performance.now() - timerStartedAt) / 1000);
    $("#f-time-sec").value = sec;
    timerStartedAt = null;
    $("#timer-hint").textContent = "";
    return sec;
  }
  return null;
}

// ===== ローカルキュー =====
function loadQueue() {
  try { return JSON.parse(localStorage.getItem(PENDING_KEY) || "[]"); }
  catch { return []; }
}
function saveQueue(q) {
  localStorage.setItem(PENDING_KEY, JSON.stringify(q));
  $("#queue-count").textContent = q.length;
}
function pushToQueue(endpoint, payload) {
  const q = loadQueue();
  q.push({ endpoint, payload, at: Date.now() });
  saveQueue(q);
}

async function flushQueue() {
  const q = loadQueue();
  if (q.length === 0) { showInfo("未送信なし"); return; }
  const remaining = [];
  for (const item of q) {
    try {
      await postWithAuth(item.endpoint, item.payload);
    } catch {
      remaining.push(item);
    }
  }
  saveQueue(remaining);
  if (remaining.length === 0) showInfo(`${q.length}件を送信しました`);
  else showError(`${remaining.length}件が未送信のままです`);
}

// ===== 通信 =====
async function postWithAuth(endpoint, payload) {
  const ctrl = new AbortController();
  const timeoutId = setTimeout(() => ctrl.abort(), 8000);
  try {
    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type":  "application/json",
        "Authorization": `Bearer ${idToken}`,
      },
      body: JSON.stringify(payload),
      signal: ctrl.signal,
    });
    clearTimeout(timeoutId);
    if (!res.ok) {
      const t = await res.text();
      throw new Error(`HTTP ${res.status}: ${t.slice(0, 200)}`);
    }
    return await res.json();
  } catch (e) {
    clearTimeout(timeoutId);
    throw e;
  }
}

// ===== 本日カウント =====
function bumpTodayCount() {
  const today = new Date().toISOString().slice(0, 10);
  const obj = JSON.parse(localStorage.getItem(TODAY_KEY) || "{}");
  if (obj.date !== today) { obj.date = today; obj.count = 0; }
  obj.count = (obj.count || 0) + 1;
  localStorage.setItem(TODAY_KEY, JSON.stringify(obj));
  $("#today-count").textContent = obj.count;
}
function refreshTodayCount() {
  const today = new Date().toISOString().slice(0, 10);
  const obj = JSON.parse(localStorage.getItem(TODAY_KEY) || "{}");
  $("#today-count").textContent = (obj.date === today ? obj.count : 0);
}

// ===== フォーム送信 =====
function setupForms() {
  $("#answer-form").addEventListener("submit", async (e) => {
    e.preventDefault();

    // タイマー値があれば自動反映
    if (!$("#f-time-sec").value) autoFillTimeSec();

    const correctRadio = document.querySelector('input[name="correct"]:checked');
    if (!correctRadio) { showError("正誤を選んでください"); return; }

    const payload = {
      answer_id:    crypto.randomUUID(),
      question_id:  $("#f-question-id").value.trim(),
      topic_id:     $("#f-topic-id").value,
      is_correct:   correctRadio.value === "true",
      time_sec:     parseInt($("#f-time-sec").value, 10),
      confidence:   parseInt($("#f-confidence").value, 10),
      device:       liff.isInClient() ? "line_inapp" : "external_browser",
      session_id:   getOrCreateSessionId(),
      answered_at:  new Date().toISOString(),
    };

    try {
      await postWithAuth(ENDPOINT_ANSWER, payload);
      showInfo("✅ 送信完了");
      bumpTodayCount();
      e.target.reset();
      $("#f-confidence-display").textContent = "3";
    } catch (err) {
      pushToQueue(ENDPOINT_ANSWER, payload);
      showError("通信不安定。端末に保存しました（オンライン復帰時に自動送信）");
    }
  });

  $("#shakyo-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const payload = {
      shakyo_id:        crypto.randomUUID(),
      topic_id:         $("#s-topic-id").value,
      target_type:      $("#s-target-type").value,
      target_ref:       $("#s-target-ref").value.trim(),
      repetition_count: parseInt($("#s-rep").value, 10),
      duration_sec:     $("#s-duration").value ? parseInt($("#s-duration").value, 10) : null,
      executed_at:      new Date().toISOString(),
    };
    try {
      await postWithAuth(ENDPOINT_SHAKYO, payload);
      showInfo("✅ 写経ログ送信完了");
      e.target.reset();
    } catch (err) {
      pushToQueue(ENDPOINT_SHAKYO, payload);
      showError("通信不安定。端末に保存しました");
    }
  });

  $("#btn-flush-queue").addEventListener("click", flushQueue);
}

// ===== オンライン復帰時に自動flush =====
window.addEventListener("online", () => {
  showInfo("オンライン復帰: 未送信を送信中...");
  flushQueue();
});

// ===== 初期化 =====
async function initializeApp() {
  fillTopicSelects();
  setupTabs();
  setupTimer();
  setupForms();
  refreshTodayCount();
  saveQueue(loadQueue());

  try {
    await liff.init({ liffId: LIFF_ID, withLoginOnExternalBrowser: true });

    if (!liff.isLoggedIn()) {
      liff.login();
      return;
    }

    idToken = liff.getIDToken();
    const profile = await liff.getProfile();
    $("#user-info").textContent = `${profile.displayName} さん`;

    // 環境判定: LINE内ブラウザなら計測UIをデフォルトactive、外部ブラウザは詳細入力フォームに留める
    if (liff.isInClient()) {
      $("#timer-hint").textContent = "(LINE内ブラウザ: ワンタップ計測が利用可能)";
    } else {
      $("#timer-hint").textContent = "(外部ブラウザ: 手入力もOK)";
    }
  } catch (err) {
    const code = err && err.code ? err.code : "UNKNOWN";
    const map = {
      INIT_FAILED:   "LIFF初期化失敗。LINEアプリを再起動してください。",
      FORBIDDEN:     "アクセス権限がありません。",
      NETWORK_ERROR: "通信失敗。電波の良い場所で再試行してください。",
    };
    showError(map[code] || `エラー: ${code} ${err && err.message ? err.message : ""}`);
  }
}

document.addEventListener("DOMContentLoaded", initializeApp);
