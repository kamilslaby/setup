--[[
 * Description: Project Time Tracker - display window for the current project.
                In order to work it requires ks_time_tracker_background.lua to be running in the background.
 * Author:      Kamil Slaby / Superior
 * REAPER:      6.0+
 * Extensions:  none required
--]]

local SECTION      = "TimeTracker"
local LIVE_SECTION = "KS_TimeTracker_Live" -- published by the background script

local function format_time(seconds)
  local total = math.floor(seconds)
  return string.format("%03d:%02d:%02d", total // 3600, (total % 3600) // 60, total % 60)
end

local function get_data()
  local proj = reaper.EnumProjects(-1)
  local _, stored = reaper.GetProjExtState(0, SECTION, "total_seconds")
  local _, date   = reaper.GetProjExtState(0, SECTION, "start_date")
  local live      = tonumber(reaper.GetExtState(LIVE_SECTION, tostring(proj))) or 0
  -- live value is ahead of the stored one between saves; stored wins if the background script isn't running
  return math.max(tonumber(stored) or 0, live), (date ~= "" and date or "unknown")
end

local function main_loop()
  local total, date = get_data()

  gfx.set(0.9, 0.9, 0.9, 1)
  gfx.setfont(1, "Arial", 14)
  gfx.x, gfx.y = 10, 8
  gfx.drawstr("Time spent: " .. format_time(total))
  gfx.x, gfx.y = 10, 26
  gfx.drawstr("Project started: " .. date)

  gfx.update()
  if gfx.getchar() >= 0 then
    reaper.defer(main_loop)
  end
end

gfx.clear = 0x202020 -- background is cleared every update (0xBBGGRR), otherwise text smears
gfx.init("Project Time", 240, 50, 0, 100, 100)
reaper.atexit(gfx.quit)
main_loop()