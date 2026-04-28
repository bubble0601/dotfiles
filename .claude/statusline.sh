#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# --- Working directory ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
short_cwd=$(basename "$cwd")

# --- Git branch + ahead/behind ---
git_branch=""
git_sync=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null)
  behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null)
  if [ -n "$ahead" ] && [ -n "$behind" ]; then
    [ "$ahead" -gt 0 ] && git_sync+="↑${ahead}"
    [ "$behind" -gt 0 ] && git_sync+="↓${behind}"
  fi
fi

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // ""')
model_short=$(echo "$model" | sed 's/Claude //' | sed 's/ Sonnet/ S/' | sed 's/ Haiku/ H/' | sed 's/ Opus/ O/')

# --- Context remaining ---
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# --- Vim mode ---
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# --- Strip ANSI codes to measure visible length ---
strip_ansi() {
  echo -e "$1" | sed 's/\033\[[0-9;]*m//g'
}

# --- Build left parts ---
left_parts=()

# Git branch + ahead/behind (yellow)
if [ -n "$git_branch" ]; then
  branch_icon=$(printf '\xee\x82\xa0')
  branch_str="$(printf '\033[33m%s %s\033[0m' "$branch_icon" "$git_branch")"
  if [ -n "$git_sync" ]; then
    branch_str+=" $(printf '\033[33m%s\033[0m' "$git_sync")"
  fi
  left_parts+=("$branch_str")
fi

# --- Build right parts ---
right_parts=()

# Model (magenta)
if [ -n "$model_short" ]; then
  right_parts+=("$(printf '\033[35m[%s]\033[0m' "$model_short")")
fi

# Context remaining (green/yellow/red)
if [ -n "$remaining" ]; then
  remaining_int=$(printf '%.0f' "$remaining")
  if [ "$remaining_int" -gt 40 ]; then
    right_parts+=("$(printf '\033[32mctx:%s%%\033[0m' "$remaining_int")")
  elif [ "$remaining_int" -gt 15 ]; then
    right_parts+=("$(printf '\033[33mctx:%s%%\033[0m' "$remaining_int")")
  else
    # 背景赤+白+太字で警告
    right_parts+=("$(printf '\033[1;37;41m CTX:%s%% \033[0m' "$remaining_int")")
  fi
fi

# Vim mode
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "INSERT" ]; then
    right_parts+=("$(printf '\033[32;1m[%s]\033[0m' "$vim_mode")")
  else
    right_parts+=("$(printf '\033[33;1m[%s]\033[0m' "$vim_mode")")
  fi
fi

# Directory (cyan)
folder_icon=$(printf '\xef\x81\xbb')
right_parts+=("$(printf '\033[36m%s %s\033[0m' "$folder_icon" "$short_cwd")")

# --- Join and align ---
left_str="$(IFS=' '; echo "${left_parts[*]}")"
right_str="$(IFS=' '; echo "${right_parts[*]}")"

term_width=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
[ -z "$term_width" ] && term_width=$(tput cols </dev/tty 2>/dev/null)
[ -z "$term_width" ] && term_width=80
left_visible=$(strip_ansi "$left_str" | tr -d '\n')
right_visible=$(strip_ansi "$right_str" | tr -d '\n')
left_len=${#left_visible}
right_len=${#right_visible}

pad=$((term_width - left_len - right_len - 1))
[ "$pad" -lt 1 ] && pad=1

printf '%s%*s%s' "$left_str" "$pad" "" "$right_str"
