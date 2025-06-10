#!/bin/bash
# advanced_wget_backup.sh

# ===============================
# 定義區 - 請根據需要修改以下設定
# ===============================

# 基本設定
WEBSITE_URL="https://yourdomain.com"
COOKIE_STRING="_ga=GA1.2.3456789012.3456789012; _gid=GA1.2.3456789012.3456789012; MoodleSession=123456789abcdefghijklmnopqrstuvwx; _gat=1; MOODLEID1_=sodium%3AG0pGRxtGmrw1R3e0wAmKT%2FJLtOq82iazXZmHK4ZPOcFqnMBCadf4tNeTnzHkP1doAjDDUPwqdVV9FEgnXqny%2Fn7B4D3kvw%3D%3D"
BACKUP_DIR="domain_backup"
LOG_FILE="backup.log"

# 其他設定
DELAY_MIN=1
DELAY_MAX=3
TIMEOUT=60
TRIES=5
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# ===============================
# 主程式開始
# ===============================

# 建立備份目錄
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

echo "========================================" | tee "$LOG_FILE"
echo "開始備份網站: $WEBSITE_URL" | tee -a "$LOG_FILE"
echo "備份時間: $(date)" | tee -a "$LOG_FILE"
echo "備份目錄: $(pwd)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 1. 主要網站遞歸備份
echo "階段 1: 執行主要網站遞歸備份..." | tee -a "$LOG_FILE"
wget \
  --recursive \
  --level=5 \
  --no-clobber \
  --page-requisites \
  --html-extension \
  --convert-links \
  --restrict-file-names=windows \
  --domains tksg.org \
  --no-parent \
  --header="Cookie: $COOKIE_STRING" \
  --header="User-Agent: $USER_AGENT" \
  --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
  --header="Accept-Language: zh-TW,zh;q=0.9,en;q=0.8" \
  --wait=2 \
  --random-wait \
  --timeout="$TIMEOUT" \
  --tries="$TRIES" \
  --continue \
  --progress=bar \
  --append-output="$LOG_FILE" \
  "$WEBSITE_URL"

echo "階段 1 完成" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
