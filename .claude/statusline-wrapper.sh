#!/usr/bin/env bash
# Claude Code statusLine — compact two-line layout (merge of new spec + legacy fields).
#
# Line 1: git branch (+ ahead/behind) │ model │ context usage % │ session burn rate ($/hr) │ [vim mode]
#         (branch and vim shown only when present; vim sits at the end of line 1)
# Line 2: cwd basename │ 5h + 7d rate-limit progress bars, with:
#           - current %
#           - "→ projected %" (where the current pace lands by reset)
#           - "(reset in …)" countdown
#
# Requires: jq, bash. No ccusage dependency.
#
# Color thresholds (applied to bars and pace projections):
#   < 80%  green     80-89% yellow     >= 90% red

set -uo pipefail

input="$(cat)"

RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'
CYAN=$'\033[36m'

BAR_WIDTH=16
FILLED='█'
EMPTY='░'

color_for() {
  awk -v p="$1" 'BEGIN{
    if (p >= 90)      print "red"
    else if (p >= 80) print "yellow"
    else              print "green"
  }'
}

color_ansi() {
  case "$1" in
    red)    printf '%s' "$RED" ;;
    yellow) printf '%s' "$YELLOW" ;;
    *)      printf '%s' "$GREEN" ;;
  esac
}

format_reset() {
  local ts="$1"
  case "$ts" in ''|-|null|*[!0-9]*) return ;; esac
  local now delta days hours mins
  now=$(date +%s)
  delta=$((ts - now))
  (( delta < 0 )) && { printf 'reset soon'; return; }
  days=$((delta / 86400))
  hours=$(( (delta % 86400) / 3600 ))
  mins=$(( (delta % 3600) / 60 ))
  if   (( days  >= 1 )); then printf 'reset %dd %dh' "$days" "$hours"
  elif (( hours >= 1 )); then printf 'reset %dh %dm' "$hours" "$mins"
  elif (( mins  >= 1 )); then printf 'reset %dm'     "$mins"
  else                        printf 'reset <1m'
  fi
}

project_pct() {
  local pct="$1" resets_at="$2" period="$3"
  case "$pct" in -|null|'') return ;; esac
  case "$resets_at" in ''|-|null|*[!0-9]*) return ;; esac
  local now delta elapsed
  now=$(date +%s)
  delta=$((resets_at - now))
  (( delta < 0 || delta > period )) && return
  elapsed=$((period - delta))
  (( elapsed * 100 < period * 5  )) && return
  (( elapsed * 100 > period * 95 )) && return
  awk -v p="$pct" -v e="$elapsed" -v per="$period" 'BEGIN{
    printf "%.0f", p * per / e
  }'
}

bar() {
  local label="$1" raw_pct="$2" iso="${3:-}" period="${4:-0}"
  local pct="$raw_pct"
  case "$pct" in -|null|'') pct="0" ;; esac
  local rounded filled empty color i bar_str=""
  rounded=$(printf '%.0f' "$pct")
  filled=$(awk -v p="$pct" -v w="$BAR_WIDTH" 'BEGIN{
    f = int(p * w / 100 + 0.5)
    if (f > w) f = w
    if (f < 0) f = 0
    print f
  }')
  empty=$((BAR_WIDTH - filled))
  color=$(color_ansi "$(color_for "$pct")")
  for ((i=0; i<filled; i++)); do bar_str+="$FILLED"; done
  for ((i=0; i<empty;  i++)); do bar_str+="$EMPTY";  done

  local proj_str=""
  if [ "$period" -gt 0 ] && [ -n "$iso" ]; then
    local proj
    proj=$(project_pct "$raw_pct" "$iso" "$period")
    if [ -n "$proj" ]; then
      local pcolor
      pcolor=$(color_ansi "$(color_for "$proj")")
      proj_str=" ${DIM}→${RESET} ${pcolor}${proj}%${RESET}"
    fi
  fi

  local reset_str=""
  if [ -n "$iso" ]; then
    local r
    r=$(format_reset "$iso")
    [ -n "$r" ] && reset_str=" ${DIM}(${r})${RESET}"
  fi

  printf '%s %s%s%s %3d%%%s%s' "$label" "$color" "$bar_str" "$RESET" "$rounded" "$proj_str" "$reset_str"
}

IFS=$'\t' read -r model ctx_pct cost_usd duration_ms \
                five_p five_r week_p week_r cwd vim_mode <<<"$(printf '%s' "$input" | jq -r '
  [
    (.model.display_name                    // "?"),
    (.context_window.used_percentage        // 0),
    (.cost.total_cost_usd                   // 0),
    (.cost.total_duration_ms                // 0),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.rate_limits.five_hour.resets_at       // "-"),
    (.rate_limits.seven_day.used_percentage // "-"),
    (.rate_limits.seven_day.resets_at       // "-"),
    (.workspace.current_dir                 // .cwd // ""),
    (.vim.mode                              // "")
  ] | @tsv
' 2>/dev/null || printf -- '?\t0\t0\t0\t-\t-\t-\t-\t\t')"

burn_rate=$(awk -v c="$cost_usd" -v d="$duration_ms" 'BEGIN{
  if (d <= 0) { print "0.00"; exit }
  printf "%.2f", c * 3600000 / d
}')

sep="  ${DIM}│${RESET}  "

# --- git branch + cwd (used on line 1) ---
git_branch=""
git_sync=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
            || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
            || echo "")
  ahead=0; behind=0
  if a=$(git -C "$cwd" rev-list --count '@{u}..HEAD' 2>/dev/null); then ahead="$a"; fi
  if b=$(git -C "$cwd" rev-list --count 'HEAD..@{u}' 2>/dev/null); then behind="$b"; fi
  [ "$ahead"  -gt 0 ] 2>/dev/null && git_sync+="↑${ahead}"
  [ "$behind" -gt 0 ] 2>/dev/null && git_sync+="↓${behind}"
fi

short_cwd=""
[ -n "$cwd" ] && short_cwd=$(basename "$cwd")

ctx_color=$(color_ansi "$(color_for "$ctx_pct")")

line1=""
if [ -n "$git_branch" ]; then
  branch_icon=$(printf '\xee\x82\xa0')
  line1+="${YELLOW}${branch_icon} ${git_branch}${RESET}"
  [ -n "$git_sync" ] && line1+=" ${YELLOW}${git_sync}${RESET}"
  line1+="$sep"
fi
line1+="🤖 ${model}${sep}🧠 ${ctx_color}$(printf '%.0f' "$ctx_pct")%${RESET}${sep}🔥 \$${burn_rate}/hr"
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "INSERT" ]; then
    line1+="${sep}${GREEN}[${vim_mode}]${RESET}"
  else
    line1+="${sep}${YELLOW}[${vim_mode}]${RESET}"
  fi
fi

line2=""
if [ -n "$short_cwd" ]; then
  folder_icon=$(printf '\xef\x81\xbb')
  line2+="${CYAN}${folder_icon} ${short_cwd}${RESET}${sep}"
fi
line2+="$(bar "5h" "$five_p" "$five_r" 18000)${sep}$(bar "7d" "$week_p" "$week_r" 604800)"

printf '%s\n%s\n' "$line1" "$line2"
