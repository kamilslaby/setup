--[[
 * Description: Project Time Tracker in background background.
                Run once at REAPER startup (e.g. via SWS startup action or __startup.lua).
                Tracks every open project tab independently and stores the total
                in each project's ExtState. Handles tab close/open and same-tab
                project swaps (File > Open into an existing tab).
 * Author:      Kamil Slaby / Superior
 * REAPER:      6.0+
 * Extensions:  none required
--]]

local SECTION       = "TimeTracker"
local LIVE_SECTION  = "KS_TimeTracker_Live" -- non-persistent, read by the display script
local SAVE_INTERVAL = 10   -- seconds between writes into the project
local POLL_INTERVAL = 0.5  -- seconds between tracker updates
local MAX_GAP       = 30   -- ignore gaps longer than this (system sleep, long modal dialogs)

local tracked   = {} -- [proj] = { path, base, pending, last_tick, last_save }
local last_poll = 0

local function read_total(proj)
  local _, v = reaper.GetProjExtState(proj, SECTION, "total_seconds")
  return tonumber(v) or 0
end

local function ensure_start_date(proj)
  local _, date = reaper.GetProjExtState(proj, SECTION, "start_date")
  if date == "" then
    reaper.SetProjExtState(proj, SECTION, "start_date", os.date("%Y-%m-%d"))
  end
end

local function track(proj, path, now)
  ensure_start_date(proj)
  tracked[proj] = {
    path      = path,
    base      = read_total(proj), -- last known stored total (used for live display only)
    pending   = 0,                -- seconds accrued since the last write
    last_tick = now,
    last_save = now,
  }
end

local function untrack(proj)
  reaper.DeleteExtState(LIVE_SECTION, tostring(proj), false)
  tracked[proj] = nil
end

-- Writes pending time on top of whatever is currently stored in the project.
local function save(proj, data)
  local total = read_total(proj) + data.pending
  reaper.SetProjExtState(proj, SECTION, "total_seconds", string.format("%.3f", total))
  data.base, data.pending = total, 0
end

local function poll()
  local now = reaper.time_precise()

  -- 1. Drop closed tabs before their pointers can be reused.
  for proj in pairs(tracked) do
    if not reaper.ValidatePtr(proj, "ReaProject*") then
      untrack(proj)
    end
  end

  -- 2. Discover new tabs and same-tab project swaps.
  local i = 0
  while true do
    local proj, path = reaper.EnumProjects(i)
    if not proj then break end
    path = path or ""

    local data = tracked[proj]
    if not data then
      track(proj, path, now)
    elseif data.path ~= path then
      if data.path == "" then
        -- Unsaved project got a filename (Save As): same project, keep counting.
        data.path = path
        data.base = read_total(proj)
        ensure_start_date(proj)
      else
        -- Different project loaded into this tab. Time accrued since the last write
        -- belonged to the old project, which is no longer reachable: discard it.
        track(proj, path, now)
      end
    end
    i = i + 1
  end

  -- 3. Accrue time, save periodically, publish live value.
  for proj, data in pairs(tracked) do
    local dt = now - data.last_tick
    data.last_tick = now
    if dt > 0 and dt <= MAX_GAP then
      data.pending = data.pending + dt
    end

    if now - data.last_save >= SAVE_INTERVAL then
      save(proj, data)
      data.last_save = now
    end

    reaper.SetExtState(LIVE_SECTION, tostring(proj), string.format("%.3f", data.base + data.pending), false)
  end
end

local function main_loop()
  if reaper.time_precise() - last_poll >= POLL_INTERVAL then
    last_poll = reaper.time_precise()
    poll()
  end
  reaper.defer(main_loop)
end

reaper.atexit(function()
  for proj, data in pairs(tracked) do
    if reaper.ValidatePtr(proj, "ReaProject*") then
      save(proj, data)
    end
    reaper.DeleteExtState(LIVE_SECTION, tostring(proj), false)
  end
end)

main_loop()