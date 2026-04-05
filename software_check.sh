#!/bin/bash

HOSTNAME=$(hostname -s | tr -cd '[:alnum:]._-')
OS_NAME=$(lsb_release -si 2>/dev/null || cat /etc/os-release 2>/dev/null | grep "^ID=" | cut -d= -f2 | tr -d '"' || echo "unknown")
OS_VERSION=$(lsb_release -sr 2>/dev/null || cat /etc/os-release 2>/dev/null | grep "^VERSION_ID=" | cut -d= -f2 | tr -d '"' || echo "0.0")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "/tmp/diplom1"
LOG_FILE="/tmp/diplom1/software_${HOSTNAME}.json"

detect_pkg_manager() {
    if command -v dpkg &>/dev/null; then echo "dpkg"
    elif command -v rpm &>/dev/null; then echo "rpm"
    else echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

check_installed() {
    local name=$1
    case "$PKG_MANAGER" in
        dpkg) dpkg -l 2>/dev/null | grep -q "^ii.*$name" && echo "true" || echo "false" ;;
        rpm)  rpm -qa 2>/dev/null | grep -q "$name" && echo "true" || echo "false" ;;
        *)    echo "null" ;;
    esac
}

check_process() {
    local name=$1
    (pgrep -x "$name" > /dev/null 2>&1 || pgrep -f "$name" > /dev/null 2>&1) && echo "true" || echo "false"
}

check_service() {
    local name=$1
    if command -v systemctl &>/dev/null && systemctl list-units --type=service 2>/dev/null | grep -q "$name"; then
        systemctl is-active "$name" 2>/dev/null
    else
        echo "unavailable"
    fi
}

PROGRAMS=("google-chrome" "firefox" "libreoffice")

SOFTWARE_JSON=""
for prog in "${PROGRAMS[@]}"; do
    installed=$(check_installed "$prog")
    process=$(check_process "$prog")
    service=$(check_service "$prog")
    entry="{\"name\":\"$prog\",\"installed\":$installed,\"process_running\":$process,\"service_status\":\"$service\"}"
    SOFTWARE_JSON="${SOFTWARE_JSON:+$SOFTWARE_JSON,}$entry"
done

cat > "$LOG_FILE" <<EOF
{
  "hostname": "$HOSTNAME",
  "os_name": "$OS_NAME",
  "os_version": "$OS_VERSION",
  "timestamp": "$TIMESTAMP",
  "pkg_manager": "$PKG_MANAGER",
  "software": [$SOFTWARE_JSON]
}
EOF

echo "Log saved: $LOG_FILE"