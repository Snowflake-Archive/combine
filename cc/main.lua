--[[
  Snowflake Combine v2.0.0
  https://github.com/Snowflake-Software/combine
  Written by znepb

  Depends on Tortise
  https://github.com/Snowflake-Software/tortise

  --- Process Arguments ---

  --disable-remote-monitoring: Prevents this turtle from
  connecting to a websocket.

  --disable-local-monitoring: Only displays debug messages
  as prints rather than in a fancy-schmancy window.

  --reset-unsafe-exit: In the event too many unsafe exits
  have occured, this argument bypasses that and resets the
  counter.

  --debug: Enable debug messages

  --- MIT License ---

  Copyright 2024 Snowflake Software

  Permission is hereby granted, free of charge, to any person
  obtaining a copy of this software and associated documentation
  files (the "Software"), to deal in the Software without
  restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom
  the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall
  be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
  KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
  THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

----------------------
-- Argument Reading --
----------------------
local rawArgs = { ... }
local args = {}

for i, v in pairs(rawArgs) do
  if v:sub(1, 1) == "-" and (rawArgs[i + 1] == nil or rawArgs[i + 1]:sub(1, 1) == "-") then
    args[v] = true
  elseif rawArgs[i + 1] ~= nil then
    args[v] = args[i + 1]
  end
end

print("Arguments ran with:")
for i, v in pairs(args) do
  print(i, v)
end

-----------------------
-- Unsafe Exit Check --
-----------------------

if args["--reset-unsafe-exit"] == true then
  settings.unset("combine.unsafe_exits")
  settings.unset("combine.last_unsafe_exit")
  settings.save()
end

do
  local unsafeExits = settings.get("combine.unsafe_exits") or 0
  local lastUnsafeExit = settings.get("combine.last_unsafe_exit") or 0

  if lastUnsafeExit + 15 * 60 * 1000 > os.epoch("utc") and unsafeExits > 3 and args["--reset-unsafe-exit"] == nil then
    error("More than 3 unsafe exits have occured recently. The software will now abort. Run with --reset-unsafe-exit to start normally.")
  end
end

local native = term.current()

-- WS is defined here, so it can be accessed and closed in the event of an error.
local ws

local ok, err = pcall(function()
  local config = require("config")
  local warnings = {}
  local cannotOperate = false

  -- Read execution arguments from config and apply them
  for i, v in pairs(config.execArgs) do
    args[i] = v
  end

  local VERSION = "2.0.0-pre1"

  local itemRequirements = {
    [config.item.name] = { min = config.item.min, max = config.item.max }
  }

  if not config.seed.sameAsItem then
    itemRequirements[config.seed.name] = {
      min = config.seed.min,
      max = config.seed.max
    }
  end

  print("Snowflake Combine", VERSION)
  print("Initalizing, please wait.")

  ----------------------
  -- Local Monitoring --
  ----------------------
  local w, h = native.getSize()
  local messageBox = window.create(native, 1, 2, w, h - 2)

  local connected = false
  local stateText = ""
  local lastConnectionFailure = 0
  local paused = settings.get("combine.paused") or false

  local function msg(...)
    if args["--disable-local-monitoring"] then
      print(...)
      return
    end

    term.redirect(messageBox)
    print(...)
    term.redirect(native)
  end

  local function debug(...)
    if not args["--debug"] then return end

    if args["--disable-local-monitoring"] then
      print(...)
      return
    end

    term.redirect(messageBox)
    print(...)
    term.redirect(native)
  end

  -- Draws the local monitoring screen.
  local function draw()
    if args["--disable-local-monitoring"] then return end

    term.setCursorPos(2, 1)
    term.setBackgroundColor(colors.lightGray)
    term.clearLine()
    term.setTextColor(colors.black)
    term.write((os.getComputerLabel() or "Farm") .. (" | ID #" .. tostring(os.getComputerID())))

    local fuelText = "Fuel: " .. turtle.getFuelLevel()
    term.setCursorPos(w - #fuelText, 1)
    term.write(fuelText)

    term.setCursorPos(2, h)
    term.setBackgroundColor(colors.lightGray)
    term.clearLine()
    term.setTextColor(connected and colors.green or colors.red)
    term.write(connected and "Connected" or "Not Connected")

    term.setTextColor(colors.black)
    local versionText = "Combine " .. VERSION
    term.setCursorPos(w - #versionText, h)
    term.write(versionText)
  end

  draw()

  ---------------------------
  -- Tortise Initalization --
  ---------------------------
  local tortise = require("tortise").new(true, args["--debug"], function(...)
    debug("[T]", ...)
  end)

  -- Set up bounding box and move to home if we aren't already there.
  tortise.setBoundingBox(config.bounds.min[1], config.bounds.min[2], config.bounds.min[3], config.bounds.max[1], config.bounds.max[2], config.bounds.max[3])
  tortise.goToAbsolutePosition(unpack(config.home))

  -----------------------
  -- Remote Monitoring --
  -----------------------

  local messageQueue = {}
  local wsTryAgainAt = 0

  local function addToMessageQueue(msg)
    table.insert(messageQueue, msg)
  end

  -- Authorizes the Websocket.
  local function authWS()
    -- Ensure we can actually connect
    if args["--disable-remote-monitoring"] then return end
    if wsTryAgainAt > os.epoch("utc") then return end

    -- Create the tentative connection
    local _ws = http.websocket(config.ws.url)
    if type(_ws) == "boolean" then
      msg("[WS] Failed to connect to websocket")
      wsTryAgainAt = os.epoch("utc") + 5000
      return
    end

    -- Send the authentication message
    _ws.send(textutils.serialiseJSON({
      type = "auth",
      key = config.ws.key,
      id = os.getComputerID()
    }))

    -- Receive the response
    local response = _ws.receive()
    local data = textutils.unserialiseJSON(response)
    if data and data.type == "auth" and data.success == true then
      ws = _ws
      connected = true
      msg("[WS] Connected successfully")
      draw()

      local ok, err = pcall(function()
        local filteredConfig = {}

        for i, v in pairs(config) do
          if type(v) ~= "function" and i ~= "ws" then
            filteredConfig[i] = v
          end
        end

        filteredConfig.fuelLimit = turtle.getFuelLimit()
        filteredConfig.version = VERSION
  
        -- Seriialise message & send.
        local msg = textutils.serialiseJSON({
          type = "turtle_config",
          id = os.getComputerID(),
          config = filteredConfig
        })
  
        debug("[WS] MSG (CfgTrans) Size:", #msg)
  
        addToMessageQueue(msg)
        connected = true
      end)
    else
      msg("[WS] Failed to authenticate with websocket")
      wsTryAgainAt = os.epoch("utc") + 5000
    end
  end

  -- Transmits the turtle's current map to the Websocket.
  local function transmitMap()
    -- Return if websocket is disabled
    if args["--disable-remote-monitoring"] then return end

    -- Return if WS connection has failed in the last minute
    if lastConnectionFailure + 60 * 1000 > os.epoch("utc") then
      return
    end

    local ok, err = pcall(function()
      local filteredMap = {}
      local positions = {}

      -- Filter each position on the map, and add it to a condensed table.
      for i, v in pairs(map) do
        if v.y == -1 and v.name ~= "minecraft:air" then
          positions[v.x .. "," .. v.z] = true
          local age
          if v.state.age then
            age = math.floor((v.state.age / config.block.age) * 10) / 10
          end

          table.insert(filteredMap, {
            x = v.x, z = v.z, a = age, b = v.name:gsub("minecraft:", "")
          })
        end
      end

      -- If a position has nothing, but has something below it, add it to the list.
      for i, v in pairs(map) do
        if positions[v.x .. "," .. v.z] == nil and v.y == -2 and v.name ~= "minecraft:air" then
          table.insert(filteredMap, {
            x = v.x, z = v.z, b = v.name:gsub("minecraft:", "")
          })
        end
      end

      -- Seriialise message & send.
      local msg = textutils.serialiseJSON({
        type = "turtle_map",
        id = os.getComputerID(),
        map = filteredMap
      })

      debug("[WS] MSG (MapTrans) Size:", #msg)

      addToMessageQueue(msg)
      connected = true
    end)

    if not ok then
      connected = false
      debug("[WS] TransMap failed", err)
      lastConnectionFailure = os.epoch("utc")
    end
  end

  -- Transmits the current position to the remote Websocket.
  local function transmitPosition()
    -- Return if websocket is disabled
    if args["--disable-remote-monitoring"] then return end

    -- Return if WS connection has failed in the last minute
    if lastConnectionFailure + 60 * 1000 > os.epoch("utc") then
      return
    end

    draw()

    local ok, err = pcall(function()
      -- Get current world position
      local worldPos = {tortise.getWorldPosition()}

      -- Serialise message & send.
      local msg = textutils.serialiseJSON({
        type = "turtle_pos",
        id = os.getComputerID(),
        position = worldPos,
        facing = tortise.getFacing()
      })

      debug("[WS] MSG (PosTrans) Size:", #msg)

      addToMessageQueue(msg)
      connected = true
    end)

    if not ok then
      connected = false
      msg("[WS] PosTrans failed", err)
      lastConnectionFailure = os.epoch("utc")
    end
  end

  -- Transmits the contents of the turtle's inventory.
  local function transmitInventory()
    -- Return if websocket is disabled
    if args["--disable-remote-monitoring"] then return end

    -- Return if WS connection has failed in the last minute
    if lastConnectionFailure + 60 * 1000 > os.epoch("utc") then
      return
    end

    local ok, err = pcall(function()
      local inv = tortise.getInventory()

      -- Serialise message & send.
      local msg = textutils.serialiseJSON({
        type = "turtle_inventory",
        id = os.getComputerID(),
        inventory = inv
      })

      debug("[WS] MSG (InvTrans) Size:", #msg)

      addToMessageQueue(msg)
      connected = true
    end)

    if not ok then
      connected = false
      msg("[WS] InvTrans failed", err)
      lastConnectionFailure = os.epoch("utc")
    end
  end

  -- Transmits the following information about this farm:
  -- Computer ID, World Position, Facing, Target (if applicable),
  -- Home Position, Top Left Bounds Corner, Bounds Size,
  -- Current Fuel Level, Current State Text, and whether or not
  -- this turtle has an active warning
  local function transmitState(target, state)
    -- Update state for local monitoring
    stateText = state
    msg(state)
    draw()

    -- Return if websocket is disabled
    if args["--disable-remote-monitoring"] then return end

    -- Return if WS connection has failed in the last minute
    if lastConnectionFailure + 60 * 1000 > os.epoch("utc") then
      return
    end

    local ok, err = pcall(function()
      local worldPos = {tortise.getWorldPosition()}

      local filteredWarnings = {}

      for i, v in pairs(warnings) do
        if v == true then
          table.insert(filteredWarnings, i)
        end
      end

      -- Get all the information, serialise & send.
      local msg = textutils.serialiseJSON({
        type = "turtle_state",
        name = os.getComputerLabel() or "Farm",
        id = os.getComputerID(),
        position = worldPos,
        facing = tortise.getFacing(),
        target = target and { target[1] + worldPos[1], target[2] + worldPos[2], target[3] + worldPos[3] } or nil,
        home = config.home,
        topLeft = config.bounds.min,
        boundsSize = {config.bounds.max[1] - config.bounds.min[1] + 1, config.bounds.max[3] - config.bounds.min[3] + 1},
        fuel = turtle.getFuelLevel(),
        state = state,
        warnings = filteredWarnings,
        paused = paused
      })

      debug("[WS] MSG (StateTrans) Size:", #msg)

      addToMessageQueue(msg)
      connected = true
    end)

    if not ok then
      connected = false
      msg("[WS] StateTrans failed", err)
      lastConnectionFailure = os.epoch("utc")
    end
  end

  ------------------------
  -- Thread Definitions --
  ------------------------

  local round = 0
  local pauseRound = 0
  local canPause = false

  local updateData

  local function farmThread()
    local function doRound()
      msg("Starting round #" .. tostring(round))
      -- Ensure that the fuel level isn't dangerously low.
      if turtle.getFuelLevel() > config.dangerousFuelLevel then
        -- Calculate item & seed count prior to searching
        local preItemCount = tortise.count(config.item.name)
        local preSeedCount = config.seed.sameAsItem == false and tortise.count(config.item.name) or nil

        -- Go to all the blocks
        tortise.goToAll(
          -- Name filter
          config.block.name,
          -- State filter
          { age = config.block.age },
          -- On reach function
          function(tX, tY, tZ)
            -- Dig down and replace
            tortise.dig("down")
            tortise.place("down", config.seed.name or config.item.name)
            for i, v in pairs(map) do
              if v.x == tX and v.y == tY and v.z == tZ then
                map[i].state = { age = 0 }
                transmitMap()
              end
            end
          end,
          -- Disables movement on the Y axis
          true,
          -- Position check function
          function(x, y, z) return y == -1 end,
          -- When this turtle reaches all of its initial targets, it will search for more.
          true,
          -- On Target Found Function
          function(x, y, z, checked, targets)
            -- Transmit a state telling that the turtle found a crop.
            transmitState({x, y, z}, "(Round #" .. tostring(round) .. ") Navigating to crop (" .. tostring(checked) .. "/" .. tostring(targets) .. ")")
          end,
          -- On Move Function
          function(moved, dir)
            transmitPosition()
            if paused then
              canPause = true
              while true do sleep(100) end
            end
          end
        )

        -- Calculate item & seed count after searching
        local postItemCount = tortise.count(config.item.name)
        local postSeedCount = config.seed.sameAsItem == false and tortise.count(config.item.name) or nil

        -- Log numbers
        msg("Net item count:", postItemCount - preItemCount)
        if postSeedCount then
          msg("Net seed count:", postSeedCount - preSeedCount)
        end
      end

      -- Return home
      transmitState(config.home, "(Round #" .. tostring(round) .. ") Returning home")
      tortise.goToAbsolutePosition(
        config.home[1],
        config.home[2],
        config.home[3],
        false,
        -- On Move Function
        function(moved, dir)
          transmitPosition()
        end
      )
      map = tortise.scan()
      transmitMap()
    end

    local function drop(fRound)
      local roundText = fRound and " (Round #" .. tostring(fRound) .. ") " or ""
      -- Remove extra items
      transmitState(config.home, roundText .. "Emptying inventory")
      for i, v in pairs(itemRequirements) do
        local count, slots = tortise.count(i)
        local totalDropped = 0

        -- TODO: Probably move this to a Tortise function (dropall, dropcount, etc.)
        if count > v.max then
          for i, s in pairs(slots) do
            turtle.select(s)
            local slotCount = turtle.getItemCount(s)
            local dropped = turtle.dropDown(math.min(64, count - v.min))
            count = count - math.min(slotCount, count - v.min)
            totalDropped = totalDropped + (slotCount - turtle.getItemCount())
            if count <= v.min then break end
          end

          warnings["Output chest is full"] = totalDropped == 0
        end
      end

      -- Drop waste items
      for i, v in pairs(config.wasteItems) do
        local count, slots = tortise.count(i)
        for i, s in pairs(slots) do
          turtle.select(s)
          turtle.dropDown()
        end
      end
    end

    local function refuel(fRound)
      local roundText = fRound and " (Round #" .. tostring(fRound) .. ") " or ""
      -- Refuel
      local fuelLevel = turtle.getFuelLevel()
      if fuelLevel < config.refuelLevel then
        transmitState(config.home, roundText .. "Refueling")
        turtle.select(tortise.findFreeSlot())
        turtle.suckUp(64)
        turtle.refuel(64)
        msg("Refueled, new level is", turtle.getFuelLevel())
      end
    end

    -- Main loop
    while true do
      if (paused and pauseRound % 30 == 0) or paused == false then
        map = tortise.scan()
        transmitMap()
      end
      
      -- Check for warnings
      local inventory = tortise.getInventory()
      warnings["Fuel level dangerously low"] = turtle.getFuelLevel() < config.dangerousFuelLevel
      warnings["Fuel level low"] = turtle.getFuelLevel() < config.refuelLevel
      warnings["Inventory full"] = #inventory == 16
      local cannotOperate = warnings["Fuel level dangerously low"] == true or warnings["Inventory full"] == true

      if cannotOperate then
        drop()
        refuel()
        transmitState(nil, "Cannot operate")
      elseif paused then
        tortise.goToAbsolutePosition(
          config.home[1],
          config.home[2],
          config.home[3],
          false,
          -- On Move Function
          function(moved, dir)
            transmitPosition()
          end
        )
  
        if pauseRound % 30 == 0 or pauseRound == 0 then
          transmitState(nil, "Paused")
        end
        pauseRound = pauseRound + 1
      else
        round = round + 1
        parallel.waitForAny(doRound, function()
          -- checks if the turtle is paused
          while not paused do
            sleep(1)
          end
          while not canPause do
            sleep()
          end
        end)

        if paused then
          tortise.goToAbsolutePosition(
            config.home[1],
            config.home[2],
            config.home[3],
            false,
            -- On Move Function
            function(moved, dir)
              transmitPosition()
            end
          )
        end

        drop(round)
        refuel(round)
        
        transmitState(nil, paused and "Paused" or "Resting")
        canPause = false
      end

      if updateData then
        local ok, err = pcall(function()
          for i, v in pairs(updateData.files) do
            transmitState(nil, "Downloading update file " .. i .. " of " .. #updateData.files)
            local req = http.get(v)
            if req then
              local file = fs.open(i, "w")
              file.write(req.readAll())
              file.close()
              req.close()
            end
          end

          print("Update downloaded. Restarting in 5 seconds.")
          transmitState(nil, "Update downloaded. Restarting in 5 seconds.")
          sleep(5)
          os.reboot()
        end)
        if not ok then
          msg("[WS] Failed to update", err)
          warnings["Failed to update"] = true
          transmitState(nil, "Failed to update. Restart required.")
          while true do sleep(1000000) end
        end
      end

      sleep(paused and 1 or 15)
    end
  end

  local function wsQueueThread()
    if args["--disable-remote-monitoring"] then
      return
    end

    while true do
      local ok, err = pcall(function() 
        if messageQueue[1] and ws then
          ws.send(messageQueue[1])
          table.remove(messageQueue, 1)
        end
      end)
      if not ok then
        msg("[WS] Failed to send message", err)
        lastConnectionFailure = os.epoch("utc")
        connected = false
      end

      sleep()
    end
  end

  local function remoteControlThread()
    if args["--disable-remote-monitoring"] then
      return
    end

    while true do
      local ok, err = pcall(function()
        if ws == nil then
          authWS()
        end

        if ws and ws.receive then
          local message = ws.receive()
          if message then
            local data = textutils.unserialiseJSON(message)
            if data and data.type == "command" and data.id == os.getComputerID() then
              msg("[WS] Received command:", data.command)
              if data.command == "pause" or data.command == "resume" then
                paused = data.command == "pause"
                settings.set("combine.paused", paused)
                settings.save()
                pauseRound = 0
              elseif data.command == "restart" then
                os.reboot()
              elseif data.command == "update" then
                updateData = data.data
                paused = true
              end
            end
          end
        end
      end)

      if not ok then
        msg("[WS] Failed to receive message", err)
        lastConnectionFailure = os.epoch("utc")
      end

      if err and err:find("closed file") then
        ws = nil
      end

      sleep()
    end
  end

  local function inventoryThread()
    transmitInventory()

    while true do
      local e = {os.pullEvent()}
      if e[1] == "turtle_inventory" then
        transmitInventory()
      end
    end
  end

  ---------------
  -- Main Loop --
  ---------------

  parallel.waitForAny(wsQueueThread, remoteControlThread, inventoryThread, farmThread)
end)

if ws then ws.close() end
if err then
  term.redirect(native)
  term.setCursorPos(1, 1)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.red)
  print("Combine has stopped!")
  print(err)

  if err ~= "Terminated" then
    local unsafeExits = settings.get("combine.unsafe_exits") or 0
    local lastUnsafeExit = settings.get("combine.last_unsafe_exit") or 0

    if lastUnsafeExit + 15 * 60 * 1000 < os.epoch("utc") then
      unsafeExits = 0
    end

    settings.set("combine.last_unsafe_exit", os.epoch("utc"))
    settings.set("combine.unsafe_exits", unsafeExits + 1)
    settings.save()
    print("This turtle will restart in 15 seconds")

    for i = 15, 1, -1 do
      write(".")
      sleep(1)
    end

    os.reboot()
  end
end
