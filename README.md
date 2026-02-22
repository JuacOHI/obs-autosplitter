# obs-autosplitter

  A Lua script for OBS Studio that automatically splits recordings at a configurable time interval.

  ## Features

  - Split recordings at any interval (hours, minutes, seconds)
  - Pause-aware: the timer pauses when the recording is paused
  - Event-driven architecture using `obs_frontend_add_event_callback` (no polling)
  - Clean lifecycle management (`script_load` / `script_unload`)
  - Enabled by default with a 10-minute interval

  ## Installation

  1. Download `autosplitter.lua`
  2. In OBS Studio, go to **Tools > Scripts**
  3. Click the **+** button and select the file

  ## Configuration

  | Setting   | Description              | Range    |
  |-----------|--------------------------|----------|
  | Enabled   | Enable/disable splitting | On / Off |
  | Hours     | Interval hours           | 0 - 240  |
  | Minutes   | Interval minutes         | 0 - 60   |
  | Seconds   | Interval seconds         | 0 - 60   |

  ## Changes from the original

  This is a modernized rewrite of [lhns/obs-autosplitter](https://github.com/lhns/obs-autosplitter). Key changes:

  - **Polling replaced with event callbacks** — the original polled recording state every 200ms; this version reacts to OBS frontend events directly     
  - **Proper lifecycle management** — added `script_load` and `script_unload` to register/clean up callbacks and timers
  - **Pause support** — the split timer pauses and resumes with the recording
  - **All helpers are local** — no global namespace pollution
  - **Dead code removed** — unused `delay`, `delayUntil`, `timerWhile` functions eliminated

  ## License

  [Apache 2.0](LICENSE)

  Originally created by [lhns](https://github.com/lhns).
