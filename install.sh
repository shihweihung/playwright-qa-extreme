#!/usr/bin/env bash
# playwright-qa-extreme — macOS/Linux 一鍵安裝腳本
# 用法：curl -fsSL https://raw.githubusercontent.com/aster-life/playwright-qa-extreme/main/install.sh | bash

set -e

SKILL_NAME="playwright-qa-extreme"
REPO_URL="https://github.com/aster-life/playwright-qa-extreme"
SKILLS_DIR="$HOME/.claude/skills"
DEST="$SKILLS_DIR/$SKILL_NAME"
TMP=$(mktemp -d)

echo ""
echo "🎭 playwright-qa-extreme 安裝程式"
echo "====================================="
echo ""

# Step 1：確認 skills 資料夾
mkdir -p "$SKILLS_DIR"

# Step 2：下載技能
echo "📥 下載技能中..."
ZIP_URL="$REPO_URL/archive/refs/heads/main.zip"
curl -fsSL "$ZIP_URL" -o "$TMP/skill.zip"
unzip -q "$TMP/skill.zip" -d "$TMP"

# Step 3：複製到 skills 資料夾
if [ -d "$DEST" ]; then
  echo "⚠️  已存在舊版本，覆蓋更新中..."
  rm -rf "$DEST"
fi
EXTRACTED=$(find "$TMP" -maxdepth 1 -type d -name "${SKILL_NAME}*" | head -1)
cp -r "$EXTRACTED" "$DEST"
echo "✅ 技能已安裝至：$DEST"

# Step 4：安裝 Playwright
echo ""
echo "🎭 檢查 Playwright 安裝狀態..."
PW_DIR="/tmp/pw-test"
if [ ! -d "$PW_DIR/node_modules/playwright" ]; then
  echo "📦 安裝 Playwright 至 $PW_DIR ..."
  mkdir -p "$PW_DIR"
  cd "$PW_DIR"
  npm install playwright --save --silent
  echo "✅ Playwright 安裝完成"
else
  echo "✅ Playwright 已存在，跳過"
fi

# Step 5：清理暫存
rm -rf "$TMP"

echo ""
echo "🎉 安裝完成！"
echo ""
echo "使用方式："
echo "  1. 重新啟動 Claude Code"
echo "  2. 把你的專案資料夾加入 Workspace"
echo "  3. 輸入：/qa-extreme-audit https://your-site.com"
echo ""
