#!/usr/bin/env bash
# ============================================================================
#  OLLAMA USB TOOLKIT - Pre-Flight Check
#  Run before installing to verify this drive is ready.
#  Checks: write access, free disk space, read/write speed
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# --- Counters ---
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
FAIL_MSGS=()
WARN_MSGS=()

# --- Thresholds ---
BENCH_SIZE_MB=64
MIN_WRITE_MBPS=5
REC_WRITE_MBPS=20
MIN_READ_MBPS=15
REC_READ_MBPS=80
MIN_FREE_GB=4
REC_FREE_GB=16

result_pass() { echo -e "  ${GREEN}✔${NC}  $1"; (( PASS_COUNT++ )); }
result_warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; (( WARN_COUNT++ )); WARN_MSGS+=("$1"); }
result_fail() { echo -e "  ${RED}✘${NC}  $1"; (( FAIL_COUNT++ )); FAIL_MSGS+=("$1"); }
result_info() { echo -e "  ${GRAY}ℹ${NC}  ${GRAY}$1${NC}"; }

clear
echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║         OLLAMA USB TOOLKIT - Pre-Flight Check        ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GRAY}Checking drive: ${WHITE}${SCRIPT_DIR}${NC}"
echo ""

# ============================================================================
# CHECK 1 — Write Access
# ============================================================================
echo -e "  ${WHITE}[1/4] Checking write access...${NC}"
if touch "${SCRIPT_DIR}/.write_test" 2>/dev/null; then
    rm -f "${SCRIPT_DIR}/.write_test"
    result_pass "Drive is writable"
else
    result_fail "Drive is READ-ONLY — cannot install to this location"
fi
echo ""

# ============================================================================
# CHECK 2 — Free Disk Space
# ============================================================================
echo -e "  ${WHITE}[2/4] Checking available disk space...${NC}"
AVAIL_GB=$(df -BG "${SCRIPT_DIR}" 2>/dev/null | awk 'NR==2 {gsub("G","",$4); print $4}')
TOTAL_GB=$(df -BG "${SCRIPT_DIR}" 2>/dev/null | awk 'NR==2 {gsub("G","",$2); print $2}')

if [ -n "$AVAIL_GB" ] && [ "$AVAIL_GB" -ge "$REC_FREE_GB" ] 2>/dev/null; then
    result_pass "Free space: ${AVAIL_GB} GB / ${TOTAL_GB} GB — plenty of room"
elif [ -n "$AVAIL_GB" ] && [ "$AVAIL_GB" -ge "$MIN_FREE_GB" ] 2>/dev/null; then
    result_warn "Free space: ${AVAIL_GB} GB — OK for 1 small model, but 16 GB+ recommended"
    result_info "Lightweight models need ~2 GB, medium models need 5-8 GB"
elif [ -n "$AVAIL_GB" ]; then
    result_fail "Free space: ${AVAIL_GB} GB — too low (minimum ${MIN_FREE_GB} GB needed)"
    result_info "Free up space on the drive before installing"
else
    result_warn "Could not determine free disk space"
fi
echo ""

# ============================================================================
# CHECK 3 — Write Speed Benchmark
# ============================================================================
echo -e "  ${WHITE}[3/4] Running write speed benchmark (${BENCH_SIZE_MB} MB test)...${NC}"
TMPFILE="${SCRIPT_DIR}/.bench_write_$$.tmp"

WRITE_MBPS=0
if command -v dd &>/dev/null; then
    T_START=$(date +%s%N 2>/dev/null || echo 0)
    dd if=/dev/urandom of="$TMPFILE" bs=1M count="$BENCH_SIZE_MB" conv=fsync 2>/dev/null
    T_END=$(date +%s%N 2>/dev/null || echo 0)
    T_NS=$(( T_END - T_START ))
    if (( T_NS > 0 )); then
        WRITE_MBPS=$(awk "BEGIN{printf \"%.1f\",($BENCH_SIZE_MB*1000000000)/$T_NS}")
        WRITE_INT="${WRITE_MBPS%.*}"
    fi
fi

if (( WRITE_INT >= REC_WRITE_MBPS )); then
    result_pass "Write speed: ${WRITE_MBPS} MB/s — great! Model downloads will be fast"
elif (( WRITE_INT >= MIN_WRITE_MBPS )); then
    result_warn "Write speed: ${WRITE_MBPS} MB/s — acceptable, but USB 3.0+ is recommended"
    result_info "Slow write speed means model downloads will take longer"
elif (( WRITE_INT > 0 )); then
    result_fail "Write speed: ${WRITE_MBPS} MB/s — too slow (minimum ${MIN_WRITE_MBPS} MB/s)"
    result_info "Use a USB 3.0+ drive in a USB 3.0+ port for best performance"
else
    result_warn "Write benchmark could not be measured"
fi
echo ""

# ============================================================================
# CHECK 4 — Read Speed Benchmark
# ============================================================================
echo -e "  ${WHITE}[4/4] Running read speed benchmark...${NC}"

READ_MBPS=0
READ_INT=0
if [ -f "$TMPFILE" ]; then
    sync
    # Drop page cache if possible
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    T_START=$(date +%s%N 2>/dev/null || echo 0)
    dd if="$TMPFILE" of=/dev/null bs=1M 2>/dev/null
    T_END=$(date +%s%N 2>/dev/null || echo 0)
    T_NS=$(( T_END - T_START ))
    if (( T_NS > 0 )); then
        READ_MBPS=$(awk "BEGIN{printf \"%.1f\",($BENCH_SIZE_MB*1000000000)/$T_NS}")
        READ_INT="${READ_MBPS%.*}"
    fi
fi
rm -f "$TMPFILE" 2>/dev/null || true

if (( READ_INT >= REC_READ_MBPS )); then
    result_pass "Read speed: ${READ_MBPS} MB/s — excellent! AI models will load quickly"
elif (( READ_INT >= MIN_READ_MBPS )); then
    result_warn "Read speed: ${READ_MBPS} MB/s — OK, but models may take 15-30s to load"
elif (( READ_INT > 0 )); then
    result_fail "Read speed: ${READ_MBPS} MB/s — too slow. AI responses will be very sluggish"
    result_info "Upgrade to a USB 3.0+ drive for a usable experience"
else
    result_warn "Read benchmark could not be measured"
fi

# USB generation hint
echo ""
if   (( READ_INT >= 150 )); then
    echo -e "  ${CYAN}ℹ${NC}  ${GRAY}Drive type detected: USB 3.1/3.2 Gen 2 — excellent${NC}"
elif (( READ_INT >= 80  )); then
    echo -e "  ${CYAN}ℹ${NC}  ${GRAY}Drive type detected: USB 3.0 / 3.1 Gen 1 — good${NC}"
elif (( READ_INT >= 25  )); then
    echo -e "  ${YELLOW}ℹ${NC}  ${YELLOW}Drive type detected: USB 3.0 (low-end or congested port)${NC}"
elif (( READ_INT > 0    )); then
    echo -e "  ${RED}ℹ${NC}  ${RED}Drive type detected: USB 2.0 — upgrade strongly recommended${NC}"
fi
echo ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║                  Pre-Flight Summary                 ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}✔ Passed   : ${PASS_COUNT}${NC}"
echo -e "  ${YELLOW}⚠ Warnings : ${WARN_COUNT}${NC}"
echo -e "  ${RED}✘ Failed   : ${FAIL_COUNT}${NC}"

if (( ${#WARN_MSGS[@]} > 0 )); then
    echo ""
    echo -e "  ${YELLOW}Warnings:${NC}"
    for msg in "${WARN_MSGS[@]}"; do
        echo -e "  ${YELLOW}  · ${NC}${msg}"
    done
fi

if (( ${#FAIL_MSGS[@]} > 0 )); then
    echo ""
    echo -e "  ${RED}Failed checks:${NC}"
    for msg in "${FAIL_MSGS[@]}"; do
        echo -e "  ${RED}  · ${NC}${msg}"
    done
fi

echo ""

# ============================================================================
# DECISION GATE
# ============================================================================
if (( FAIL_COUNT > 0 )); then
    echo -e "${RED}  ✘  REQUIREMENTS NOT MET — Please fix the issues above.${NC}"
    echo -e "     Resolve the failed checks, then re-run this script."
    echo ""
    exit 1

elif (( WARN_COUNT > 0 )); then
    echo -e "${YELLOW}  ⚠  REQUIREMENTS MET WITH WARNINGS${NC}"
    echo -e "     Installation can proceed, but review warnings above."
    echo ""
    read -rp "  Proceed to installation anyway? (y/N): " CONFIRM
    if [[ "${CONFIRM,,}" == "y" ]]; then
        echo ""
        exit 0
    else
        echo ""
        echo -e "  ${GRAY}Cancelled. Re-run preflight-check.sh when ready.${NC}"
        exit 1
    fi

else
    echo -e "${GREEN}  ✔  ALL CHECKS PASSED — Your drive is ready!${NC}"
    echo ""
    read -rp "  Proceed to installation? (y/N): " CONFIRM
    if [[ "${CONFIRM,,}" == "y" ]]; then
        echo ""
        exit 0
    else
        echo ""
        echo -e "  ${GRAY}No problem — run START-Linux.sh whenever you're ready.${NC}"
        exit 1
    fi
fi
