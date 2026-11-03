-- Hammerspoon config

require("hs.ipc")

-- Reload from the command line
-- hs -c "hs.reload()"
hs.ipc.cliInstall()

-- Toggle Device Hub: activate it, or hide it when already frontmost.
local deviceHubTask
local deviceHubShown = false
local function toggleDeviceHub()
  if deviceHubTask then return end
  local focusedWorkspace = hs.execute('/opt/homebrew/bin/hyprspace list-workspaces --focused')
    :match('^[0-9]')
  if not focusedWorkspace then
    hs.alert.show('Could not determine the current workspace')
    return
  end
  local show = not deviceHubShown
  local script = show and [[
    set -euo pipefail
    workspace="$1"
    /opt/homebrew/bin/hyprspace list-windows --all \
      --format '%{window-id} %{app-bundle-id}' --json |
      /usr/bin/jq -r '.[] | select(."app-bundle-id" == "com.apple.dt.Devices") | ."window-id"' |
      while IFS= read -r window_id; do
        /opt/homebrew/bin/hyprspace move-node-to-workspace --window-id "$window_id" "$workspace" || exit 1
      done
    /usr/bin/osascript -e 'tell application id "com.apple.dt.Devices" to activate'
    window_id=$(/opt/homebrew/bin/hyprspace list-windows --all \
      --format '%{window-id} %{app-bundle-id}' --json |
      /usr/bin/jq -r 'first(.[] | select(."app-bundle-id" == "com.apple.dt.Devices") | ."window-id") // empty')
    if [ -n "$window_id" ]; then
      /opt/homebrew/bin/hyprspace focus --window-id "$window_id"
    fi
  ]] or [[
    set -euo pipefail
    workspace="$1"
    fallback=$(/opt/homebrew/bin/hyprspace list-windows --workspace "$workspace" \
      --format '%{window-id} %{app-bundle-id}' --json |
      /usr/bin/jq -r 'first(.[] | select(."app-bundle-id" != "com.apple.dt.Devices") | ."window-id") // empty')
    if [ -n "$fallback" ]; then
      /opt/homebrew/bin/hyprspace focus --window-id "$fallback"
    fi
    /usr/bin/osascript -e 'tell application "System Events" to set visible of process "Device Hub" to false'
    if [ -z "$fallback" ]; then
      /opt/homebrew/bin/hyprspace workspace "$workspace"
    fi
  ]]
  deviceHubShown = show
  deviceHubTask = hs.task.new('/bin/bash', function(code, _, stderr)
    deviceHubTask = nil
    if code ~= 0 then
      deviceHubShown = not show
      hs.alert.show('Device Hub toggle failed: ' .. stderr)
    end
  end, { '-c', script, 'device-hub-toggle', focusedWorkspace })
  if not deviceHubTask:start() then deviceHubTask = nil; deviceHubShown = not show end
end

-- Command-Tab cycles Hyprspace workspaces. Command-Option-Tab forwards to
-- Apple's app switcher. Disable with workspaceSwitcher.stop() in the console.
workspaceSwitcher = {}
do
  local state = workspaceSwitcher
  local cli = hs.fs.attributes('/opt/homebrew/bin/hyprspace') and
    '/opt/homebrew/bin/hyprspace' or '/usr/local/bin/hyprspace'
  local workspaceOrder = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' }
  local order = {}
  local apps, focused, selected = {}, '1', 1
  local active, native, nativeAlt, pending, generation = false, false, false, 0, 0
  local syntheticTag = 0x57535043
  local tagProperty = hs.eventtap.event.properties.eventSourceUserData
  local function postNative(key, down, shift)
    local modifiers = key == 'cmd' and {} or { 'cmd' }
    if shift then table.insert(modifiers, 'shift') end
    hs.eventtap.event.newKeyEvent(modifiers, key, down)
      :setProperty(tagProperty, syntheticTag):post()
  end
  local canvas, query, focusQuery, switchTask
  local logger = hs.logger.new('workspace-switcher', 'warning')

  local function hide()
    active, pending = false, 0
    generation = generation + 1
    if canvas then canvas:delete(); canvas = nil end
  end

  local function draw()
    if canvas then canvas:delete() end
    local frame = hs.mouse.getCurrentScreen():fullFrame()
    local width = math.min(680, frame.w - 40)
    local height = 64 + #order * 37
    canvas = hs.canvas.new({ x = frame.x + (frame.w - width) / 2,
      y = frame.y + math.max(30, (frame.h - height) / 2), w = width, h = height })
    canvas:level('overlay')
    canvas:behavior({ 'canJoinAllSpaces', 'fullScreenAuxiliary', 'ignoresCycle' })
    canvas:clickActivating(false)
    canvas:appendElements({ type = 'rectangle', action = 'fill',
      roundedRectRadii = { xRadius = 16, yRadius = 16 },
      fillColor = { white = 0.08, alpha = 0.96 } },
      { type = 'text', text = 'Workspaces · release ⌘ to switch · Esc to cancel',
        textSize = 16, textColor = { white = 0.85 },
        frame = { x = 20, y = 16, w = width - 40, h = 26 } })
    for i, workspace in ipairs(order) do
      local y = 54 + (i - 1) * 37
      if i == selected then
        canvas:appendElements({ type = 'rectangle', action = 'fill',
          fillColor = { red = 0.18, green = 0.38, blue = 0.65, alpha = 0.9 },
          roundedRectRadii = { xRadius = 7, yRadius = 7 },
          frame = { x = 10, y = y - 2, w = width - 20, h = 34 } })
      end
      local names = apps[workspace] or {}
      canvas:appendElements({ type = 'text',
        text = workspace .. '   ⌥' .. workspace .. '     ' ..
          (#names > 0 and table.concat(names, ' · ') or 'Empty'),
        textSize = 15, textColor = { white = i == selected and 1 or 0.7 },
        frame = { x = 22, y = y + 3, w = width - 44, h = 25 } })
    end
    canvas:show()
  end

  local function advance(delta)
    selected = ((selected - 1 + delta) % #order) + 1
  end

  local function begin(delta)
    if active then
      if query or focusQuery then pending = pending + delta else advance(delta); draw() end
      return
    end
    active, pending = true, delta
    generation = generation + 1
    local currentGeneration = generation
    -- Both queries are asynchronous: no shell or blocking work in the event tap.
    focusQuery = hs.task.new(cli, function(code, output)
      focusQuery = nil
      if code == 0 then focused = output:match('%S+') or focused end
      if not active or generation ~= currentGeneration then return end
      query = hs.task.new(cli, function(exitCode, stdout, stderr)
        query = nil
        if not active or generation ~= currentGeneration then return end
        if exitCode ~= 0 then logger.e(stderr); hide(); return end
        local ok, windows = pcall(hs.json.decode, stdout)
        if not ok or type(windows) ~= 'table' then hide(); return end
        apps = {}
        local seen = {}
        for _, window in ipairs(windows) do
          local workspace, name = window.workspace, window['app-name']
          if workspace and name then
            apps[workspace], seen[workspace] = apps[workspace] or {}, seen[workspace] or {}
            if not seen[workspace][name] then
              table.insert(apps[workspace], name)
              seen[workspace][name] = true
            end
          end
        end
        for _, names in pairs(apps) do table.sort(names) end
        order = {}
        for _, workspace in ipairs(workspaceOrder) do
          if apps[workspace] and #apps[workspace] > 0 then
            table.insert(order, workspace)
          end
        end
        if #order == 0 then hide(); return end
        -- If the current workspace is empty, start at the first/last occupied one.
        selected = pending < 0 and 1 or 0
        for i, workspace in ipairs(order) do
          if workspace == focused then selected = i; break end
        end
        advance(pending); pending = 0
        -- A quick tap still commits after the query finishes.
        if not hs.eventtap.checkKeyboardModifiers().cmd then
          local target = order[selected]
          hide()
          switchTask = hs.task.new(cli, function() switchTask = nil end,
            { 'workspace', target })
          switchTask:start()
        else draw() end
      end, { 'list-windows', '--all', '--format', '%{app-name} %{workspace}', '--json' })
      if not query:start() then query = nil; hide() end
    end, { 'list-workspaces', '--focused' })
    if not focusQuery:start() then focusQuery = nil; hide() end
  end

  state.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp, hs.eventtap.event.types.flagsChanged }, function(event)
    if event:getProperty(tagProperty) == syntheticTag then return false end
    local flags, kind, key = event:getFlags(), event:getType(), event:getKeyCode()
    if key == hs.keycodes.map.d and flags.alt and flags.shift
        and not flags.cmd and not flags.ctrl then
      if kind == hs.eventtap.event.types.keyDown then toggleDeviceHub() end
      return true
    end
    if kind == hs.eventtap.event.types.flagsChanged then
      if nativeAlt then
        if not flags.alt then
          nativeAlt = false
          postNative('cmd', false)
        end
      elseif native then
        flags.alt = nil
        event:setFlags(flags)
        if not flags.cmd then native = false end
      elseif active and not flags.cmd and not query and not focusQuery then
        local target = order[selected]
        hide()
        switchTask = hs.task.new(cli, function() switchTask = nil end, { 'workspace', target })
        switchTask:start()
      end
      return false
    end
    if key == hs.keycodes.map.tab and flags.alt and not flags.cmd and not flags.ctrl then
      if kind == hs.eventtap.event.types.keyDown then
        if not nativeAlt then
          if active then hide() end
          nativeAlt = true
          postNative('cmd', true)
        end
        postNative('tab', true, flags.shift)
      else
        postNative('tab', false, flags.shift)
      end
      return true
    end
    if nativeAlt and key == hs.keycodes.map.escape then
      if kind == hs.eventtap.event.types.keyDown then postNative('escape', true)
      else postNative('escape', false) end
      return true
    end
    if key == hs.keycodes.map.tab and flags.cmd then
      if native or flags.alt then
        if active then hide() end
        native = true
        flags.alt = nil
        event:setFlags(flags)
        return false
      end
      if kind == hs.eventtap.event.types.keyDown and not flags.ctrl then
        begin(flags.shift and -1 or 1)
        return true
      elseif kind == hs.eventtap.event.types.keyUp and active then return true end
    end
    if active and kind == hs.eventtap.event.types.keyDown and key == hs.keycodes.map.escape then
      hide()
      return true
    end
    return false
  end)
  function state.status()
    return { active = active, native = native, visible = canvas ~= nil,
      selected = order[selected], loading = query ~= nil or focusQuery ~= nil }
  end
  function state.stop()
    state.tap:stop()
    hide()
    if nativeAlt then nativeAlt = false; postNative('cmd', false) end
    if query then query:terminate(); query = nil end
    if focusQuery then focusQuery:terminate(); focusQuery = nil end
  end
  state.tap:start()
end
