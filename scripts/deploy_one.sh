#!/bin/bash
# UKC Deploy Script
# �?bh-scripts 仓库拉取核心脚本并执行部�?

set -euo pipefail

METRO="${1:-}"
IMAGE="${2:-xiaojieyu/x-tunnel:latest}"
MEMORY="${3:-256Mi}"
ORG="${4:-xiaojieyu}"

if [ -z "${METRO}" ]; then
    echo "Usage: $0 <metro> [image] [memory] [org]"
    echo "Metro: fra, was, dal, sin, sfo"
    exit 1
fi

INSTANCE_NAME="ukc-${METRO}"
FULL_IMAGE="oci://unikraft.io/${IMAGE}"

echo "==> 部署�?${METRO}..."
echo "    实例�? ${INSTANCE_NAME}"
echo "    镜像: ${FULL_IMAGE}"
echo "    内存: ${MEMORY}"
echo "    组织: ${ORG}"

# 创建实例
echo "==> 创建实例..."
unikraft instance create "${INSTANCE_NAME}" \
    --metro "${METRO}" \
    --image "${FULL_IMAGE}" \
    --memory "${MEMORY}" \
    --vcpus 1 \
    --scale-to-zero true \
    --cooldown-time 1000 \
    --publish 443:8080/http+tls \
    --publish 80:8080/http \
    --org "${ORG}" \
    -o json

# 等待实例就绪
echo "==> 等待实例就绪..."
_timeout=300
_count=0
while [ $_count -lt $_timeout ]; do
    STATUS=$(unikraft instance get "${INSTANCE_NAME}" -o json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('state', 'unknown'))" 2>/dev/null || echo "error")
    echo "[$_count/$\timeout] 状�? ${STATUS}"
    if [ "${STATUS}" = "running" ]; then
        break
    fi
    sleep 10
    _count=$((_count + 10))
done

if [ "${STATUS}" != "running" ]; then
    echo "错误: 实例未进�?running 状态，最后状�? ${STATUS}"
    exit 1
fi

# 获取 FQDN
FQDN=$(unikraft instance get "${INSTANCE_NAME}" -o json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('fqdn', d.get('domain', 'unknown')))" 2>/dev/null || echo "unknown")
echo "FQDN: ${FQDN}"

# 冒烟测试
echo "==> 冒烟测试..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 15 "https://${FQDN}" 2>/dev/null || echo "000")
if [ "${HTTP_CODE}" = "200" ] || [ "${HTTP_CODE}" = "301" ] || [ "${HTTP_CODE}" = "302" ]; then
    STATUS="�?running"
else
    STATUS="⚠️ unreachable (HTTP ${HTTP_CODE})"
fi
echo "状�? ${STATUS}"

# 输出结果
echo ""
echo "==> 完成"
echo "实例: ${INSTANCE_NAME}"
echo "FQDN: https://${FQDN}"
echo "状�? ${STATUS}"
