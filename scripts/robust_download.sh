#!/bin/bash

# 鲁棒的下载脚本
# 用法: ./robust_download.sh <URL> <OUTPUT_PATH> [DESCRIPTION] [FALLBACK_URL1] [FALLBACK_URL2] ...

set -e

# 参数检查
if [ $# -lt 2 ]; then
    echo "用法: $0 <URL> <OUTPUT_PATH> [DESCRIPTION] [FALLBACK_URL1] [FALLBACK_URL2] ..."
    exit 1
fi

URL="$1"
OUTPUT_PATH="$2"
DESCRIPTION="${3:-$(basename $OUTPUT_PATH)}"
shift 3

# 备用URL列表
FALLBACK_URLS=("$@")

# 下载配置
MAX_RETRIES=3
TIMEOUT=30
USER_AGENT="Mozilla/5.0 (compatible; IP-Database-Updater/1.0)"

# 状态文件
STATUS_FILE="update_status.md"

# 记录状态的函数
log_status() {
    local status="$1"
    local message="$2"
    echo "$status $DESCRIPTION: $message" >> "$STATUS_FILE"
}

# 验证下载文件的函数
validate_download() {
    local file="$1"
    
    # 检查文件是否存在且不为空
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        return 1
    fi
    
    # 检查是否是HTML错误页面（通常表示404或其他HTTP错误）
    if file "$file" | grep -q "HTML\|ASCII text" && head -n 5 "$file" | grep -qi "error\|not found\|404"; then
        return 1
    fi
    
    return 0
}

# 尝试下载的函数
try_download() {
    local url="$1"
    local output="$2"
    local temp_file="${output}.tmp"
    
    echo "尝试从 $url 下载..."
    
    # 使用wget下载到临时文件
    if wget \
        --timeout="$TIMEOUT" \
        --tries="$MAX_RETRIES" \
        --user-agent="$USER_AGENT" \
        --no-check-certificate \
        --progress=dot:mega \
        "$url" \
        -O "$temp_file" 2>/dev/null; then
        
        # 验证下载的文件
        if validate_download "$temp_file"; then
            mv "$temp_file" "$output"
            return 0
        else
            echo "下载的文件验证失败"
            rm -f "$temp_file"
            return 1
        fi
    else
        rm -f "$temp_file"
        return 1
    fi
}

# 主下载逻辑
echo "开始下载 $DESCRIPTION..."

# 创建输出目录（如果不存在）
mkdir -p "$(dirname "$OUTPUT_PATH")"

# 尝试主URL
if try_download "$URL" "$OUTPUT_PATH"; then
    log_status "✅" "SUCCESS (primary source)"
    echo "✅ $DESCRIPTION 下载成功 (主要源)"
    exit 0
fi

# 尝试备用URL
for i in "${!FALLBACK_URLS[@]}"; do
    fallback_url="${FALLBACK_URLS[$i]}"
    echo "尝试备用源 $((i+1)): $fallback_url"
    
    if try_download "$fallback_url" "$OUTPUT_PATH"; then
        log_status "✅" "SUCCESS (fallback source $((i+1)))"
        echo "✅ $DESCRIPTION 下载成功 (备用源 $((i+1)))"
        exit 0
    fi
done

# 所有尝试都失败了
log_status "❌" "FAILED (all sources)"
echo "❌ $DESCRIPTION 下载失败 - 所有源都不可用"

# 检查是否存在旧文件
if [ -f "$OUTPUT_PATH" ]; then
    echo "ℹ️  保留现有文件: $OUTPUT_PATH"
    log_status "⚠️" "FAILED but kept existing file"
else
    echo "❌ 没有可用的文件"
fi

exit 1