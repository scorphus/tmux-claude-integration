# tmux-claude-integration

Know when a [Claude Code](https://claude.com/claude-code) session finishes or
needs you, without staring at the terminal: a flagged tmux window, a sound, a
spoken one-liner, an on-screen overlay, and — if you run several sessions at
once — a status-bar readout and a jump menu.

It leans on two things every Claude Code install already has:

- **hooks** (`Stop`, `Notification`) — commands Claude Code runs when a turn
  ends or a session needs your attention.
- **the session registry** (`~/.claude/sessions/*.json`) — one JSON file per
  running session, naming its pid, display name, status, and (when started
  inside tmux) its pane.

Everything here is shell and Lua glue over those two things. No daemon, no
extra dependency beyond `jq`, `tmux`, and (optionally) [Hammerspoon](https://www.hammerspoon.org/).

## What you get

- **`claude-announce.sh`** — the core piece. Wired to the `Stop` and
  `Notification` hooks, it, for the session that just fired:
  - rings the bell on that session's tmux window (tmux then styles it per
    `window-status-bell-style` until you visit it) and blinks the window tab
    red for a couple of seconds, so you notice it even across windows;
  - plays a sound (`Hero` when done, `Basso` when waiting on you) and speaks
    a short sentence with `say`, naming the session and — when waiting —
    whether it's a permission prompt or you've simply gone idle;
  - shows the same sentence as an on-screen overlay via Hammerspoon, so it's
    still visible if you missed the sound.
- **`claude-fleet.sh`** — a tmux `status-right` segment listing every live
  Claude Code session with a colored dot (green = busy, red = waiting, grey =
  idle).
- **`claude-menu.sh`** — a tmux menu (bound to `prefix+Backspace` in the
  snippet below) listing the same sessions; pick one to jump straight to its
  window.
- **`hammerspoon-mute-toggle.lua`** — a menubar checkbox to mute the sound
  and speech (the window flag/flash and the overlay stay on), for when
  you're on a call.

## How it fits together

```
Claude Code session          claude-announce.sh                 you
       │  Stop / Notification    │
       ├────────────────────────►│
       │                         │ look up the session's tmux pane
       │                         │ in ~/.claude/sessions/*.json
       │                         ├─► tmux: ring the bell, flash the window
       │                         ├─► afplay: Hero / Basso
       │                         ├─► hs -c: Hammerspoon overlay
       │                         └─► say: spoken summary
```

`claude-fleet.sh` and `claude-menu.sh` don't hook into anything — they just
read the same registry on demand, whenever tmux redraws the status bar or you
press the menu's key bind.

## Setup

Requires `jq` (`brew install jq`) and tmux. Hammerspoon is optional — without
it, the hook still rings the bell, flashes the window, plays the sound, and
speaks; you just lose the on-screen overlay and the mute toggle (drop the
`hs -c ...` line in `claude/claude-announce.sh` if you don't want Hammerspoon
at all).

1. **Link the scripts:**

   ```
   ./install.sh
   ```

   This symlinks `claude/*.sh` into `~/.claude/`. Re-run it any time you pull
   changes — it just re-links, it won't duplicate anything.

2. **Wire the hooks.** Merge `settings.hooks.json`'s `"hooks"` entries into
   your `~/.claude/settings.json` (global, so it covers every project) or a
   project's `.claude/settings.json`. If you already have other hooks
   configured, add these entries alongside them rather than replacing the
   `"hooks"` key outright.

3. **Add the tmux lines.** Append `tmux.conf.snippet`'s contents to your
   `tmux.conf` (adjust the `prefix+A` / `prefix+Backspace` binds if either is
   already taken in your config), then reload (`tmux source ~/.tmux.conf` or
   restart tmux).

4. **(optional) Add the mute toggle.** Paste `hammerspoon-mute-toggle.lua`
   into your Hammerspoon `init.lua` (or fold its menu entry into one of your
   own `hs.menubar` items), then reload Hammerspoon config. It also needs
   `require("hs.ipc")` loaded somewhere in your config — that's what lets the
   `hs` command-line tool talk to a running Hammerspoon; without it the
   overlay call in `claude-announce.sh` silently does nothing.

That's it — the next Claude Code turn that stops or waits on you should ring,
flash, and announce itself.

## Customizing

- **Sounds**: any name under `/System/Library/Sounds/` works (`afplay -v`
  lists volume options too). Change the `sound=Hero` / `sound=Basso` lines in
  `claude-announce.sh`.
- **Speech rate/voice**: `say` takes `-r <words-per-minute>` and
  `-v <voice>` (`say -v '?'` lists installed voices). Add either to the final
  `say "$msg"` line.
- **Flash color/duration**: the `bg=red,fg=white,bold` style and the
  `for i in 1 2 3 4 5; ... sleep 0.25` loop in `claude-announce.sh` are both
  plain tmux/shell — change them freely.
- **What counts as "waiting"**: the `Notification` hook fires for several
  reasons (`permission_prompt`, `idle_prompt`, MCP elicitations, background
  agent events, …); `claude-announce.sh` only special-cases the first two and
  falls back to a generic line for the rest. See Claude Code's
  [hooks reference](https://code.claude.com/docs/en/hooks.md) for the full
  list of notification types if you want to add more cases.

## Don't use tmux? (even though you should)

Most of this still works. The sound, the speech, the Hammerspoon overlay, and
the mute flag don't touch tmux at all — you get the full announcement either
way.

What changes: `claude-announce.sh` checks `$TMUX`. Inside tmux, it resolves
the session's pane and does the bell-plus-colored-flash routine described
above. Outside tmux, it instead finds its own controlling tty directly
(`ps -o tty= -p $$`) and rings the bell there — so whatever terminal you're
actually in (Ghostty, iTerm2, Terminal.app, …) flags its own tab the way it
knows how, if it's configured to react to a bell at all. Ghostty, for
instance, gates this behind its `bell-features` setting.

The three features that stay tmux-only, with no real equivalent elsewhere:
the colored window flash (there's no "flash this tab" API outside tmux to
target), the fleet widget in `status-right`, and the session-jump menu. A
non-tmux session simply won't show up for those — it still gets everything
else.

## Don't use Hammerspoon? (even though you should)

The overlay and the mute toggle are the only two things Hammerspoon buys
you; everything else (bell, flash, sound, speech, the fleet widget, the
session menu) works without it. Skip step 4 in Setup and the `hs -c ...`
line in `claude-announce.sh` just does nothing — no error, no dependency.

Flipping the mute switch without Hammerspoon is still one line, since the
"switch" is only ever the presence of `~/.claude/announce-muted`:

- **A tmux key bind** (if you're using tmux anyway):
  ```
  bind M run-shell "touch ~/.claude/announce-muted"
  bind U run-shell "rm -f ~/.claude/announce-muted"
  ```
- **A couple of shell aliases/functions**, e.g. `claude-mute` / `claude-unmute`
  in your shell rc.
- **[xbar](https://xbarapp.com)** or its actively maintained fork
  **[SwiftBar](https://swiftbar.app)** — both are lighter-weight menu-bar
  hosts than Hammerspoon; a short script with a clickable menu item gives you
  the same checkbox.
- **The macOS Shortcuts app** — a shortcut whose one action toggles that
  file, bound to a keyboard shortcut via System Settings → Keyboard →
  Shortcuts, or run from Spotlight.

## Notes

- Inside tmux, the window-jump and bell-flag logic resolves the pane from
  the hook's own `TMUX_PANE` environment variable first, falling back to the
  session registry's recorded pane — so it still finds the right window even
  if you've since moved it.
- Everything here only ever touches your own machine: the session registry,
  tmux, `afplay`/`say`, and (if present) your own Hammerspoon. Nothing is
  sent anywhere.

## License

Code in this repository is distributed under the terms of the BSD 3-Clause
License (BSD-3-Clause).

See [LICENSE](LICENSE) for details.
