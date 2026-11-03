--- Just a simple script to reset the timer for testing or if something goes wrong with the ks_time_tracker_background script. 
reaper.SetProjExtState(0, "TimeTracker", "total_seconds", "0")
reaper.SetProjExtState(0, "TimeTracker", "start_date", os.date("%Y-%m-%d"))