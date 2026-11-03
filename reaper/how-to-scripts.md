# Guide on scripts

Here is how to add new script. Like any script in general:

1. Open REAPER.
2. Put the script file in REAPER’s Scripts folder. Go to Options → Show REAPER resource path in explorer/finder, open the Scripts folder, and copy the script file (.lua, .eel or .py) into it. It can also stay anywhere else on your computer, but the Scripts folder keeps things tidy.
3. Open the action list with Actions → Show action list.
4. Click New action → Load ReaScript...
5. Select the script file and click Open. The script is now registered in the action list as Script: filename.lua.
6. Run it. Search for the script’s name in the action list, select it, and click Run.



# Project Time Tracker: Installation

The tracker has two scripts:
- ks_time_tracker_background.lua runs invisibly and counts the time for every open project tab.
- ks_time_tracker_display.lua opens a small window showing the time for the current project.

## Setup
1. Open REAPER.
2. Install the SWS extension (needed to start the tracker automatically with REAPER). If you already have it, check for an Extensions menu in the top menu bar. If not, download it from https://www.sws-extension.org/, install it, and restart REAPER.
3. Put the scripts in REAPER’s Scripts folder. Go to Options → Show REAPER resource path in explorer/finder, open the Scripts folder, and copy both .lua files into it.
4. Open the action list with Actions → Show action list.
5. Load the scripts. Click New action → Load ReaScript..., select both .lua files, and click Open. They now appear in the action list.
6. Start the tracker automatically with REAPER:
    - In the action list, search for ks_time_tracker_background and select it.
    - Right-click it and choose Copy selected action command ID.
    - Go to Extensions → Startup actions → Set global startup action..., paste the command ID, and confirm.
7. Start the tracker now. With the background script still selected, click Run. Nothing appears on screen, but tracking has started. (After a REAPER restart this happens automatically.)
8. Open the display window. Search for ks_time_tracker_display, select it, and click Run. A small window shows the time spent and the start date of the current project. You can dock it anywhere.

## Good to know: 
- Time is stored inside each project file, so each project keeps its own total. Save your project to keep the latest time.
- All open project tabs are tracked at the same time, not just the active one.
- The display refreshes continuously. The saved value in the project updates every 10 seconds.
- To show the display with one click, add it to a toolbar: right-click a toolbar → Customize toolbar → Add....

## Troubleshooting:
- The time stays at 000:00:00 or doesn’t move: the background script isn’t running. Run it from the action list (step 7).
- The time is wrong or jumps: two copies of the background script may be running. Run Terminate running scripts from the action list, or restart REAPER.