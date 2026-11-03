--[[
 * ReaScript Name: Humanize Selected Drum Items (Timing / Volume / Pitch)
 * Description:    Randomizes position, clip volume and pitch of selected
 *                  media items to add natural human "feel" to drum tracks.
 * Author:          Kamil Slaby / Superior
 * REAPER:          6.0+
 * Extensions:      none required
--]]

-------------------------------------------------------------------
-- USER SETTINGS
-------------------------------------------------------------------
local MAX_TIME_MS    = 12      -- max timing offset in milliseconds (+/-)
local MAX_VOL_DB     = 1.5     -- max clip volume change in dB (+/-)
local MAX_PITCH_ST   = 0.05    -- max pitch change in semitones (+/-)
local GROUP_TOL_SEC  = 0.001   -- items starting within 1 ms are treated
                                -- as "the same hit" and moved together

-------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------

-- Weighted random in range [-maxVal, +maxVal].
-- Squaring a uniform [0,1] value biases results toward 0, so small
-- (subtle) changes happen far more often than large ones.
local function weightedRandom(maxVal)
  local r = math.random()
  r = r * r
  local sign = (math.random() < 0.5) and -1 or 1
  return sign * r * maxVal
end

local function dbToLinear(db)
  return 10 ^ (db / 20)
end

-------------------------------------------------------------------
-- MAIN
-------------------------------------------------------------------

local function main()
  local itemCount = reaper.CountSelectedMediaItems(0)
  if itemCount == 0 then
    reaper.ShowMessageBox("No media items selected.", "Humanize Drum Items", 0)
    return
  end

  math.randomseed(math.floor(reaper.time_precise() * 1000))

  -- Collect selected items with their current position
  local items = {}
  for i = 0, itemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    items[#items + 1] = { item = item, pos = pos }
  end

  -- Sort by position so items starting at (nearly) the same time
  -- end up adjacent, letting us group them in one pass
  table.sort(items, function(a, b) return a.pos < b.pos end)

  -- Group items that start together (layered samples: kick+sub,
  -- snare top+bottom, etc.) so timing offset moves them as one
  local groups = {}
  local currentGroup, lastPos = nil, nil
  for _, entry in ipairs(items) do
    if not currentGroup or math.abs(entry.pos - lastPos) > GROUP_TOL_SEC then
      currentGroup = {}
      groups[#groups + 1] = currentGroup
    end
    currentGroup[#currentGroup + 1] = entry
    lastPos = entry.pos
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  for _, group in ipairs(groups) do
    -- One shared timing offset per group -> layered hits stay locked together
    local timeOffsetSec = weightedRandom(MAX_TIME_MS) / 1000

    for _, entry in ipairs(group) do
      local item = entry.item
      local newPos = entry.pos + timeOffsetSec
      if newPos < 0 then newPos = 0 end
      reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPos)

      local take = reaper.GetActiveTake(item)
      if take and not reaper.TakeIsMIDI(take) then

        -- Volume: independent per item
        local volDb = weightedRandom(MAX_VOL_DB)
        local volLinearMult = dbToLinear(volDb)
        local curVol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
        reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", curVol * volLinearMult)

        -- Pitch: independent per item
        local pitchOffset = weightedRandom(MAX_PITCH_ST)
        local curPitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
        reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", curPitch + pitchOffset)
      end
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Humanize selected drum items (timing/volume/pitch)", -1)
end

main()
