#!/bin/bash
# advanced_wget_backup.sh

# ===============================
# 定義區 - 請根據需要修改以下設定
# ===============================

# 基本設定
WEBSITE_URL="https://yourdomain.com"
COOKIE_STRING="_ga=GA1.2.3456789012.3456789012; _gid=GA1.2.3456789012.3456789012; MoodleSession=123456789abcdefghijklmnopqrstuvwx; _gat=1; MOODLEID1_=sodium%3AG0pGRxtGmrw1R3e0wAmKT%2FJLtOq82iazXZmHK4ZPOcFqnMBCadf4tNeTnzHkP1doAjDDUPwqdVV9FEgnXqny%2Fn7B4D3kvw%3D%3D"
BACKUP_DIR="mod_assign_view"
LOG_FILE="backup.log"

# 後綴清單定義
# 格式：後綴路徑:開始數值:結束數值
# 如果不需要數值範圍，請設定為 後綴路徑::（兩個冒號表示無數值）
declare -a SUFFIX_LIST=(
    # "/course/view.php?id=:1:20000"
    # "/course/section.php?id=:1:20000"
    # "/mod/page/view.php?id=:1:20000"
    # "/mod/forum/view.php?id=:1:20000"
    "/mod/assign/view.php?id=:1:20000"
    # "/mod/quiz/view.php?id=:1:20000"
    # "/mod/resource/view.php?id=:1:20000"
    # "/enrol/index.php?id=:1:20000"
    # "/user/profile.php?id=:1:10000"
    # "/grade/report/overview/index.php::"
    # "/calendar/view.php::"
    # "/admin/index.php::"
)

# 其他設定
DELAY_MIN=1
DELAY_MAX=3
TIMEOUT=60
TRIES=5
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# 錯誤統計
AUTH_ERROR_COUNT=0

# ===============================
# 函數定義
# ===============================

# 顯示進度函數
show_progress() {
    local current=$1
    local total=$2
    local prefix=$3
    local percent=$((current * 100 / total))
    printf "\r[%s] 進度: %d/%d (%d%%)" "$prefix" "$current" "$total" "$percent"
}

# wget 下載函數
download_url() {
    local url=$1
    local description=$2
    local temp_log="temp_wget_$.log"
    echo "Dealing $url"
    
    # 執行 wget 並捕獲輸出
    wget \
        --header="Cookie: $COOKIE_STRING" \
        --header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        --timeout=30 \
        --tries=3 \
        --continue \
        --append-output="$LOG_FILE" \
        "$url"
    
    local exit_code=$?
    
    # macOS 相容的隨機延遲
    # sleep $(jot -r 1 $DELAY_MIN $DELAY_MAX)
    
    return $exit_code
}

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


# 2. 根據後綴清單進行特定頁面備份
echo "階段 2: 開始後綴清單備份..." | tee -a "$LOG_FILE"

for suffix_config in "${SUFFIX_LIST[@]}"; do
    # 解析設定 (後綴:開始:結束)
    IFS=':' read -r suffix start_num end_num <<< "$suffix_config"
    
    echo "----------------------------------------" | tee -a "$LOG_FILE"
    echo "處理後綴: $suffix" | tee -a "$LOG_FILE"
    
    if [[ -z "$start_num" || -z "$end_num" ]]; then
        # 無數值範圍，直接下載
        full_url="${WEBSITE_URL}${suffix}"
        echo "執行無數值備份: $full_url"
        echo "除錯: WEBSITE_URL='$WEBSITE_URL', suffix='$suffix'" >> "$LOG_FILE"
        echo "除錯: 組合後的 URL='$full_url'" >> "$LOG_FILE"
        download_url "$full_url" "$suffix"
    else
        # 有數值範圍，逐一嘗試
        echo "數值範圍: $start_num 到 $end_num" | tee -a "$LOG_FILE"
        total_count=$((end_num - start_num + 1))
        current_count=0
        success_count=0
        
        for ((i=start_num; i<=end_num; i++)); do
            current_count=$((current_count + 1))
            
            # 組合完整的 URL
            full_url="${WEBSITE_URL}${suffix}${i}"
            
            # 除錯輸出：顯示 URL 組合過程
            echo "除錯: WEBSITE_URL='$WEBSITE_URL', suffix='$suffix', i='$i'" >> "$LOG_FILE"
            echo "除錯: 組合後的 URL='$full_url'" >> "$LOG_FILE"
            
            # 顯示當前處理的 URL
            echo -n "[$current_count/$total_count] 備份: ${suffix}${i} "
            
            # 執行下載
            if download_url "$full_url" "${suffix}${i}"; then
                success_count=$((success_count + 1))
            fi
            
            # 每 10 個 URL 顯示統計
            if [ $((current_count % 10)) -eq 0 ]; then
                echo "  >> 已處理 $current_count/$total_count，成功 $success_count 個" | tee -a "$LOG_FILE"
            fi
        done
        
        echo "後綴 $suffix 完成: 總共嘗試 $total_count 個，成功 $success_count 個" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
done

# 3. 生成備份報告
echo "========================================" | tee -a "$LOG_FILE"
echo "備份完成時間: $(date)" | tee -a "$LOG_FILE"
echo "備份統計:" | tee -a "$LOG_FILE"
echo "- HTML 檔案數量: $(find . -name "*.html" | wc -l)" | tee -a "$LOG_FILE"
echo "- 總檔案數量: $(find . -type f | wc -l)" | tee -a "$LOG_FILE"
echo "- 備份大小: $(du -sh . | cut -f1)" | tee -a "$LOG_FILE"
echo "- 一般錯誤數量: $(grep -c "錯誤\|失敗\|ERROR" "$LOG_FILE" 2>/dev/null || echo 0)" | tee -a "$LOG_FILE"
echo "- 認證錯誤數量: $AUTH_ERROR_COUNT" | tee -a "$LOG_FILE"

# 檢查是否有空檔案或錯誤頁面
empty_files=$(find . -name "*.html" -size 0 | wc -l)
if [ "$empty_files" -gt 0 ]; then
    echo "- 警告: 發現 $empty_files 個空的 HTML 檔案" | tee -a "$LOG_FILE"
    echo "  建議檢查這些檔案對應的 URL 是否需要特殊處理" | tee -a "$LOG_FILE"
fi

# 認證錯誤警告
if [ "$AUTH_ERROR_COUNT" -gt 5 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "⚠️  警告: 發現 $AUTH_ERROR_COUNT 個認證相關錯誤 (401/403)" | tee -a "$LOG_FILE"
    echo "   建議檢查並更新 Cookie 字串！" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "備份腳本執行完畢！"
echo "日誌檔案: $LOG_FILE"
echo "備份目錄: $(pwd)"
