---
name: playwright-qa-extreme
description: 企業級 QA 極限稽核技能。當使用者說「QA 驗收模式」、「幫我測試這個網站」、「/qa-extreme-audit」時啟動。核心流程：Claude_in_Chrome 真實瀏覽探察 → 切分模組 → 產出完整中文測試規格 → Playwright 逐條驗收 + Claude_in_Chrome 語意判斷 → Console/Network 直讀稽查 → HTML 主整合報告。嚴禁修改任何程式碼。
---

# Playwright QA 極限稽核技能

## 路徑初始化（每次啟動第一件事）

啟動技能後，**依以下優先序決定 QA_BASE**，之後所有文件、截圖、報告全部輸出到同一位置：

### 優先序（由高到低）

**① 用戶當前 Claude Code Workspace 根目錄（最高優先，自動偵測）**
- Claude Code 的 Workspace 就是用戶 Add 進來的專案資料夾
- 偵測方式：讀取當前 session 的 **working directory（cwd）**，即 Claude Code 開啟時的根目錄
- 這個路徑不需要用戶手動提供，直接使用即可
- 範例：用戶 Add 了 `...\TCGA` → cwd = `...\TCGA` → QA_BASE = `...\TCGA`

**② 用戶在訊息中明確指定路徑（覆蓋 workspace）**
- 用戶在指令裡直接說「輸出到 X 資料夾」
- 用該路徑覆蓋 workspace 偵測結果
- 範例：「存到 D:\Projects\SiteB」→ QA_BASE = `D:\Projects\SiteB`

**③ 兩者皆無（備援）**
- 詢問用戶：「請告訴我 QA 報告要存在哪個資料夾？」

### 確認輸出格式

確定 QA_BASE 後，**立即輸出確認訊息**（不可跳過，讓用戶可以在 Phase 0 第一步就確認路徑正確）：
```
📁 QA_BASE   = [實際路徑]  ← 來源：[Workspace cwd / 用戶指定 / 手動輸入]
📁 規格文件  → QA_BASE/qa-reports/specs/
📁 截圖      → QA_BASE/qa-reports/screenshots/
📁 報告      → QA_BASE/qa-reports/
📁 暫存腳本  → C:/tmp/（跑完不需保留）
```

若路徑有誤，用戶可在此立即糾正，後續所有輸出才正確落點。

> **絕對禁止使用相對路徑 `./qa-reports` 或 `C:/tmp/qa-reports` 作為最終輸出路徑。**
> 截圖與報告必須存在同一個 QA_BASE 下，確保 Google Drive 同步。

---

## 鐵則（啟動前必讀）

1. **無損迭代**：報告只能堆疊新增，禁止覆蓋舊區塊
2. **預設缺陷**：假設每個按鈕、欄位、流程都有問題
3. **裝置隔離**：強制桌機 (1920px) + 行動 (375px) 分離測試
4. **Overlay 三步自救**：遇到彈窗遮擋，先執行彈窗關閉協議，三步失敗才判 P0（詳見 Phase 1）
5. **純稽核鎖**：全程禁止修改任何程式碼
6. **500 錯誤不得忽視**：任何 500 均視為程式碼強健性缺陷
7. **路徑強制同步**：截圖與報告必須輸出到 QA_BASE（Google Drive），禁止存到 `C:/tmp/`

---

## 完整執行流程

```
Phase 0    → 🤖 Claude_in_Chrome 真實瀏覽探察，AI 自行判斷頁面結構與流程
Phase 0-B  → 產出各模組「完整中文測試規格文件」（等待用戶確認）
Phase 0-C  → Pre-Auth 前置認證（有需要登入的模組才執行）
Phase 1    → 混合執行：Playwright 腳本（確定性） + Claude_in_Chrome（歧義判斷）
Phase 2    → 🤖 Claude_in_Chrome 直讀 Console/Network + Playwright 邊界攻擊
Phase 3    → Mid-Flow 中斷（執行中遇到 OTP / 金流 / 圖形驗證碼）
Phase 4    → 三份報告（UAT 清單 + Bug 報告 + HTML 主整合報告）
```

**工具分工原則：**
- `Claude_in_Chrome` → 「看懂畫面、理解語意」的任務（探察、歧義判斷、console 稽查）
- `Playwright 腳本`  → 「確定性、可重複」的任務（逐條驗收、邊界攻擊、CI 回歸）

> **Phase 0-C 是 Phase 3 拆分後的前半段。**
> 凡是「需要登入才能測試」的模組，必須在 Phase 1 開始前先建立好 session，
> 而不是等到 Phase 1 撞牆後才中斷。

---

## Phase 0 — 網站探察與模組切分（Claude_in_Chrome）

> **工具：`mcp__Claude_in_Chrome__*`**
> Phase 0 完全用 Claude_in_Chrome 執行，AI 直接看畫面、理解結構，不寫探察腳本。

### 探察步驟

**Step 1：取得瀏覽器 tab**
```
→ 呼叫 tabs_context_mcp 取得可用 tab ID
→ 若無 tab，呼叫 tabs_create_mcp 建立新 tab
```

**Step 2：前台探察**
```
1. navigate(url=FRONT_URL, tabId)
2. computer(action="screenshot") → 看首頁全貌
3. read_page(filter="interactive") → 讀導覽列、選單結構
4. 逐一點擊主導覽項目（find("主導覽選單") → computer click）
5. 每個頁面：screenshot + read_page，記錄：
   - 頁面名稱、URL
   - 主要功能區塊
   - 是否需要登入才能看到內容
   - 是否有子頁面 / 子選單
6. 遇到彈窗 → find("關閉按鈕") → click → 繼續探察（不記錄為 Bug）
```

**Step 3：後台探察**
```
1. navigate(url=ADMIN_URL, tabId)
2. computer(action="screenshot") → 判斷是否需要登入
3. 若出現登入頁 → 立即觸發 HitL（見下方），等用戶登入完成
4. 登入後：read_page(filter="interactive") → 讀側邊欄選單
5. 逐一點擊後台選單項目，記錄：
   - 功能名稱、URL
   - CRUD 類型（列表 / 新增 / 編輯 / 刪除）
   - 特殊功能（上傳 / 審核 / 發布）
```

**後台需要登入時的 HitL 格式：**
```
🛑 [Phase 0 Human-in-the-Loop 請求]
停止原因：後台需要登入才能探察真實選單
目前網址：[ADMIN_URL]
截圖：[computer screenshot 已顯示登入頁]
需要您完成：在瀏覽器完成登入（含 CAPTCHA）
完成後請回覆「繼續」
```

> **絕對不可用前台內容「推導」後台結構。** 必須親眼看到後台選單才能切分模組。

### 探察過程中主動記錄

每個頁面探察後，AI 立即記錄：
```
頁面：[名稱]
URL：[實際 URL]
功能：[一句話描述]
需要登入：[是/否]
發現的問題（初步）：[有無破圖、明顯 layout 問題、404]
```

### 模組切分規則

- 前台前綴 `F`，後台前綴 `B`，整合層前綴 `E`
- 單一模組最多 5 頁，前台 + 後台最少切 6 個模組
- 後台每個 CRUD 功能獨立成模組
- 整合層 `E*` 必須等 `F*` 和 `B*` 完成後才執行
- **模組切分必須基於實際探察結果，嚴禁推導或假設**

**切分完成後列出清單，等待使用者「確認」再進入 Phase 0-B。**

---

## Phase 0-B — 產出完整中文測試規格文件

> **這是整個流程最核心的輸出。必須在執行任何 Playwright 之前完成。**

### 文件標準

每個模組產出一份獨立的 Markdown 測試規格文件，存放於：
```
[QA_BASE]/qa-reports/specs/[模組ID]-test-spec.md
```
> ✅ 使用 Write tool 寫入絕對路徑（不可用相對路徑）。

### 測試規格的覆蓋維度（缺任一維度即為不完整）

1. **正向主流程**：用戶完成核心任務的標準路徑
2. **替代流程**：達成同目標的不同路徑（如：不同登入方式）
3. **負向流程**：輸入錯誤、操作失敗的處理
4. **邊界測試**：空值、超長輸入、特殊字元、極限值
5. **權限驗證**：未登入/無權限時的存取行為
6. **狀態轉換**：操作後系統狀態是否正確切換
7. **跨裝置（RWD）**：行動版佈局與互動是否正確

### 測試規格文件格式（每個測試案例必須包含）

```markdown
# [模組ID] — [模組名稱] 測試規格文件
**版本：** v1.0  
**涵蓋維度：** 正向流程 / 負向流程 / 邊界測試 / 權限驗證 / RWD

---

## TC-[模組ID]-001 [測試案例名稱]

**維度：** [正向主流程 / 負向流程 / 邊界測試 / 權限驗證 / RWD]  
**前置條件：** [執行此測試前的系統狀態，如：未登入、已登入管理員帳號]  
**測試裝置：** [桌機 1920px / 行動 375px / 雙端]

### 測試步驟
1. [具體操作步驟，精確到點哪個按鈕、輸入什麼值]
2. ...

### 預期結果
- [系統應顯示什麼、跳轉到哪裡、有無提示訊息]

### 失敗定義
- [什麼樣的實際結果代表此案例測試失敗]

---
```

### 思考各種用戶流程的方法

產出測試規格前，AI 必須以「真實用戶視角」思考：

**一般用戶會怎麼走？**
- 第一次來的新用戶（不熟系統）
- 犯錯的用戶（填錯欄位、忘記密碼）
- 手滑的用戶（連點兩次、中途返回）
- 心急的用戶（表單還沒載入就送出）

**邊緣情況：**
- 網路很慢時（Loading 狀態）
- 帶著舊 session 回來（Token 過期）
- 從別的頁面直接跳進（深層連結）

**惡意/測試用戶：**
- 嘗試 SQL Injection、XSS
- 超長字串、特殊字元
- 跳過步驟直接訪問受保護頁面

**產出後展示給使用者確認，收到「確認」才進入 Phase 0-C。**

---

## Phase 0-C — Pre-Auth 前置認證（Phase 1 開跑前必做）

> **這個 Phase 是 Phase 3 的前半段，專門處理「需要登入才能跑的模組」。**
> 必須在 Phase 1 開始之前完成，否則需要登入的測試案例全部無法執行。

### 判斷是否需要執行 Phase 0-C

掃描所有模組的測試規格，檢查是否有以下前置條件：
- `前置條件：已登入會員`
- `前置條件：已登入管理員`
- `前置條件：具有 [角色] 權限`

若所有模組均為「未登入」前置條件 → **跳過 Phase 0-C，直接進 Phase 1**
若有任一模組需要登入 → **必須執行 Phase 0-C**

### 前置認證步驟

**Step 1：列出需要的 session 類型**
```
📋 以下模組需要登入 session，Phase 1 前必須建立：
  - 會員 session：F3（會員認證）、F4（會員中心）、F5（報名購買）
  - 管理員 session：B1 ~ B6（所有後台模組）
```

**Step 2：觸發 Human-in-the-Loop，請用戶完成登入**

```
🛑 [Phase 0-C Pre-Auth 請求]
原因：以下測試模組需要登入 session 才能執行
需要您完成：
  1. 會員登入 → 開啟 [前台登入 URL]，完成登入（若有 CAPTCHA 請手動輸入）
  2. 管理員登入 → 開啟 [後台登入 URL]，完成登入（CAPTCHA 請手動輸入）
Session 將儲存至：
  - 會員：C:/tmp/pw-profile/[site]-member
  - 管理員：C:/tmp/pw-profile/[site]-admin
完成後請回覆「繼續」
```

**Step 3：驗證 session 有效**
```js
// 驗證會員 session
const memberCtx = await chromium.launchPersistentContext('C:/tmp/pw-profile/[site]-member', { headless: true });
const memberPage = memberCtx.pages()[0] || await memberCtx.newPage();
await memberPage.goto(MEMBER_URL, { waitUntil: 'networkidle' });
if (memberPage.url().includes('/login')) {
  // session 無效 → 再次觸發 HitL
}
console.log('✅ 會員 session 有效：', memberPage.url());
await memberCtx.close();
```

**Step 4：確認後輸出**
```
✅ Phase 0-C 完成
  會員 session：有效（profile: C:/tmp/pw-profile/[site]-member）
  管理員 session：有效（profile: C:/tmp/pw-profile/[site]-admin）
→ 準備進入 Phase 1，回覆「繼續」啟動
```

### Phase 0-C 的 Human-in-the-Loop 執行方式

使用 `launchPersistentContext` + `headless: false`，讓用戶在瀏覽器視窗完成登入：

```js
const { chromium } = require('C:/tmp/pw-test/node_modules/playwright');

async function setupMemberSession(loginUrl, profilePath, account, password) {
  const context = await chromium.launchPersistentContext(profilePath, {
    headless: false,
    args: ['--start-maximized', '--disable-blink-features=AutomationControlled'],
  });
  const page = context.pages()[0] || await context.newPage();
  await page.goto(loginUrl, { waitUntil: 'networkidle' });

  // 嘗試自動填入（若有 CAPTCHA 則讓用戶手動完成）
  const emailInput = await page.$('input[type="email"], input[name="email"], input[name="account"]');
  const pwInput    = await page.$('input[type="password"]');
  if (emailInput) await emailInput.fill(account);
  if (pwInput)    await pwInput.fill(password);

  // Polling：等用戶手動輸入 CAPTCHA 並送出
  console.log('⏳ 若有 CAPTCHA，請在瀏覽器手動輸入後按登入...');
  while (page.url().includes('/login') || page.url().includes('/captcha')) {
    await page.waitForTimeout(2000);
  }
  console.log('✅ 登入成功，session 已儲存');
  await context.close();
}
```

---

## Phase 1 — Playwright 自動化執行

依照 Phase 0-B 的測試規格，逐條用 Playwright 執行。

### 執行腳本基礎結構

> ⚠️ `QA_BASE` 必須替換為實際 Google Drive 路徑（從路徑初始化步驟取得）。
> 暫存腳本本身寫到 `C:/tmp/pw_[模組ID]_test.js`，但所有輸出存到 `QA_BASE`。

```js
const { chromium } = require('C:/tmp/pw-test/node_modules/playwright');
const fs = require('fs');
const path = require('path');

// ✅ 正確：絕對路徑，指向 Google Drive 同步資料夾
// QA_BASE 由路徑初始化優先序決定：
//   ① 用戶明確提供 → 直接用（最高優先）
//   ② CLAUDE.md 所在目錄 → 次要
//   ③ 手動詢問 → 備援
// 範例：
// const QA_BASE = 'C:/Users/trist/我的雲端硬碟 (tristan416@gmail.com)/Claude-Work/Cowork Station/TCGA';
const QA_BASE = '[路徑初始化步驟取得的 QA_BASE]';
const REPORT_DIR = path.join(QA_BASE, 'qa-reports');
const SPEC_DIR   = path.join(REPORT_DIR, 'specs');
const SS_DIR     = path.join(REPORT_DIR, 'screenshots');

// 一次性建立所有目錄
[REPORT_DIR, SPEC_DIR, SS_DIR].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

// 監聽 Console 錯誤 + 網路失敗
const consoleErrors = [];
const networkFails = [];

async function setupMonitors(page) {
  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', err => consoleErrors.push(err.message));
  page.on('response', res => {
    if (res.status() >= 400) networkFails.push(`${res.status()} ${res.url()}`);
  });
}

// 截圖命名規則：[模組ID]-[案例ID]-[步驟]-[pass|fail]-[desktop|mobile].png
async function shot(page, name) {
  const file = path.join(SS_DIR, `${name}.png`);
  await page.screenshot({ path: file, fullPage: true });
  return file;
}

// 桌機端測試
async function runDesktop(page, testFn, testId) {
  await page.setViewportSize({ width: 1920, height: 1080 });
  return testFn(page, testId + '-desktop');
}

// 行動端測試（RWD 防誤報四步驟）
async function runMobile(page, url, testFn, testId) {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto(url, { waitUntil: 'networkidle' }); // 必須重新導覽
  await page.waitForTimeout(1500);                     // 等待 CSS Reflow
  return testFn(page, testId + '-mobile');
}

// ── 彈窗關閉協議（Overlay Dismissal Protocol）────────────
// 偵測到 overlay/dialog 擋住目標元素時，必須先跑此函式，
// 不可直接判 P0。根據回傳值決定嚴重度。
//
// 回傳值：
//   'dismissed' → 找到關閉按鈕並成功點擊 → 降級為 P3 或不算 Bug
//   'escaped'   → Escape 有效關閉 → 降級為 P3
//   'failed'    → 真的關不掉 → 才升為 P0
//
async function tryDismissOverlay(page, testId) {
  // Step 1：嘗試常見關閉按鈕文字
  const dismissTexts = ['我知道了', '知道了', '關閉', '確認', '同意', 'OK', 'Close', '×', 'X'];
  for (const text of dismissTexts) {
    try {
      const btn = page.locator('button, [role="button"], [role="dialog"] a')
                      .filter({ hasText: new RegExp(text, 'i') });
      if (await btn.count() > 0 && await btn.first().isVisible({ timeout: 500 })) {
        await btn.first().click();
        await page.waitForTimeout(600);
        const overlayStillOpen = await page.$('[data-slot="dialog-overlay"][data-state="open"], [role="dialog"][aria-modal="true"]');
        if (!overlayStillOpen) {
          await shot(page, `${testId}-overlay-dismissed`);
          return 'dismissed';
        }
      }
    } catch (_) {}
  }

  // Step 2：嘗試 Escape
  await page.keyboard.press('Escape');
  await page.waitForTimeout(400);
  const stillOpenAfterEsc = await page.$('[data-slot="dialog-overlay"][data-state="open"], [role="dialog"][aria-modal="true"]');
  if (!stillOpenAfterEsc) {
    await shot(page, `${testId}-overlay-escaped`);
    return 'escaped';
  }

  // Step 3：點擊 overlay 背景
  try {
    const overlay = page.locator('[data-slot="dialog-overlay"]').first();
    if (await overlay.isVisible({ timeout: 500 })) {
      await overlay.click({ position: { x: 10, y: 10 }, force: true });
      await page.waitForTimeout(400);
      const stillOpen = await page.$('[data-slot="dialog-overlay"][data-state="open"]');
      if (!stillOpen) {
        await shot(page, `${testId}-overlay-bg-clicked`);
        return 'dismissed';
      }
    }
  } catch (_) {}

  // 三步都失敗 → 真的關不掉
  await shot(page, `${testId}-overlay-stuck-P0`);
  return 'failed';
}

// 使用範例：
// const overlayResult = await tryDismissOverlay(page, testId);
// if (overlayResult === 'failed') {
//   results.push({ id: testId, status: 'FAIL', severity: 'P0', note: 'Overlay 無法關閉，目標元素被永久遮擋' });
// } else {
//   results.push({ id: testId, status: 'WARN', severity: 'P3',
//     note: `Overlay 可關閉（${overlayResult}），屬首次載入公告彈窗，非阻塞性問題` });
// }
```

### Overlay 遮擋判斷規則（禁止直接判 P0）

遇到 overlay / dialog / modal 擋住目標元素時，**強制執行以下三步流程**，不可跳過：

```
Step 1 → 呼叫 tryDismissOverlay(page, testId)
Step 2 → 根據回傳值決定後續：
          ┌─────────────┬────────────────────────────────────────────────────┐
          │ 'dismissed' │ overlay 成功關閉 → 重測目標元素                    │
          │             │   重測通過 → WARN / P3（首次公告彈窗，可接受）      │
          │             │   重測失敗 → FAIL / P1（關閉後仍有問題）            │
          ├─────────────┼────────────────────────────────────────────────────┤
          │ 'escaped'   │ 同上，Escape 可關閉 → WARN / P3                    │
          ├─────────────┼────────────────────────────────────────────────────┤
          │ 'failed'    │ 真的關不掉 → FAIL / P0（阻塞性問題）               │
          └─────────────┴────────────────────────────────────────────────────┘
Step 3 → 若 'failed'，截圖後觸發 HitL 讓用戶確認是否真的是 Bug：
          「偵測到 overlay 無法自動關閉，截圖已存至 [路徑]。
            請確認：A) 正常設計（標記 P3）  B) 真實 Bug（標記 P0）」
```

> **設計理由：** 腳本無法理解畫面語意。公告彈窗、Cookie 同意、活動提醒等「可關閉的 overlay」不應被誤判為 P0。只有真正無法關閉、永久遮擋操作流程的情況才是 P0。

---

### 測試結果記錄格式

```js
const results = [];
results.push({
  id: 'TC-F1-001',
  name: '首頁正常載入',
  status: 'PASS' | 'FAIL',
  screenshot: 'screenshots/f1-tc001-desktop.png',
  consoleErrors: [],
  networkFails: [],
  note: '說明'
});
```

---

## Phase 2 — 破壞式邊界稽查（混合執行）

> **工具分工：**
> - Console / Network 稽查 → `Claude_in_Chrome`（直讀，不需掛 listener）
> - 表單邊界攻擊 → `Playwright 腳本`（確定性輸入，可重複）

---

### 2-A Console & Network 稽查（Claude_in_Chrome）

每個關鍵頁面**逐一執行**：

```
1. navigate(url=PAGE_URL, tabId)         ← 導覽到目標頁面
2. 等待 2 秒（頁面完全載入）
3. read_console_messages(tabId)          ← 直讀 JS console
4. read_network_requests(tabId)          ← 直讀所有網路請求
5. 分析結果：
   - console error → 記錄，依嚴重度分類
   - HTTP 4xx / 5xx → 記錄 URL + 狀態碼
   - 特別標注：404 圖片、500 API、CORS error
```

**需稽查的頁面清單（Phase 1 跑完後確認）：**
- 所有主要前台頁面（至少 8 頁）
- 所有後台主功能頁面
- 404 錯誤頁面本身

**結果格式：**
```
頁面：[URL]
Console Errors：[有 / 無，若有列出內容]
Network Fails：[有 / 無，若有列出 status + url]
判定：PASS / FAIL + 說明
```

---

### 2-B 表單邊界攻擊（Playwright 腳本）

每個有表單的頁面，用 Playwright 執行標準攻擊組合：

```js
// 1. 空白送出
await page.fill('input', '');
await page.click('[type="submit"]');
await shot(page, `${id}-empty-submit`);

// 2. XSS 測試
await page.fill('input', '<script>alert(1)</script>');
await shot(page, `${id}-xss`);

// 3. 超長字串（500字）
await page.fill('input', 'A'.repeat(500));
await shot(page, `${id}-overflow`);

// 4. 錯誤格式（Email 欄位）
await page.fill('input[type="email"]', 'not-an-email');
await page.click('[type="submit"]');
await shot(page, `${id}-bad-email`);
```

**判定標準：**
- XSS：alert 未彈出 → PASS
- 空白送出：無 500，頁面穩定 → PASS
- 超長輸入：無 crash，無 500 → PASS

---

### 2-C 500 錯誤雙重探測（Playwright 腳本）

```js
// Probe A：全新無 Session（模擬未登入用戶）
const fresh = await chromium.launch({ headless: true });
const freshPage = await fresh.newPage();
const res = await freshPage.goto(URL);
console.log('Probe A status:', res.status());
await fresh.close();

// Probe B：現有 Session 重整（模擬登入用戶重整）
await page.reload({ waitUntil: 'networkidle' });
// 配合 2-A 的 read_network_requests 檢查是否出現 5xx
```

---

## Phase 3 — Mid-Flow 中斷（執行中途遇到人工牆）

> **Phase 3 只處理「Phase 1/2 跑到一半才碰到」的中斷情況。**
> 「需要登入才能跑的模組」應在 Phase 0-C 就處理，不應等到這裡。

### 觸發條件（執行途中才會出現）

| 情況 | 說明 |
|------|------|
| 手機 OTP / 簡訊驗證碼 | 測試「忘記密碼」或「新裝置登入」流程時 |
| 金流付款頁面 | 測試結帳流程時遇到實際付款閘道 |
| 圖形 CAPTCHA（mid-flow） | 某些操作（如高頻搜尋）觸發的防機器人 |
| 需收實際 Email | 測試「Email 驗證」等需要收信的流程 |

### 中斷格式

```
🛑 [Phase 3 Mid-Flow 中斷]
目前網址：[URL]
停止原因：[具體說明，如：送出報名表後出現簡訊 OTP 頁面]
需要您完成：[操作描述]
截圖：[QA_BASE]/qa-reports/screenshots/[截圖檔名].png
完成後請回覆「繼續」
```

### 注意事項

- 中斷後當前測試案例記錄為 `SKIP`（非 FAIL），附上中斷原因
- 繼續後從下一個測試案例接著跑
- 金流 / OTP 絕對不模擬，必須人工完成或標記為「需手動驗證」

---

## Phase 4 — 三份報告輸出

### 4-A 單模組報告（每個模組跑完後立即產出）

**1. `[模組ID]-uat-checklist.md`**
將 Phase 0-B 的測試規格逐條打勾：
- 通過：`[x] TC-F1-001 首頁正常載入`
- 失敗：`[ ] TC-F1-002 導覽列連結 (👉 BUG-F1-001)`

**2. `[模組ID]-qa-bug-report.md`**
5 大區塊：Post-Mortem / P0 阻塞 / P1 高優先 / P2 中優先 / 優先修復矩陣

**單模組結案格式：**
```
✅ [模組 ID] 測試完成
📄 UAT 清單：[QA_BASE]/qa-reports/[模組ID]-uat-checklist.md
📄 Bug 報告：[QA_BASE]/qa-reports/[模組ID]-qa-bug-report.md
進度：X / Y 模組 ── 下一個：[模組 ID]，回覆「繼續」啟動
```

---

### 4-B 主整合報告（所有模組全部完成後產出）

**命名規則：** `[workspace根目錄名]-qa-report-[YYYYMMDD].html`
- 範例：`TCGA-qa-report-20260422.html`
- 存放位置：`[QA_BASE]/qa-reports/`
- 格式：**單一自包含 HTML**（截圖 base64 內嵌、CSS inline，無外部依賴）

**用以下 Node.js 腳本產生（存為 `C:/tmp/pw_generate_report.js` 後執行）：**

```js
const { chromium } = require('C:/tmp/pw-test/node_modules/playwright');
const fs   = require('fs');
const path = require('path');

// ── 設定區 ──────────────────────────────────────────────
const QA_BASE      = '[路徑初始化取得的 QA_BASE]';
const REPORT_DIR   = path.join(QA_BASE, 'qa-reports');
const SS_DIR       = path.join(REPORT_DIR, 'screenshots');
const PROJECT_NAME = path.basename(QA_BASE);           // e.g. "TCGA"
const TODAY        = new Date().toISOString().slice(0,10).replace(/-/g,''); // "20260422"
const OUT_HTML     = path.join(REPORT_DIR, `${PROJECT_NAME}-qa-report-${TODAY}.html`);

// ── 讀取所有 Bug 報告資料（由 AI 在腳本執行前填入） ──
const BUGS = [
  // 格式：{ id, title, severity, page, desc, expected, actual, screenshot }
  // severity: 'P0'|'P1'|'P2'|'P3'
  // screenshot: 檔名（不含路徑），留空則不顯示
];

// ── 讀取各模組 UAT 彙總（由 AI 填入） ──
const MODULES = [
  // 格式：{ id, name, total, pass, fail }
];

// ── 讀取 Phase 2 安全性結果（由 AI 填入） ──
const SECURITY = [
  // 格式：{ item, result, note }
  // result: 'PASS'|'FAIL'
];

// ── 截圖轉 base64 ────────────────────────────────────────
function imgBase64(filename) {
  if (!filename) return '';
  const fp = path.join(SS_DIR, filename);
  if (!fs.existsSync(fp)) return '';
  return 'data:image/png;base64,' + fs.readFileSync(fp).toString('base64');
}

// ── 嚴重度顏色 ───────────────────────────────────────────
const SEV_COLOR = { P0:'#dc2626', P1:'#ea580c', P2:'#ca8a04', P3:'#16a34a' };
const SEV_LABEL = { P0:'🔴 P0 阻塞', P1:'🟠 P1 高優先', P2:'🟡 P2 中優先', P3:'🟢 P3 低優先' };

// ── HTML 產生 ─────────────────────────────────────────────
function generateHTML() {
  const totalTC   = MODULES.reduce((s,m) => s + m.total, 0);
  const totalPass = MODULES.reduce((s,m) => s + m.pass,  0);
  const totalFail = MODULES.reduce((s,m) => s + m.fail,  0);
  const p0 = BUGS.filter(b=>b.severity==='P0').length;
  const p1 = BUGS.filter(b=>b.severity==='P1').length;
  const p2 = BUGS.filter(b=>b.severity==='P2').length;
  const p3 = BUGS.filter(b=>b.severity==='P3').length;

  const bugSections = ['P0','P1','P2','P3'].map(sev => {
    const list = BUGS.filter(b=>b.severity===sev);
    if (!list.length) return '';
    return `
    <section style="margin-bottom:2rem">
      <h2 style="color:${SEV_COLOR[sev]};font-size:1.2rem;font-weight:700;border-bottom:2px solid ${SEV_COLOR[sev]};padding-bottom:.4rem">${SEV_LABEL[sev]}（${list.length} 項）</h2>
      ${list.map(bug => {
        const img = imgBase64(bug.screenshot);
        return `
        <details style="margin:.8rem 0;border:1px solid #e5e7eb;border-radius:.5rem;overflow:hidden">
          <summary style="padding:.75rem 1rem;background:#f9fafb;cursor:pointer;font-weight:600">
            <span style="background:${SEV_COLOR[bug.severity]};color:#fff;padding:.1rem .5rem;border-radius:.25rem;font-size:.75rem;margin-right:.5rem">${bug.severity}</span>
            ${bug.id} — ${bug.title}
          </summary>
          <div style="padding:1rem;font-size:.9rem;line-height:1.7">
            <p><strong>頁面：</strong>${bug.page}</p>
            <p><strong>描述：</strong>${bug.desc}</p>
            <p><strong>預期行為：</strong>${bug.expected}</p>
            <p><strong>實際行為：</strong>${bug.actual}</p>
            ${img ? `<img src="${img}" style="max-width:100%;border:1px solid #e5e7eb;border-radius:.375rem;margin-top:.75rem" loading="lazy">` : ''}
          </div>
        </details>`;
      }).join('')}
    </section>`;
  }).join('');

  const moduleRows = MODULES.map(m => `
    <tr>
      <td style="padding:.5rem .75rem;font-weight:600">${m.id}</td>
      <td style="padding:.5rem .75rem">${m.name}</td>
      <td style="padding:.5rem .75rem;text-align:center">${m.total}</td>
      <td style="padding:.5rem .75rem;text-align:center;color:#16a34a;font-weight:700">${m.pass}</td>
      <td style="padding:.5rem .75rem;text-align:center;color:#dc2626;font-weight:700">${m.fail}</td>
      <td style="padding:.5rem .75rem;text-align:center">
        <div style="background:#e5e7eb;border-radius:999px;height:8px;width:80px;display:inline-block;vertical-align:middle">
          <div style="background:#16a34a;border-radius:999px;height:8px;width:${Math.round(m.pass/m.total*80)}px"></div>
        </div>
        <span style="margin-left:.4rem;font-size:.8rem">${Math.round(m.pass/m.total*100)}%</span>
      </td>
    </tr>`).join('');

  const securityRows = SECURITY.map(s => `
    <tr>
      <td style="padding:.5rem .75rem">${s.item}</td>
      <td style="padding:.5rem .75rem;text-align:center;font-weight:700;color:${s.result==='PASS'?'#16a34a':'#dc2626'}">${s.result==='PASS'?'✅ PASS':'❌ FAIL'}</td>
      <td style="padding:.5rem .75rem;font-size:.85rem;color:#6b7280">${s.note||''}</td>
    </tr>`).join('');

  return `<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${PROJECT_NAME} QA 驗收報告 ${TODAY}</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#111827;background:#f3f4f6;padding:2rem}
  .card{background:#fff;border-radius:.75rem;box-shadow:0 1px 3px rgba(0,0,0,.1);padding:1.5rem;margin-bottom:1.5rem}
  table{width:100%;border-collapse:collapse}
  thead tr{background:#f9fafb}
  th{padding:.5rem .75rem;text-align:left;font-size:.8rem;color:#6b7280;text-transform:uppercase;letter-spacing:.05em}
  tbody tr:nth-child(even){background:#f9fafb}
  details summary::-webkit-details-marker{display:none}
</style>
</head>
<body>
<div style="max-width:960px;margin:0 auto">

  <!-- Header -->
  <div class="card" style="background:linear-gradient(135deg,#1e3a5f,#2563eb);color:#fff">
    <h1 style="font-size:1.75rem;font-weight:800;margin-bottom:.25rem">${PROJECT_NAME} QA 驗收報告</h1>
    <p style="opacity:.85;font-size:.9rem">測試日期：${TODAY.slice(0,4)}-${TODAY.slice(4,6)}-${TODAY.slice(6,8)} ｜ Playwright v1.56.0 ｜ 桌機 1920px + 行動 375px</p>
  </div>

  <!-- 總覽儀表板 -->
  <div class="card">
    <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:1rem">📊 測試總覽</h2>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:1rem;text-align:center">
      <div style="padding:1rem;background:#f0f9ff;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#0369a1">${totalTC}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">測試案例</div>
      </div>
      <div style="padding:1rem;background:#f0fdf4;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#16a34a">${totalPass}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">PASS</div>
      </div>
      <div style="padding:1rem;background:#fef2f2;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#dc2626">${totalFail}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">FAIL</div>
      </div>
      <div style="padding:1rem;background:#fef2f2;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#dc2626">${p0}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">P0 阻塞</div>
      </div>
      <div style="padding:1rem;background:#fff7ed;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#ea580c">${p1}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">P1 高優先</div>
      </div>
      <div style="padding:1rem;background:#fefce8;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#ca8a04">${p2}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">P2 中優先</div>
      </div>
      <div style="padding:1rem;background:#f0fdf4;border-radius:.5rem">
        <div style="font-size:2rem;font-weight:800;color:#16a34a">${p3}</div>
        <div style="font-size:.8rem;color:#6b7280;margin-top:.2rem">P3 低優先</div>
      </div>
    </div>
  </div>

  <!-- Bug 清單 -->
  <div class="card">
    <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:1rem">🐛 Bug 清單</h2>
    ${bugSections || '<p style="color:#6b7280">無 Bug 發現</p>'}
  </div>

  <!-- 模組 UAT 結果 -->
  <div class="card">
    <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:1rem">📋 各模組 UAT 結果</h2>
    <table>
      <thead><tr><th>模組</th><th>名稱</th><th>總計</th><th>PASS</th><th>FAIL</th><th>通過率</th></tr></thead>
      <tbody>${moduleRows}</tbody>
    </table>
  </div>

  <!-- 安全性稽查 -->
  <div class="card">
    <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:1rem">🛡️ 安全性稽查（Phase 2）</h2>
    <table>
      <thead><tr><th>測試項目</th><th>結果</th><th>說明</th></tr></thead>
      <tbody>${securityRows}</tbody>
    </table>
  </div>

  <p style="text-align:center;color:#9ca3af;font-size:.8rem;margin-top:1rem">
    Generated by playwright-qa-extreme skill ｜ ${new Date().toLocaleString('zh-TW')}
  </p>
</div>
</body>
</html>`;
}

fs.writeFileSync(OUT_HTML, generateHTML(), 'utf8');
console.log('✅ HTML 報告已產生：' + OUT_HTML);
```

> **使用說明：**
> 1. AI 在執行腳本前，先根據所有 `*-qa-bug-report.md` 和 `*-uat-checklist.md` 填入 `BUGS`、`MODULES`、`SECURITY` 三個陣列
> 2. `screenshot` 欄位填截圖檔名（如 `F1-TC013-overlay-blocks-mobile.png`），腳本自動讀取並轉 base64 內嵌
> 3. 執行後產出 `[QA_BASE]/qa-reports/[PROJECT_NAME]-qa-report-[YYYYMMDD].html`
> 4. 直接用瀏覽器開啟，或丟給任何人，無需網路、無需伺服器

**最終結案格式（所有模組完成後）：**
```
🎉 全站 QA 完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 總計：[X] TC ｜ [X] PASS ｜ [X] FAIL
🔴 P0: [X]  🟠 P1: [X]  🟡 P2: [X]  🟢 P3: [X]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 主整合報告（HTML）：
   [QA_BASE]/qa-reports/[PROJECT]-qa-report-[DATE].html
📁 各模組 UAT 清單 + Bug 報告：
   [QA_BASE]/qa-reports/
📸 截圖（[X] 張）：
   [QA_BASE]/qa-reports/screenshots/
```

> ✅ 所有檔案用 **Write tool 寫到絕對路徑（QA_BASE）**，Google Drive 自動同步。

---

## 啟動指令

```
「/qa-extreme-audit [URL]」
「QA 驗收模式：[URL]」
「幫我測試這個網站：[URL]」
```

啟動後從 Phase 0 開始，依序執行，不跳步驟。
