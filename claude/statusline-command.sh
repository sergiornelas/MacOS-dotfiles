#!/bin/sh
input=$(cat)

used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

if [ -z "$used" ]; then
  exit 0
fi

used_int=$(printf '%.0f' "$used")

filled=$(( (used_int + 5) / 10 ))
empty=$(( 10 - filled ))

filled_color='\033[38;2;255;127;0m'
model_color='\033[38;2;104;157;106m'
branch_color='\033[38;2;215;153;33m'
ctx_color='\033[38;2;91;122;194m'
added_color='\033[38;2;104;157;106m'
modified_color='\033[38;2;251;73;52m'
untracked_color='\033[38;2;173;158;130m'
sep_color='\033[38;2;146;131;116m'
reset='\033[0m'

sep=" ${sep_color}|${reset} "
git_icon='\xee\x82\xa0'
model_icon='\xef\x8b\x9b'
ctx_icon='\xf3\xb0\x86\xbc'

bar=""
i=0
while [ $i -lt $filled ]; do
  bar="${bar}${filled_color}█${reset}"
  i=$(( i + 1 ))
done
i=0
while [ $i -lt $empty ]; do
  bar="${bar}░"
  i=$(( i + 1 ))
done

# Git branch + detailed status (if inside a repo)
branch=""
dirty=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    porcelain=$(git -C "$cwd" status --porcelain 2>/dev/null)
    added=$(printf '%s\n' "$porcelain" | grep -c '^[MADRC]')
    modified=$(printf '%s\n' "$porcelain" | grep -c '^.[MD]')
    untracked=$(printf '%s\n' "$porcelain" | grep -c '^??')
    [ -z "$porcelain" ] && added=0 && modified=0 && untracked=0
    [ "$added" -gt 0 ] && dirty="${dirty} ${added_color}+${added}${reset}"
    [ "$modified" -gt 0 ] && dirty="${dirty} ${modified_color}!${modified}${reset}"
    [ "$untracked" -gt 0 ] && dirty="${dirty} ${untracked_color}?${untracked}${reset}"
  fi
fi

model_out=""
if [ -n "$model" ]; then
  model_out="${model_color}${model_icon}  ${model}${reset}${sep}"
fi

ctx_out=""
if [ -n "$ctx" ]; then
  ctx_int=$(printf '%.0f' "$ctx")
  ctx_out="${sep}${ctx_color}${ctx_icon} ctx ${ctx_int}%${reset}"
fi

branch_out=""
if [ -n "$branch" ]; then
  branch_out="${sep}${branch_color}${git_icon} ${branch}${reset}${dirty}"
fi

printf "%b%d%% [%b]%b%b%b\n" "$model_out" "$used_int" "$bar" "$ctx_out" "$branch_out"
