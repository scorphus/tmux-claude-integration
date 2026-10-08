-- Adds a menubar item with a checkbox to mute claude-announce.sh's sound and
-- speech (the tmux flag/flash and the on-screen overlay stay on either way).
-- Paste this into your Hammerspoon init.lua, or merge the menu entry into an
-- existing hs.menubar item of your own.
--
-- Requires: require("hs.ipc") somewhere in your init.lua, so `hs -c` (used by
-- claude-announce.sh to show the overlay) can reach a running Hammerspoon.

local announceMuteFlag = os.getenv("HOME") .. "/.claude/announce-muted"

local function announcementsMuted()
  return hs.fs.attributes(announceMuteFlag) ~= nil
end

claudeAnnounceMenu = hs.menubar.new()

local function refreshClaudeAnnounceMenuTitle()
  claudeAnnounceMenu:setTitle(announcementsMuted() and "🔕" or "🔔")
end

claudeAnnounceMenu:setMenu(function()
  return {
    {
      title = "Mute Claude announcements",
      checked = announcementsMuted(),
      fn = function()
        if announcementsMuted() then
          os.remove(announceMuteFlag)
        else
          io.open(announceMuteFlag, "w"):close()
        end
        refreshClaudeAnnounceMenuTitle()
      end,
    },
  }
end)
refreshClaudeAnnounceMenuTitle()
