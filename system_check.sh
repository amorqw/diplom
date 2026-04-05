#!/bin/bash

HOSTNAME=$(hostname -s | tr -cd '[:alnum:]._-')
OS_NAME=$(lsb_release -si 2>/dev/null || cat /etc/os-release 2>/dev/null | grep "^ID=" | cut -d= -f2 | tr -d '"' || echo "unknown")
OS_VERSION=$(lsb_release -sr 2>/dev/null || cat /etc/os-release 2>/dev/null | grep "^VERSION_ID=" | cut -d= -f2 | tr -d '"' || echo "0.0")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "/tmp/diplom1"
LOG_FILE="/tmp/diplom1/system_${HOSTNAME}.json"

RAM_TOTAL=$(free -b | awk '/^Mem:/{print $2}')
RAM_USED=$(free -b  | awk '/^Mem:/{print $3}')
RAM_FREE=$(free -b  | awk '/^Mem:/{print $4}')

SWAP_TOTAL=$(free -b | awk '/^Swap:/{print $2}')
SWAP_USED=$(free -b  | awk '/^Swap:/{print $3}')

DISK_JSON=$(df --block-size=1 | grep -v tmpfs | grep -v udev | grep -v "^Filesystem" | \
    awk '{printf "{\"mount\":\"%s\",\"total\":%s,\"used\":%s,\"available\":%s,\"use_pct\":\"%s\"},", $6, $2, $3, $4, $5}')
DISK_JSON="[${DISK_JSON%,}]" 

CPU_PROC_JSON=$(ps aux --sort=-%cpu | awk 'NR>1 && NR<=11 {
    printf "{\"pid\":%s,\"user\":\"%s\",\"cpu_pct\":%s,\"mem_pct\":%s,\"cmd\":\"%s\"},", $2, $1, $3, $4, $11
}')
CPU_PROC_JSON="[${CPU_PROC_JSON%,}]"

MEM_PROC_JSON=$(ps aux --sort=-%mem | awk 'NR>1 && NR<=11 {
    printf "{\"pid\":%s,\"user\":\"%s\",\"cpu_pct\":%s,\"mem_pct\":%s,\"mem_bytes\":%d,\"cmd\":\"%s\"},",
    $2, $1, $3, $4, $6*1024, $11
}')
MEM_PROC_JSON="[${MEM_PROC_JSON%,}]"

cat > "$LOG_FILE" <<EOF
{
  "hostname": "$HOSTNAME",
  "os_name": "$OS_NAME",
  "os_version": "$OS_VERSION",
  "timestamp": "$TIMESTAMP",
  "ram": {
    "total_bytes": $RAM_TOTAL,
    "used_bytes": $RAM_USED,
    "free_bytes": $RAM_FREE
  },
  "swap": {
    "total_bytes": $SWAP_TOTAL,
    "used_bytes": $SWAP_USED
  },
  "disk": $DISK_JSON,
  "top_cpu_processes": $CPU_PROC_JSON,
  "top_mem_processes": $MEM_PROC_JSON
}
EOF

echo "Log saved: $LOG_FILE"