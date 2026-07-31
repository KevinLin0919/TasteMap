#!/usr/bin/env bash
# 檢查 Config.xcconfig 裡的 Google API 金鑰，並同步到 GitHub Secrets，
# 讓 CI 產出的 IPA 也帶有金鑰。
#
#   1. 編輯 Config.xcconfig，把金鑰填在等號後面
#   2. bash scripts/set-api-key.sh
#
# 金鑰不會出現在指令參數或 shell 歷史中 —— 只從檔案讀。
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f Config.xcconfig ]; then
    cp Config.example.xcconfig Config.xcconfig
    echo "已從範本建立 Config.xcconfig。"
fi

KEY=$(sed -n 's/^[[:space:]]*GOOGLE_MAPS_API_KEY[[:space:]]*=[[:space:]]*//p' Config.xcconfig | tr -d '\r\n ' | head -1)

if [ -z "$KEY" ]; then
    echo "✗ Config.xcconfig 裡還沒有金鑰。"
    echo "  用記事本打開 D:\\TasteMap\\Config.xcconfig，把金鑰填在等號後面再存檔："
    echo "      GOOGLE_MAPS_API_KEY = AIza..."
    exit 1
fi

# Google 的金鑰是 AIza 開頭、39 字元。擋掉貼錯東西的意外。
if [[ ! "$KEY" =~ ^AIza[A-Za-z0-9_-]{35}$ ]]; then
    echo "✗ 檔案裡的值不像 Google API 金鑰。"
    echo "  長度 ${#KEY} 字元，開頭：${KEY:0:12}"
    echo "  預期是 39 字元、AIza 開頭。"
    exit 1
fi

echo "✓ Config.xcconfig 的金鑰格式正確（${KEY:0:10}… 共 ${#KEY} 字元）"

if command -v gh >/dev/null 2>&1; then
    printf '%s' "$KEY" | gh secret set GOOGLE_MAPS_API_KEY
    echo "✓ 已設定 GitHub Secret，CI 產出的 IPA 會帶金鑰"
else
    echo "! 找不到 gh，GitHub Secret 未設定 —— CI 的 IPA 將沒有金鑰"
fi
