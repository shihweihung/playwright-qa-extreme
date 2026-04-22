# playwright-qa-extreme

> 企業級 QA 極限稽核技能 for Claude Code  
> AI-driven website QA: browser exploration → test specs → Playwright automation → HTML report

---

## 功能概覽

| Phase | 工具 | 做什麼 |
|-------|------|--------|
| Phase 0 探察 | Claude_in_Chrome | AI 直接瀏覽網站，看畫面理解結構，自動切分測試模組 |
| Phase 0-B 規格 | Claude | 產出完整中文測試規格文件（7 大維度） |
| Phase 0-C Pre-Auth | Playwright | 建立登入 session，供後續模組使用 |
| Phase 1 執行 | Playwright + Claude_in_Chrome | 逐條驗收；歧義畫面交由 AI 判斷 |
| Phase 2 稽查 | Claude_in_Chrome + Playwright | Console/Network 直讀 + 表單邊界攻擊 |
| Phase 3 HitL | 人工 | OTP / 金流 / CAPTCHA 中斷處理 |
| Phase 4 報告 | Claude + Node.js | UAT 清單 + Bug 報告 + **自包含 HTML 主整合報告** |

**核心特色：**
- 🤖 Phase 0 零腳本：AI 直接看網頁，不需手寫探察腳本
- 📊 HTML 報告可直接分享：截圖 base64 內嵌，單一檔案，無依賴
- 🛡️ Overlay 三步自救：公告彈窗自動關閉，不誤判為 P0
- 🚫 純稽核鎖：全程禁止修改任何網站程式碼

---

## 安裝需求

| 項目 | 版本 |
|------|------|
| [Claude Code](https://claude.ai/download) | 最新版 |
| [Node.js](https://nodejs.org/) | v18+ |
| Claude_in_Chrome MCP | 需在 Claude Code 中已啟用 |

> **Claude_in_Chrome** 是 Claude Code 的瀏覽器控制 MCP，提供 `navigate`、`find`、`computer`、`read_console_messages` 等工具。請確認你的 Claude Code 已連接此 MCP。

---

## 快速安裝

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/aster-life/playwright-qa-extreme/main/install.ps1 | iex
```

### macOS / Linux（bash）

```bash
curl -fsSL https://raw.githubusercontent.com/aster-life/playwright-qa-extreme/main/install.sh | bash
```

### 手動安裝

```bash
# 1. Clone 此 repo
git clone https://github.com/aster-life/playwright-qa-extreme.git

# 2. 複製技能到 Claude Code skills 資料夾
# Windows:
xcopy /E /I playwright-qa-extreme "%USERPROFILE%\.claude\skills\playwright-qa-extreme"

# macOS / Linux:
cp -r playwright-qa-extreme ~/.claude/skills/playwright-qa-extreme

# 3. 安裝 Playwright（供 Phase 1/2 腳本使用）
mkdir -p C:/tmp/pw-test   # Windows
npm install playwright --prefix C:/tmp/pw-test

# 4. 重新啟動 Claude Code
```

---

## 使用方式

在 Claude Code 中，把你要測試的專案資料夾加入 Workspace，然後輸入：

```
/qa-extreme-audit https://your-website.com
```

或：

```
QA 驗收模式：https://your-website.com
幫我測試這個網站：https://your-website.com
```

技能啟動後會自動：
1. 確認輸出路徑（`[Workspace]/qa-reports/`）
2. 開始 Phase 0 探察

---

## 輸出結構

```
[Workspace]/
└── qa-reports/
    ├── [PROJECT]-qa-report-[DATE].html   ← 主整合報告（可直接分享）
    ├── [MODULE]-uat-checklist.md         ← 各模組 UAT 打勾清單
    ├── [MODULE]-qa-bug-report.md         ← 各模組 Bug 報告
    ├── screenshots/                      ← 截圖（已內嵌進 HTML）
    └── specs/                            ← 測試規格文件
```

---

## 路徑初始化規則

技能啟動時自動偵測輸出路徑（優先序）：

1. **Claude Code Workspace 根目錄**（最高優先）— 你 Add 進來的專案資料夾
2. **用戶在訊息中明確指定路徑**（覆蓋）— 說「存到 D:\Projects\SiteB」
3. **詢問用戶**（備援）

> 所有截圖與報告都輸出到同一個路徑，確保 Google Drive / OneDrive 自動同步。

---

## 嚴重度定義

| 等級 | 標準 |
|------|------|
| 🔴 P0 阻塞 | 主流程完全無法執行，需立即修復 |
| 🟠 P1 高優先 | 核心功能受損，本週內修復 |
| 🟡 P2 中優先 | 非核心功能異常，下一 Sprint |
| 🟢 P3 低優先 | UX 摩擦力 / 有空再修 |

---

## 授權

MIT License — 自由使用、修改、分享

---

*Built by [Aster Wei](https://asterwei.life) · Powered by Claude Code + Playwright*
