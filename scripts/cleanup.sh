#!/bin/bash
# UKC Cleanup Script
# 清理不需要的实例

set -euo pipefail

ORG="${1:-xiaojieyu}"
KEEP_METROS="${2:-fra,was,dal,sin,sfo}"

echo "==> 清理实例（保留 metro: ${KEEP_METROS}）..."

# 获取所有实例
INSTANCES=$(unikraft instance list --org "${ORG}" -o json 2>/dev/null || echo "[]")

# 解析并删除不在保留列表中的实例
echo "${INSTANCES}" | python3 -c "
import sys, json, subprocess

keep_metros = set('${KEEP_METROS}'.split(','))
instances = json.load(sys.stdin)

for inst in instances:
    metro = inst.get('metro', '')
    name = inst.get('name', '')
    if metro not in keep_metros:
        print(f'删除实例: {name} (metro: {metro})')
        subprocess.run(['unikraft', 'instance', 'delete', name, '--org', '${ORG}'], check=False)
    else:
        print(f'保留实例: {name} (metro: {metro})')
"

echo "清理完成"
