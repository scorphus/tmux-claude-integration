#!/bin/bash
# One segment per live Claude Code session, for tmux's status-right.
#
# Wire it up in tmux.conf, e.g.:
#   set -g status-right '#(bash ~/.claude/claude-fleet.sh)%H:%M %d-%b-%y'
out=""
for f in ~/.claude/sessions/*.json; do
    [ -e "$f" ] || continue
    pid=$(jq -r '.pid // 0' "$f")
    kill -0 "$pid" 2>/dev/null || continue
    name=$(jq -r '.name // "?"' "$f")
    status=$(jq -r '.status // ""' "$f")
    case $status in
        busy)  dot="#[fg=green,bold]●#[default]" ;;
        wait*) dot="#[fg=red,bold]●#[default]" ;;
        *)     dot="#[fg=colour245]○#[default]" ;;
    esac
    out+="$dot ${name:0:12}  "
done
printf '%s' "$out"
