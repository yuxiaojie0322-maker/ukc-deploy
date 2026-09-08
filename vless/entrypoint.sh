#!/bin/bash
set -e

echo "=== Starting VLESS Microkernel with Nezha Agent ==="

# 1. Start Nezha Agent v1 if configured
if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ]; then
  echo "Configuring Nezha Agent for ${NEZHA_SERVER}..."
  mkdir -p /tmp/nezha
  cat << EOF > /tmp/nezha/config.yaml
client_secret: ${NEZHA_KEY}
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: true
ip_report_period: 1800
report_delay: 4
server: ${NEZHA_SERVER}
skip_connection_count: true
skip_procs_count: true
temperature: false
tls: true
use_gitee_to_upgrade: false
use_ipv6_country_code: false
EOF

  echo "Launching Nezha Agent v1 in background..."
  /nezha-agent -c /tmp/nezha/config.yaml > /dev/null 2>&1 &
  echo "Nezha Agent started successfully!"
fi

# 2. Launch VLESS WebSocket Server in foreground
echo "Launching VLESS Server on port ${PORT:-8080}..."
exec /server
