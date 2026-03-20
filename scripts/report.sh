#!/bin/bash
# AutoForge Report v2 — Rich live progress updates with Unicode bars
# Supports: Telegram, Discord, Slack, stdout (ANSI fallback)
#
# Usage: ./report.sh [results.tsv] [skill-name] [--final] [--json] [--dashboard]
#
# Environment:
#   AF_CHANNEL   — Messaging channel (telegram, discord, slack). Default: telegram
#   AF_CHAT_ID   — Chat/group ID for delivery. If unset, prints to stdout.
#   AF_TOPIC_ID  — Thread/topic ID within the chat (optional).
#
# Flags:
#   --final      — End-of-run summary with conclusion
#   --json       — JSON output for programmatic consumption
#   --dashboard  — Full dashboard with stats, trends, and eval breakdown
#
# Examples:
#   AF_CHAT_ID="-100123456" AF_TOPIC_ID="2211" ./report.sh results.tsv "My Skill"
#   ./report.sh results.tsv "My Skill" --final --dashboard
#   ./report.sh results.tsv "My Skill" --json

set -euo pipefail

RESULTS_FILE="${1:-results.tsv}"
SKILL_NAME="${2:-Skill}"
shift 2 2>/dev/null || true

# Parse flags
FINAL_FLAG="false"
JSON_FLAG=""
DASHBOARD_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --final)     FINAL_FLAG="true" ;;
    --json)      JSON_FLAG="yes" ;;
    --dashboard) DASHBOARD_FLAG="yes" ;;
  esac
done

# Configuration from environment
CHANNEL="${AF_CHANNEL:-telegram}"
CHAT_ID="${AF_CHAT_ID:-}"
TOPIC_ID="${AF_TOPIC_ID:-}"

# --- Validation ---

if [ ! -f "$RESULTS_FILE" ]; then
  echo "Error: Results file not found: $RESULTS_FILE" >&2
  exit 1
fi

LINE_COUNT=$(tail -n +2 "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d ' ')
if [ "$LINE_COUNT" -eq 0 ]; then
  echo "Error: No data rows in $RESULTS_FILE" >&2
  exit 1
fi

# --- Data Extraction ---

TOTAL=$(tail -n +2 "$RESULTS_FILE" | wc -l | tr -d ' ')
KEEP=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '{s=$NF} s=="keep"||s=="best"||s=="improved"||s=="retained"||s=="baseline" {c++} END{print c+0}')
DISCARD=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '$NF=="discard" {c++} END{print c+0}')
BEST=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '{val=$3; gsub(/%/,"",val); if(val ~ /^[0-9.]+$/ && val+0>max+0)max=val} END{print max+0}')
BEST_ITER=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' -v best="$BEST" '{val=$3; gsub(/%/,"",val); if(val ~ /^[0-9.]+$/ && val+0==best+0){print NR; exit}}')
LAST_RATE=$(tail -n +2 "$RESULTS_FILE" | tail -1 | awk -F'\t' '{print $3}')
LAST_STATUS=$(tail -n +2 "$RESULTS_FILE" | tail -1 | awk -F'\t' '{print $NF}')
FIRST_RATE=$(tail -n +2 "$RESULTS_FILE" | head -1 | awk -F'\t' '{val=$3; gsub(/%/,"",val); print val+0}')

# Extended stats for v2
IMPROVED_COUNT=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '$NF=="improved" {c++} END{print c+0}')
RETAINED_COUNT=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '$NF=="retained" {c++} END{print c+0}')
BASELINE_COUNT=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '$NF=="baseline" {c++} END{print c+0}')

# Calculate improvement delta
DELTA=$((BEST - FIRST_RATE))

# Calculate streak info
CURRENT_STREAK=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '
  { status=$NF }
  NR==1 { last=status; count=1; next }
  status==last { count++; next }
  { last=status; count=1 }
  END { printf "%d×%s", count, last }
')

# Regression detection (v2): check if last rate dropped from previous
PREV_RATE=$(tail -n +2 "$RESULTS_FILE" | tail -2 | head -1 | awk -F'\t' '{val=$3; gsub(/%/,"",val); print int(val+0)}' 2>/dev/null || echo "0")
LAST_RATE_NUM=$(printf '%.0f' "${LAST_RATE//%/}" 2>/dev/null || echo "0")
if echo "$LAST_RATE_NUM" | grep -qE '^[0-9]+$'; then
  REGRESSION_FLAG=""
  if [ "$LAST_RATE_NUM" -lt "$PREV_RATE" ] 2>/dev/null; then
    REGRESSION_FLAG="⚠️ Regression: ${PREV_RATE}% → ${LAST_RATE_NUM}%"
  fi
else
  REGRESSION_FLAG=""
fi

# Eval category breakdown (v2): read from extended TSV if present
# Extended TSV has optional col 6: eval_category (structural|simulated|live)
# shellcheck disable=SC2034
HAS_CATEGORIES=$(head -1 "$RESULTS_FILE" | awk -F'\t' '{if(NF>=6) print "yes"; else print "no"}')

# --- JSON Output ---

if [ "$JSON_FLAG" = "yes" ]; then
  ITER_JSON=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '
    BEGIN { printf "[" }
    NR>1 { printf "," }
    {
      gsub(/"/, "\\\"", $2);
      gsub(/"/, "\\\"", $4);
      gsub(/%/, "", $3);
      cat6 = (NF>=6) ? $6 : "unknown";
      printf "{\"iteration\":%s,\"summary\":\"%s\",\"pass_rate\":%s,\"change\":\"%s\",\"status\":\"%s\",\"category\":\"%s\"}", $1, $2, ($3 ~ /^[0-9.]+$/ ? $3 : "0"), $4, $5, cat6
    }
    END { printf "]" }
  ')

  cat <<EOF
{
  "skill": "${SKILL_NAME}",
  "version": "2.0",
  "total_iterations": ${TOTAL},
  "kept": ${KEEP},
  "discarded": ${DISCARD},
  "improved": ${IMPROVED_COUNT},
  "retained": ${RETAINED_COUNT},
  "best_pass_rate": ${BEST},
  "best_iteration": ${BEST_ITER:-0},
  "baseline_rate": ${FIRST_RATE},
  "improvement_delta": ${DELTA},
  "last_rate": "${LAST_RATE}",
  "last_status": "${LAST_STATUS}",
  "current_streak": "${CURRENT_STREAK}",
  "final": ${FINAL_FLAG},
  "iterations": ${ITER_JSON}
}
EOF
  exit 0
fi

# --- Build Unicode Bar Display ---

ITER_LINES=""
while IFS=$'\t' read -r iter _summary rate _change status rest; do
  rate_num="${rate//%/}"
  if ! echo "$rate_num" | grep -qE '^[0-9.]+$'; then
    rate_num="0"
  fi

  # Build progress bar (20 chars)
  filled=$((rate_num / 5))
  empty=$((20 - filled))
  bar=""
  for ((b=0; b<filled; b++)); do bar="${bar}█"; done
  for ((b=0; b<empty; b++)); do bar="${bar}░"; done

  case "$status" in
    keep|improved|best) icon="✅" ;;
    retained)           icon="➡️" ;;
    discard)            icon="❌" ;;
    crash)              icon="💥" ;;
    baseline)           icon="📍" ;;
    regression)         icon="⬇️" ;;
    *)                  icon="🔹" ;;
  esac

  ITER_LINES="${ITER_LINES}
${icon} Iter ${iter}  ${bar}  ${rate}"
done < <(tail -n +2 "$RESULTS_FILE")

# --- Build Stats Block (v2) ---

STATS_BLOCK="Iterations: ${TOTAL}  ✅ ${IMPROVED_COUNT}  ➡️ ${RETAINED_COUNT}  ❌ ${DISCARD}
🏆 Best: ${BEST}% (Iter ${BEST_ITER})  📈 Δ+${DELTA}%"

if [ -n "$REGRESSION_FLAG" ]; then
  STATS_BLOCK="${STATS_BLOCK}
${REGRESSION_FLAG}"
fi

# --- Build Dashboard (v2, optional) ---

DASHBOARD_BLOCK=""
if [ "$DASHBOARD_FLAG" = "yes" ]; then
  # Improvement velocity: avg pass rate gain per iteration
  VELOCITY=$(tail -n +2 "$RESULTS_FILE" | awk -F'\t' '
    { val=$3; gsub(/%/,"",val); rates[NR]=val+0 }
    END {
      if(NR<=1) { print "N/A"; exit }
      gains=0; count=0
      for(i=2;i<=NR;i++) {
        d=rates[i]-rates[i-1]
        if(d>0) { gains+=d; count++ }
      }
      if(count>0) printf "+%.1f%%/iter", gains/count
      else print "plateau"
    }
  ')

  # Efficiency: improved / (total - baseline)
  EFFICIENCY="0"
  NON_BASELINE=$((TOTAL - BASELINE_COUNT))
  if [ "$NON_BASELINE" -gt 0 ]; then
    EFFICIENCY=$((IMPROVED_COUNT * 100 / NON_BASELINE))
  fi

  # Time-to-best
  TTB="${BEST_ITER:-?} iterations"

  DASHBOARD_BLOCK="
📊 Dashboard
├ Velocity: ${VELOCITY}
├ Efficiency: ${EFFICIENCY}% (improvements/attempts)
├ Time-to-best: ${TTB}
├ Streak: ${CURRENT_STREAK}
└ Baseline → Best: ${FIRST_RATE}% → ${BEST}%"
fi

# --- Build Message ---

if [ "$FINAL_FLAG" = "true" ]; then
  case "$LAST_STATUS" in
    improved|best) CONCLUSION="✅ Converged — improvement found" ;;
    retained)      CONCLUSION="➡️ Stable — no further improvement possible" ;;
    discard)       CONCLUSION="⚠️ Last discarded — best state from Iter ${BEST_ITER}" ;;
    regression)    CONCLUSION="⬇️ Regression detected — rolled back to Iter ${BEST_ITER}" ;;
    *)             CONCLUSION="🏁 Loop finished" ;;
  esac

  # Determine improvement tier
  if [ "$BEST" -eq 100 ] 2>/dev/null; then
    TIER="🥇 Perfect (100%)"
  elif [ "$BEST" -ge 90 ] 2>/dev/null; then
    TIER="🥈 Excellent (≥90%)"
  elif [ "$BEST" -ge 75 ] 2>/dev/null; then
    TIER="🥉 Good (≥75%)"
  else
    TIER="⚠️ Needs work (<75%)"
  fi

  case "$CHANNEL" in
    discord)
      MSG="📊 **AutoForge complete: ${SKILL_NAME}**
${ITER_LINES}

──────────────────────
${STATS_BLOCK}
${TIER}

${CONCLUSION}${DASHBOARD_BLOCK}

_--dry-run mode. Approve for --live?_"
      ;;
    *)
      MSG="📊 *AutoForge complete: ${SKILL_NAME}*
${ITER_LINES}

──────────────────────
${STATS_BLOCK}
${TIER}

${CONCLUSION}${DASHBOARD_BLOCK}

_--dry-run mode. Approve for --live?_"
      ;;
  esac
else
  case "$CHANNEL" in
    discord)
      MSG="📊 **AutoForge: ${SKILL_NAME}**
${ITER_LINES}

──────────────────────
${STATS_BLOCK}"
      ;;
    *)
      MSG="📊 *AutoForge: ${SKILL_NAME}*
${ITER_LINES}

──────────────────────
${STATS_BLOCK}"
      ;;
  esac
fi

# Append dashboard if requested (non-final)
if [ "$DASHBOARD_FLAG" = "yes" ] && [ "$FINAL_FLAG" = "false" ]; then
  MSG="${MSG}${DASHBOARD_BLOCK}"
fi

# --- Deliver ---

if [ -n "$CHAT_ID" ] && command -v openclaw &>/dev/null; then
  CMD="openclaw message send --channel ${CHANNEL} --target ${CHAT_ID}"
  if [ -n "$TOPIC_ID" ]; then
    CMD="${CMD} --thread-id ${TOPIC_ID}"
  fi
  CMD="${CMD} --message"

  $CMD "$MSG"
else
  # Stdout fallback with ANSI colors
  if [ -t 1 ]; then
    echo ""
    echo -e "\033[1;36m${MSG}\033[0m"
    echo ""
    if [ -z "$CHAT_ID" ]; then
      echo -e "\033[33mTip: Set AF_CHAT_ID to deliver reports to a channel.\033[0m"
    fi
    if ! command -v openclaw &>/dev/null; then
      echo -e "\033[33mTip: Install openclaw CLI for channel delivery.\033[0m"
    fi
  else
    echo "$MSG"
  fi
fi
