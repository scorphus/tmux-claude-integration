#!/bin/bash
# Symlinks the claude-*.sh scripts into ~/.claude/. Everything else (the tmux
# lines, the Hammerspoon snippet, the hook wiring in settings.json) touches
# files that already hold your own config, so those stay manual — see the
# README.
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p ~/.claude
for f in claude/*.sh; do
    ln -sf "$(pwd)/$f" ~/.claude/"$(basename "$f")"
    echo "linked ~/.claude/$(basename "$f")"
done

cat <<'EOF'

Scripts linked. Three manual steps left — see README.md for details:
  1. Append tmux.conf.snippet's lines to your tmux.conf.
  2. Merge settings.hooks.json's "hooks" entries into ~/.claude/settings.json.
  3. (optional) Paste hammerspoon-mute-toggle.lua into your Hammerspoon init.lua.
EOF
