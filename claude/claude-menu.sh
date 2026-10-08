#!/bin/bash
# Pops a tmux menu listing every live Claude Code session; picking one jumps
# straight to its window.
#
# Wire it up in tmux.conf, e.g.:
#   bind BSpace run-shell -b "bash ~/.claude/claude-menu.sh"
args=(-T "Claude sessions")
i=1
for f in ~/.claude/sessions/*.json; do
    [ -e "$f" ] || continue
    pid=$(jq -r '.pid // 0' "$f")
    kill -0 "$pid" 2>/dev/null || continue
    name=$(jq -r '.name // "?"' "$f")
    status=$(jq -r '.status // ""' "$f")
    tmuxloc=$(jq -r '.tmux // ""' "$f")
    case $status in
        busy)  dot="#[fg=green,bold]●#[default]" ;;
        wait*) dot="#[fg=red,bold]●#[default]" ;;
        *)     dot="#[fg=colour245]○#[default]" ;;
    esac
    # an entry with no tmux location shows dimmed and cannot be picked
    # (e.g. a session started outside tmux)
    cmd=""
    if [ -n "$tmuxloc" ]; then
        sess=${tmuxloc%%:*}
        t=${tmuxloc#*:}
        win=${t%.*}
        cmd="switch-client -t '$sess' ; select-window -t '$sess:$win'"
    fi
    args+=("$dot $name" "$i" "$cmd")
    i=$((i+1))
done
tmux display-menu "${args[@]}"
