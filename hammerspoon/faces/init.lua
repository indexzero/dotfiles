--- Faces: Fast virtual workspaces for Hammerspoon
--- https://github.com/indexzero/dotfiles/tree/main/hammerspoon/faces

local Faces = {
  _VERSION = "1.0.4",
  _DESCRIPTION = "Fast virtual workspaces for Hammerspoon",
}

-- State: only primitive data, no window object references
local faces = {}                -- Ordered list of face names
local currentFace = nil         -- Current face name
local windows = {}              -- windowId -> { face = string, frame = {x,y,w,h} or nil }
local windowFilter = nil        -- hs.window.filter instance
local hotkeys = {}              -- Bound hotkeys for cleanup
local saveTimer = nil           -- Debounce timer for persistence
local sleepWatcher = nil        -- hs.caffeinate.watcher instance

-- Constants
local OFFSCREEN_X = -10000
local STATE_FILE = hs.configdir .. "/faces-state.json"
local DEBUG_LOG = hs.configdir .. "/faces-debug.log"
local DEBOUNCE_SECONDS = 1
local DEBUG = false

-- Debug logging to file (only when DEBUG is true)
local function log(msg)
  if not DEBUG then return end
  local file = io.open(DEBUG_LOG, "a")
  if file then
    file:write(os.date("[%H:%M:%S] ") .. msg .. "\n")
    file:close()
  end
end

-- Clear log on load if debugging
if DEBUG then
  local file = io.open(DEBUG_LOG, "w")
  if file then file:close() end
end

--------------------------------------------------------------------------------
-- Persistence (debounced)
--------------------------------------------------------------------------------

local function saveStateNow()
  local state = {
    version = Faces._VERSION,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    currentFace = currentFace,
    faces = faces,
    windows = {},
  }

  -- Convert window IDs to strings for JSON (Lua numbers as keys don't serialize well)
  for id, entry in pairs(windows) do
    state.windows[tostring(id)] = {
      id = id,
      face = entry.face,
      frame = entry.frame,
    }
  end

  local json = hs.json.encode(state, true)  -- pretty print
  local file = io.open(STATE_FILE, "w")
  if file then
    file:write(json)
    file:close()
  end
end

local function saveStateDebounced()
  if saveTimer then
    saveTimer:stop()
  end
  saveTimer = hs.timer.doAfter(DEBOUNCE_SECONDS, saveStateNow)
end

--------------------------------------------------------------------------------
-- Private helpers
--------------------------------------------------------------------------------

local function isOffscreen(frame)
  if not frame then return false end
  return frame.x < 0
end

--- Build id -> window lookup from a single allWindows() call
local function buildWindowMap()
  local map = {}
  for _, w in ipairs(hs.window.allWindows()) do
    local id = w:id()
    if id then map[id] = w end
  end
  return map
end

--- Hide a window (takes window object directly, not ID)
local function hideWindowObj(window, entry)
  if not window or not entry then return end

  local frame = window:frame()
  if not frame then return end

  if not isOffscreen(frame) then
    -- Store frame as plain table (primitives only)
    entry.frame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
    window:setTopLeft({ x = OFFSCREEN_X, y = frame.y })
  end
end

--- Show a window (takes window object directly, not ID)
local function showWindowObj(window, entry, id)
  if not window then log("showWindowObj: no window for id " .. tostring(id)) return end
  if not entry then log("showWindowObj: no entry for id " .. tostring(id)) return end

  local currentFrame = window:frame()
  if not currentFrame then log("showWindowObj: no frame for id " .. tostring(id)) return end

  log("showWindowObj id=" .. tostring(id) .. " x=" .. tostring(currentFrame.x) .. " offscreen=" .. tostring(isOffscreen(currentFrame)))

  if isOffscreen(currentFrame) then
    if entry.frame then
      log("showWindowObj: restoring to x=" .. tostring(entry.frame.x) .. " y=" .. tostring(entry.frame.y))
      window:setTopLeft({ x = entry.frame.x, y = entry.frame.y })
      local afterFrame = window:frame()
      log("showWindowObj: AFTER setTopLeft x=" .. tostring(afterFrame and afterFrame.x or "nil"))
    else
      -- No saved frame, center on screen
      log("showWindowObj: no saved frame, centering")
      local screen = hs.screen.mainScreen():frame()
      window:setTopLeft({
        x = (screen.w - currentFrame.w) / 2,
        y = (screen.h - currentFrame.h) / 2,
      })
      local afterFrame = window:frame()
      log("showWindowObj: AFTER centering x=" .. tostring(afterFrame and afterFrame.x or "nil"))
    end
  end
end

--- Re-enforce current face after wake (re-hide windows not on current face)
local function enforceCurrentFace()
  log("enforceCurrentFace called for face: " .. tostring(currentFace))
  local winMap = buildWindowMap()
  local hiddenCount = 0

  for id, entry in pairs(windows) do
    if entry.face ~= currentFace then
      local window = winMap[id]
      if window then
        local frame = window:frame()
        if frame and not isOffscreen(frame) then
          -- Window should be hidden but isn't - re-hide it
          log("enforceCurrentFace: re-hiding window " .. tostring(id) .. " (face: " .. entry.face .. ")")
          hideWindowObj(window, entry)
          hiddenCount = hiddenCount + 1
        end
      end
    end
  end

  if hiddenCount > 0 then
    log("enforceCurrentFace: re-hid " .. hiddenCount .. " windows")
    saveStateDebounced()
  end
end

local function trackWindow(id, faceName, frame)
  if not id then return end
  windows[id] = {
    face = faceName,
    frame = frame and { x = frame.x, y = frame.y, w = frame.w, h = frame.h } or nil,
  }
  saveStateDebounced()
end

local function untrackWindow(id)
  windows[id] = nil
  saveStateDebounced()
end

local function setWindowFace(id, faceName)
  if windows[id] then
    windows[id].face = faceName
    saveStateDebounced()
  end
end

--------------------------------------------------------------------------------
-- Window filter callbacks
--------------------------------------------------------------------------------

local function onWindowCreated(window)
  if not window:isStandard() then return end
  local id = window:id()
  if id then
    trackWindow(id, currentFace, window:frame())
  end
end

local function onWindowDestroyed(window)
  local id = window:id()
  if id then
    untrackWindow(id)
  end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Initialize Faces with configuration
--- @param config table { faces: string[], startFace: string }
function Faces.setup(config)
  config = config or {}
  faces = config.faces or { "1", "2", "3" }
  currentFace = config.startFace or faces[1]

  -- Disable window animations
  hs.window.animationDuration = 0

  -- Track all existing windows on current face (store primitives only)
  -- Skip offscreen positions - don't save corrupted state from previous runs
  for _, window in ipairs(hs.window.allWindows()) do
    if window:isStandard() then
      local id = window:id()
      local frame = window:frame()
      if id and frame then
        -- Only save frame if window is on-screen (x >= 0)
        local safeFrame = nil
        if frame.x >= 0 then
          safeFrame = frame
        end
        trackWindow(id, currentFace, safeFrame)
      end
    end
  end

  -- Subscribe to window events (minimal subscriptions)
  windowFilter = hs.window.filter.new()
    :setDefaultFilter({})
    :setOverrideFilter({
      allowRoles = { "AXStandardWindow" },
    })

  windowFilter:subscribe(hs.window.filter.windowCreated, onWindowCreated)
  windowFilter:subscribe(hs.window.filter.windowDestroyed, onWindowDestroyed)

  -- Watch for wake events to re-enforce face state
  sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
      log("systemDidWake detected")
      -- Delay slightly to let macOS finish restoring windows
      hs.timer.doAfter(1, enforceCurrentFace)
    end
  end)
  sleepWatcher:start()

  -- Save initial state
  saveStateNow()

  return Faces
end

--- Switch to a face
--- @param faceName string
function Faces.switchTo(faceName)
  log("switchTo called: " .. tostring(faceName) .. " (current: " .. tostring(currentFace) .. ")")
  if not faceName then return end
  if faceName == currentFace then return end

  -- Query all windows ONCE, build lookup table
  local winMap = buildWindowMap()

  -- Hide windows on current face, show windows on target face
  for id, entry in pairs(windows) do
    local window = winMap[id]
    if window then
      if entry.face == currentFace then
        hideWindowObj(window, entry)
      elseif entry.face == faceName then
        showWindowObj(window, entry, id)
      end
    else
      log("switchTo: window not found in winMap for id " .. tostring(id))
    end
  end

  currentFace = faceName
  saveStateDebounced()

  -- Focus topmost visible window on new face
  for _, window in ipairs(hs.window.orderedWindows()) do
    local id = window:id()
    local entry = windows[id]
    if entry and entry.face == currentFace then
      local frame = window:frame()
      if frame and not isOffscreen(frame) then
        window:focus()
        break
      end
    end
  end
end

--- Move focused window to a face
--- @param faceName string
--- @param follow boolean (optional) Switch to that face after moving
function Faces.moveWindow(faceName, follow)
  local window = hs.window.focusedWindow()
  if not window then return end

  local id = window:id()
  if not id or not windows[id] then return end

  setWindowFace(id, faceName)

  if follow then
    Faces.switchTo(faceName)
  else
    -- Hide the window (we already have a valid window object)
    hideWindowObj(window, windows[id])
    saveStateDebounced()
    -- Focus next window on current face
    for _, w in ipairs(hs.window.orderedWindows()) do
      local wid = w:id()
      if wid ~= id and windows[wid] and windows[wid].face == currentFace then
        local frame = w:frame()
        if frame and not isOffscreen(frame) then
          w:focus()
          break
        end
      end
    end
  end
end

--- Get current face name
--- @return string
function Faces.currentFace()
  return currentFace
end

--- Get all faces with window counts
--- @return table { faceName: { count: number, current: boolean } }
function Faces.list()
  local result = {}

  for _, face in ipairs(faces) do
    result[face] = { count = 0, current = (face == currentFace) }
  end

  for _, entry in pairs(windows) do
    if result[entry.face] then
      result[entry.face].count = result[entry.face].count + 1
    end
  end

  return result
end

--- Get ordered face names
--- @return string[]
function Faces.faces()
  return faces
end

--------------------------------------------------------------------------------
-- Keybinding helpers
--------------------------------------------------------------------------------

--- Bind hotkeys to switch faces (modifier + face name)
--- @param modifier table e.g., { "alt" }
function Faces.bindSwitchFace(modifier)
  for _, face in ipairs(faces) do
    local hk = hs.hotkey.bind(modifier, face, function()
      Faces.switchTo(face)
    end)
    table.insert(hotkeys, hk)
  end
  return Faces
end

--- Bind hotkeys to move window to face (modifier + face name)
--- @param modifier table e.g., { "cmd", "shift" }
--- @param follow boolean (optional) Switch to face after moving
function Faces.bindMoveFace(modifier, follow)
  for _, face in ipairs(faces) do
    local hk = hs.hotkey.bind(modifier, face, function()
      Faces.moveWindow(face, follow)
    end)
    table.insert(hotkeys, hk)
  end
  return Faces
end

local function currentIndex()
  for i, face in ipairs(faces) do
    if face == currentFace then return i end
  end
  return 1
end

--- Bind hotkey to cycle to next face
--- @param modifier table e.g., { "ctrl" }
--- @param key string e.g., "space"
function Faces.bindCycleNext(modifier, key)
  local hk = hs.hotkey.bind(modifier, key, function()
    local idx = currentIndex() % #faces + 1
    Faces.switchTo(faces[idx])
  end)
  table.insert(hotkeys, hk)
  return Faces
end

--- Bind hotkey to cycle to previous face
--- @param modifier table e.g., { "ctrl", "shift" }
--- @param key string e.g., "space"
function Faces.bindCyclePrev(modifier, key)
  local hk = hs.hotkey.bind(modifier, key, function()
    local idx = (currentIndex() - 2) % #faces + 1
    Faces.switchTo(faces[idx])
  end)
  table.insert(hotkeys, hk)
  return Faces
end

--- Bind escape hatch to restore all windows
--- @param modifier table e.g., { "ctrl", "alt", "shift" }
--- @param key string e.g., "h"
function Faces.bindEscapeHatch(modifier, key)
  local hk = hs.hotkey.bind(modifier, key, function()
    Faces.showAll()
  end)
  table.insert(hotkeys, hk)
  return Faces
end

--- Show all windows (escape hatch)
function Faces.showAll()
  -- Query all windows ONCE
  local winMap = buildWindowMap()

  local restored = 0
  local total = 0
  for id, entry in pairs(windows) do
    total = total + 1
    local window = winMap[id]
    if window and entry.frame then
      window:setTopLeft({ x = entry.frame.x, y = entry.frame.y })
      restored = restored + 1
    end
  end
  hs.alert.show("Faces: Restored " .. restored .. "/" .. total .. " windows")
  saveStateNow()  -- Immediate save after escape hatch
end

--- Unbind all hotkeys (for cleanup/reload)
function Faces.unbindAll()
  for _, hk in ipairs(hotkeys) do
    hk:delete()
  end
  hotkeys = {}
  return Faces
end

--------------------------------------------------------------------------------
-- Cleanup
--------------------------------------------------------------------------------

--- Stop Faces and clean up resources
function Faces.stop()
  Faces.unbindAll()

  if windowFilter then
    windowFilter:unsubscribeAll()
    windowFilter = nil
  end

  if sleepWatcher then
    sleepWatcher:stop()
    sleepWatcher = nil
  end

  -- Show all hidden windows before stopping
  Faces.showAll()

  windows = {}
  currentFace = nil
end

return Faces
