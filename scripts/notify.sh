#!/bin/bash
# UKC Notify Script
# 发送 Telegram 通知

set -euo pipefail

TG_BOT_TOKEN="${1:-}"
TG_CHAT_ID="${2:-}"
MESSAGE="${3:-}"

if [ -z "${TG_BOT_TOKEN}" ] || [ -z "${TG_CHAT_ID}" ] || [ -z "${MESSAGE}" ]; then
    echo "Usage: $0 <tg_bot_token> <tg_chat_id> <message>"
    exit 1
fi

curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":\"${TG_CHAT_ID}\",\"text\":\"${MESSAGE}\",\"parse_mode\":\"Markdown\"}"

echo "通知已发送"
