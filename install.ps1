# playwright-qa-extreme — Windows 一鍵安裝腳本
# 用法：irm https://raw.githubusercontent.com/aster-life/playwright-qa-extreme/main/install.ps1 | iex

$ErrorActionPreference = "Stop"
$SKILL_NAME = "playwright-qa-extreme"
$REPO_URL   = "https://github.com/aster-life/playwright-qa-extreme"
$SKILLS_DIR = "$env:USERPROFILE\.claude\skills"
$DEST       = "$SKILLS_DIR\$SKILL_NAME"
$TMP        = "$env:TEMP\$SKILL_NAME-install"

Write-Host ""
Write-Host "🎭 playwright-qa-extreme 安裝程式" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Step 1：確認 Claude Code skills 資料夾存在
if (-not (Test-Path $SKILLS_DIR)) {
    New-Item -ItemType Directory -Path $SKILLS_DIR -Force | Out-Null
    Write-Host "✅ 建立 skills 資料夾：$SKILLS_DIR" -ForegroundColor Green
}

# Step 2：下載技能
Write-Host "📥 下載技能中..." -ForegroundColor Yellow
if (Test-Path $TMP) { Remove-Item $TMP -Recurse -Force }
New-Item -ItemType Directory -Path $TMP -Force | Out-Null

$ZIP_URL = "$REPO_URL/archive/refs/heads/main.zip"
$ZIP_PATH = "$TMP\skill.zip"
Invoke-WebRequest -Uri $ZIP_URL -OutFile $ZIP_PATH -UseBasicParsing
Expand-Archive -Path $ZIP_PATH -DestinationPath $TMP -Force

# Step 3：複製到 skills 資料夾
if (Test-Path $DEST) {
    Write-Host "⚠️  已存在舊版本，覆蓋更新中..." -ForegroundColor Yellow
    Remove-Item $DEST -Recurse -Force
}
$EXTRACTED = Get-ChildItem "$TMP" -Directory | Where-Object { $_.Name -like "$SKILL_NAME*" } | Select-Object -First 1
Copy-Item -Path $EXTRACTED.FullName -Destination $DEST -Recurse
Write-Host "✅ 技能已安裝至：$DEST" -ForegroundColor Green

# Step 4：安裝 Playwright（若尚未安裝）
Write-Host ""
Write-Host "🎭 檢查 Playwright 安裝狀態..." -ForegroundColor Yellow
$PW_DIR = "C:\tmp\pw-test"
if (-not (Test-Path "$PW_DIR\node_modules\playwright")) {
    Write-Host "📦 安裝 Playwright 至 $PW_DIR ..." -ForegroundColor Yellow
    if (-not (Test-Path $PW_DIR)) { New-Item -ItemType Directory -Path $PW_DIR -Force | Out-Null }
    Push-Location $PW_DIR
    npm install playwright --save 2>&1 | Out-Null
    node -e "require('./node_modules/playwright')" 2>&1 | Out-Null
    Pop-Location
    Write-Host "✅ Playwright 安裝完成" -ForegroundColor Green
} else {
    Write-Host "✅ Playwright 已存在，跳過" -ForegroundColor Green
}

# Step 5：清理暫存
Remove-Item $TMP -Recurse -Force

# 完成
Write-Host ""
Write-Host "🎉 安裝完成！" -ForegroundColor Cyan
Write-Host ""
Write-Host "使用方式：" -ForegroundColor White
Write-Host "  1. 重新啟動 Claude Code" -ForegroundColor Gray
Write-Host "  2. 把你的專案資料夾加入 Workspace" -ForegroundColor Gray
Write-Host "  3. 輸入：/qa-extreme-audit https://your-site.com" -ForegroundColor Gray
Write-Host ""
