local _expect = require("cc.expect")
local field, expect = _expect.field, _expect.expect
local items = {
  PICKAXE = "minecraft:diamond_pickaxe",
  ENDER_MODEM = "computercraft:wireless_modem_advanced",
  MODEM = "computercraft:wireless_modem_normal",
  BLOCK_SCANNER = "plethora:module_scanner"
}

local peripheralNames = {
  MODEM = "modem",
  BLOCK_SCANNER = "plethora:scanner"
}

local rights = {
  north = "east",
  east = "south",
  south = "west",
  west = "north"
}

local lefts = {
  north = "west",
  east = "north",
  south = "east",
  west = "south"
}

local worldDirections = {
  ["-z"] = "north",
  ["+z"] = "south",
  ["-x"] = "west",
  ["+x"] = "east",
  ["-y"] = "down",
  ["+y"] = "up"
}

local oppisites = {
  left = "right",
  right = "left",
  forward = "back",
  back = "forward",
  up = "down",
  down = "up",
  north = "south",
  east = "west",
  south = "north",
  west = "east",
  ["-z"] = "+z",
  ["+z"] = "-z",
  ["-x"] = "+x",
  ["+x"] = "-x",
  ["-y"] = "+y",
  ["+y"] = "-y",
}

local directionValues = {
  west = -1,
  north = 0,
  east = 1,
  south = 2
}

local function evalulateClosestDistance(positions, x, y, z, invalidPositions)
  expect(1, positions, "table")
  expect(2, x, "number")
  expect(3, y, "number")
  expect(4, z, "number")

  local function isValid(x, y, z)
    for i, v in pairs(invalidPositions) do
      if v.x == x and v.y == y and v.z == z then
        return false
      end
    end
    return true
  end

  local closest = {}
  local distanceOfClosest = math.huge

  for i, v in pairs(positions) do
    field(v, "x", "number")
    field(v, "y", "number")
    field(v, "z", "number")
    local distance = math.abs(v.x - x) + math.abs(v.y - y) + math.abs(v.z - z)
    if distance < distanceOfClosest and isValid(v.x, v.y, v.z) then
      distanceOfClosest = distance
      closest = v
    end
  end
  return {
    x = closest.x - x,
    y = closest.y - y,
    z = closest.z - z
  }, distanceOfClosest, closest
end

--- Creates a new tortise object.
-- @param willUseAbsolute boolean When set to true, the turtle will use absolute positioning.
-- @param debug boolean When set to true, the turtle will print debug messages.
-- @param debugFunc function A function to use for debug messages.
-- @returns table A new tortise object.
local function new(willUseAbsolute, debug, debugFunc)
  expect(1, willUseAbsolute, "boolean", "nil")
  expect(2, debug, "boolean", "nil")
  expect(3, debugFunc, "function", "nil")
  debug = debug or false

  local function debugMsg(...)
    if debugFunc and debug then
      debugFunc(...)
    elseif debug then
      print(...)
    end
  end

  debugMsg("Tortise Init")

  local x, y, z = nil, nil, nil
  local facing = nil

  local equipmentLeft = nil
  local equipmentRight = nil

  -- Check current equipment (if there's an empty slot)
  for i = 1, 16 do
    if turtle.getItemCount(i) == 0 then
      turtle.select(i)

      turtle.equipRight()
      local detail = turtle.getItemDetail(i)
      if detail then
        equipmentRight = detail.name
        turtle.equipRight()
      end

      turtle.equipLeft()
      detail = turtle.getItemDetail(i)
      if detail then
        equipmentLeft = detail.name
        turtle.equipLeft()
      end

      break
    end
  end

  debugMsg("Equipment: right ", equipmentRight, "left", equipmentLeft)

  --[[
    Utility Functions
  ]]

  --- Gets the turtle's inventory.
  -- @returns table The turtle's inventory.
  local function getInventory()
    local inventory = {}
    for i = 1, 16 do
      inventory[i] = turtle.getItemDetail(i, true)
    end

    return inventory
  end

  --- Selects an item in the turtle's inventory.
  -- @param what string The item to select.
  -- @returns boolean, number True if the item was found, the slot the item was found in.
  local function select(what)
    expect(1, what, "string")
    if turtle.getItemDetail() and turtle.getItemDetail().name == what then return true end

    for i = 1, 16 do
      local detail = turtle.getItemDetail(i, true)
      if detail and detail.name == what then
        turtle.select(i)
        return true, i
      end
    end

    return false
  end

  --- Equips an item in the turtle's inventory.
  -- @param what string The item to equip.
  -- @param peripheralName string|nil The name of the peripheral to equip.
  -- @returns boolean True if the item was equipped.
  local function equip(what, peripheralName)
    expect(1, what, "string")
    expect(1, peripheralName, "string", "nil")

    if peripheralName and peripheral.getType("right") == peripheralName then
      return true
    end

    if equipmentRight == what then return true end

    local exists, slot = select(what)
    if not exists then return false end
    equipmentRight = turtle.getItemDetail().name
    turtle.equipRight()
    return true
  end

  --- Finds an empty slot.
  -- @returns number|nil The empty slot.
  local function findFreeSlot()
    for i = 1, 16 do if turtle.getItemCount(i) == 0 then return i end end
    return nil
  end

  --[[
    Peripheral Functions
  ]]

  --- Locates the turtle using a modem.
  -- @returns number, number, number The X, Y, and Z coordinates of the turtle.
  local function locate()
    if peripheral.getType("left") ~= peripheralNames.MODEM then
      local success, slot = select(items.MODEM)
      if not success then
        success, slot = select(items.ENDER_MODEM)
      end
      if not success then error("No modem, cannot locate") end

      equipmentLeft = turtle.getItemDetail().name
      turtle.equipLeft()
    end

    x, y, z = gps.locate()

    return x, y, z
  end

  --- Scans the area around the turtle with a block scanner.
  -- @returns table A table containing the blocks around the turtle.
  local function scan()
    local has = equip(items.BLOCK_SCANNER, peripheralNames.BLOCK_SCANNER)
    if not has then error("No block scanner!") end

    return peripheral.call("right", "scan")
  end

  --- Gets the direction the turtle is facing
  -- @returns string The direction the turtle is facing.
  local function getFacing()
    local blocks = scan()
    for i, v in pairs(blocks) do
      if v.x == 0 and v.y == 0 and v.z == 0 then
        facing = v.state.facing
        return
      end
    end

    return facing
  end

  --- Initalizes the turtle's state of the world.
  local function initWorld()
    if x ~= nil and y ~= nil and z ~= nil and facing ~= nil then return end
    locate()
    getFacing()
    debugMsg("WorldInit", x, y, z, facing)
  end

  --- Digs in the specified direction.
  -- @param dir string The direction to dig in, up or down.
  -- @returns boolean True if the dig was successful.
  local function dig(dir)
    local digFunc = turtle.dig

    if dir == "down" then digFunc = turtle.digDown elseif dir == "up" then digFunc = turtle.digUp end
    local exists = equip(items.PICKAXE)
    if not exists then error("No pickaxe") end

    digFunc()
    return true
  end

  --- Places a block in a direction.
  -- @param dir string The direction to turn in.
  -- @param what string What to place
  -- @returns boolean True if the place was successful.
  local function place(dir, what)
    expect(1, dir, "string")
    expect(2, what, "string")

    local placeFunc = turtle.place

    if dir == "down" then placeFunc = turtle.placeDown elseif dir == "up" then placeFunc = turtle.placeUp end
    local exists = select(what)
    if not exists then return false end

    placeFunc()
    return true
  end

  --- Turns in the specified direction.
  -- @param dir string The direction to turn in.
  local function turn(dir)
    expect(1, dir, "string")

    if dir == "left" then
      turtle.turnLeft()
      facing = lefts[facing]
    elseif dir == "right" then
      turtle.turnRight()
      facing = rights[facing]
    end
  end

  --- Faces in a direction.
  -- @param dir string The direction to face.
  local function face(dir)
    expect(1, dir, "string")

    initWorld()
    debugMsg("Facing", dir)
    if facing == dir then return end

    local difference = directionValues[facing] - directionValues[dir]
    if math.abs(difference) == 3 then
      difference = 1 * -(difference / 3)
    end

    if difference > 0 then
      for i = 1, difference do
        turn("left")
      end
    elseif difference < 0 then
      for i = 1, math.abs(difference) do
        turn("right")
      end
    end
  end

  --- Checks to make sure a position is within the set bounding box.
  -- @param x number
  -- @param y number
  -- @param z number
  -- @returns boolean True if the point is within the bounding box.
  local function isWithinBoundingBox(x, y, z)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, z, "number")
    
    initWorld()
    return x >= boundingBox.min.x and y >= boundingBox.min.y and z >= boundingBox.min.z and
      x <= boundingBox.max.x and y <= boundingBox.max.y and z <= boundingBox.max.z
  end

  --- Moves the turtle the specified distance in the specified direction. If destructive is supplied, the turtle will destroy blocks to make it to its final location.
  --- TODO: When destructive is not supplied, attempt to get there via pathfinding.
  -- @param distance number The distance to move.
  -- @param direction string One of: [north, east, south, west, forward, right, left, back, +x, -x, +y, -y, +z, -z, up, down]. Moves in that direction.
  -- @param destructive boolean When set to true, the turtle will break blocks to reach its target.
  -- @param singleMove function Executes with a X, Y, and Z parameter when the turtles moves.
  -- @returns boolean, number, string True if the move succeeded, number of blocks moved, reason for failure if target could not be reached.
  local function move(distance, direction, destructive, singleMove)
    expect(1, distance, "number")
    expect(2, direction, "string")
    expect(3, destructive, "boolean", "nil")
    expect(4, singleMove, "function", "nil")

    -- No need to do anything if the distance is 0
    if distance == 0 then return true, 0 end

    -- Make sure the distance is a whole number
    if math.floor(distance) ~= distance then error("Distance must be a whole number") end

    -- For world directions, (+x, -y, etc.), turn these to cardinal directions.
    if worldDirections[direction] then
      direction = worldDirections[direction]
    end

    -- If distance is negative, reverse it.
    if distance < 1 and oppisites[direction] then
      direction = oppisites[direction]
      distance = math.abs(distance)
    end

    -- Change cardinal directions to relative directions.
    if direction == "north" or direction == "east" or direction == "south" or direction == "west" then
      face(direction)
      direction = "forward"
    end

    -- Ensure the requested direction is valid
    local validDirs = { forward = true, back = true, right = true, left = true, up = true, down = true }
    if validDirs[direction] == nil then error("Invalid direction: " .. direction) end

    -- Turn depending on the direction
    if direction == "right" then turn("right") end
    if direction == "left" then turn("left") end
    if direction == "back" and destructive then turn("right") turn("right") end

    debugMsg("Final: direction", direction, "facing", facing, "distance", distance)

    -- Adds to the current direction value. Utility function
    local function addDirection()
      if (direction == "up" or direction == "down") and y ~= nil then
        y = y + (direction == "up" and 1 or -1)
      elseif (facing == "east" or facing == "west") and x ~= nil then
        x = x + (facing == "east" and 1 or -1)
      elseif (facing == "north" or facing == "south") and z ~= nil then
        z = z + (facing == "south" and 1 or -1)
      end
    end

    -- Check for bounding boxes.
    if boundingBox and facing ~= "up" and facing ~= "down" then
      if facing == "north" then
        if not isWithinBoundingBox(x, y, z - distance) then
          error("Location would be outside bounding box")
        end
      elseif facing == "east" then
        if not isWithinBoundingBox(x + distance, y, z) then
          error("Location would be outside bounding box")
        end
      elseif facing == "south" then
        if not isWithinBoundingBox(x, y, z + distance) then
          error("Location would be outside bounding box")
        end
      elseif facing == "west" then
        if not isWithinBoundingBox(x - distance, y, z) then
          error("Location would be outside bounding box")
        end
      end
    elseif boundingBox then
      if facing == "up" then
        if not isWithinBoundingBox(x, y + distance, z) then
          error("Location would be outside bounding box")
        end
      elseif facing == "down" then
        if not isWithinBoundingBox(x, y - distance, z) then
          error("Location would be outside bounding box")
        end
      end
    end

    local moveFunc = turtle.forward

    if not destructive and direction == "back" then moveFunc = turtle.back end
    if direction == "up" then moveFunc = turtle.up end
    if direction == "down" then moveFunc = turtle.down end

    -- Destructive movement
    if destructive then
      local moved = 0
      local digFunc = turtle.dig
      if direction == "up" then digFunc = turtle.digUp() end
      if direction == "down" then digFunc = turtle.digDown() end

      for i = 1, distance do
        local success, reason = moveFunc()
        if not success then
          equip(items.PICKAXE)
          digFunc()
          success, reason = moveFunc()

          if not success then
            return false, moved, reason
          end
        end

        addDirection()
        moved = moved + 1
        if singleMove then singleMove(x, y, z) end
      end

      return true, moved
    else
      -- Non-destructive movement
      local moved = 0

      for i = 1, distance do
        local success, reason = moveFunc()
        if not success then
          return false, moved, reason
        end

        addDirection()
        moved = moved + 1
        if singleMove then singleMove(x, y, z) end
      end

      return true, moved
    end
  end

  --- Goes to a position relative to the turtle.
  -- @param rX number The relative X value
  -- @param rY number The relative Y value
  -- @param rZ number The relative Z value
  -- @param destructive boolean When set to true, the turtle will break blocks to reach its target.
  -- @param singleMove function Executes with a X, Y, and Z parameter when the turtles moves.
  local function goToRelativePosition(rX, rY, rZ, destructive, singleMove)
    expect(1, rX, "number")
    expect(2, rY, "number")
    expect(3, rZ, "number")
    expect(4, destructive, "boolean", "nil")
    expect(5, singleMove, "function", "nil")

    debugMsg("Going to relative, position", rX, rY, rZ, "destructive:", destructive)
    if boundingBox then
      local newX, newY, newZ = x + rX, y + rY, z + rZ
      if not isWithinBoundingBox(newX, newY, newZ) then
        error("Location would be outside bounding box")
      end
    end

    local xOk, xDisplacement, xErr = move(rX, "+x", destructive, singleMove)
    if not xOk then error(xErr) end

    local yOk, yDisplacement, xErr = move(rY, "+y", destructive, singleMove)
    if not yOk then error(yErr) end

    local zOk, zDisplacement, zErr = move(rZ, "+z", destructive, singleMove)
    if not zOk then error(zErr) end

    debugMsg("New position", x, y, z)

    return true, { x = (rX < 0 and -1 or 1) * xDisplacement, y = (rY < 0 and -1 or 1) * yDisplacement, z =  (rZ < 0 and -1 or 1) * zDisplacement }
  end

  --- Goes to an absolute X, Y and Z position based on the modem positioning.
  -- @param aX number The absolute X value
  -- @param aY number The absolute Y value
  -- @param aZ number The absolute Z value
  -- @param destructive boolean When set to true, the turtle will break blocks to reach its target.
  -- @param singleMove function Executes with a X, Y, and Z parameter when the turtles moves.
  local function goToAbsolutePosition(aX, aY, aZ, destructive, singleMove)
    expect(1, aX, "number")
    expect(2, aY, "number")
    expect(3, aZ, "number")
    expect(4, destructive, "boolean", "nil")
    expect(5, singleMove, "function", "nil")

    debugMsg("Going to absolute, position", aX, aY, aZ, "destructive:", destructive, "current pos:", x, y, z, "dist:", aX - x, aY - y, aZ - z)
    initWorld()
    return goToRelativePosition(aX - x, aY - y, aZ - z, destructive, singleMove)
  end

  --- Scans for matching blocks.
  -- @param block string The ID of the block to search for.
  -- @param state table|nil The state to filter against.
  -- @param posFunction number Provides the X, Y, and Z arguments of a position. This function should return a boolean on whether or not these are valid.
  local function scanForMatchingBlocks(block, state, posFunction)
    state = state or {}
    posFunction = posFunction or function() return true end

    expect(1, block, "string")
    expect(2, state, "table")
    expect(3, posFunction, "function", "nil")

    local items = scan()
    local validBlocks = {}

    for i, v in pairs(items) do
      if v.name == block and posFunction(v.x, v.y, v.z) and (boundingBox == nil or isWithinBoundingBox(x + v.x, y + v.y, z + v.z)) then
        local stateMatches = true

        if state then
          for i, s in pairs(state) do
            if v.state[i] ~= s then
              stateMatches = false
            end
          end
        end

        if stateMatches then table.insert(validBlocks, v) end
      end
    end

    return validBlocks
  end

  --- Goes to the cloest block.
  -- @param block string The ID of the block to search for.
  -- @param state table|nil The state to filter against.
  -- @param dontMoveOnY number When set to true, the turtle will not move on the Y axis.
  -- @param posFunction number Provides the X, Y, and Z arguments of a position. This function should return a boolean on whether or not these are valid.
  -- @param destructive boolean When set to true, the turtle will break blocks to reach its target.
  -- @param singleMove function Executes with a X, Y, and Z parameter when the turtles moves.
  local function goToClosestBlock(block, state, posFunction, dontMoveOnY, destructive, singleMove)
    expect(1, block, "string")
    expect(2, state, "table")
    expect(3, dontMoveOnY, "boolean", "nil")
    expect(4, posFunction, "function", "nil")
    expect(5, destructive, "boolean", "nil")
    expect(6, singleMove, "function", "nil")

    local blocks = scanForMatchingBlocks(block, state, posFunction)

    if #blocks > 0 then
      local closest = evalulateClosestDistance(blocks, 0, 0, 0)
      goToRelativePosition(closest.x, dontMoveOnY and 0 or closest.y, closest.z, destructive, singleMove)
      return true
    end

    return false
  end

  --- Goes to all the blocks it finds and runs a function there.
  -- @param block string The ID of the block to search for.
  -- @param state table|nil The state to filter against.
  -- @param reachedFunction function The function to run when each block is reached.
  -- @param dontMoveOnY number When set to true, the turtle will not move on the Y axis.
  -- @param posFunction number Provides the X, Y, and Z arguments of a position. This function should return a boolean on whether or not these are valid.
  -- @param continuous boolean Once the turtle reaches all of the blocks it has found, when this is set to true, it will continue to search for more.
  -- @param foundTarget function Executes with a X, Y, and Z parameter whenever a target is found.
  -- @param singleMove function Executes with a X, Y, and Z parameter when the turtles moves.
  local function goToAll(block, state, reachedFunction, dontMoveOnY, posFunction, continuous, foundTarget, singleMove)
    expect(1, block, "string")
    expect(2, state, "table", "nil")
    expect(3, reachedFunction, "function", "nil")
    expect(4, dontMoveOnY, "boolean", "nil")
    expect(5, posFunction, "function", "nil")
    expect(6, continuous, "boolean", "nil")
    expect(7, foundTarget, "function", "nil")
    expect(8, singleMove, "function", "nil")

    local blocks = scanForMatchingBlocks(block, state, posFunction)
    -- cd stands for "current displacement"
    debugMsg("goToAll", #blocks)

    local totalBlocks = #blocks
    local blocksChecked = 0

    -- Check all the blocks
    local function checkBlocks(blocks)
      local cdX, cdY, cdZ = 0, 0, 0
      local invalidPositions = {}

      for i = 1, #blocks do
        -- Find closest block
        local closest, _, rv = evalulateClosestDistance(blocks, cdX, cdY, cdZ, invalidPositions)

        -- Execute found target function
        if foundTarget then
          foundTarget(closest.x, dontMoveOnY and 0 or closest.y, closest.z, blocksChecked, totalBlocks)
        end

        local _, displacement = goToRelativePosition(closest.x, dontMoveOnY and 0 or (closest.y), closest.z, nil, singleMove)
        cdX = cdX + displacement.x
        cdY = cdY + displacement.y
        cdZ = cdZ + displacement.z

        table.insert(invalidPositions, {x = rv.x, y = rv.y, z = rv.z})

        -- Execute reached function
        if reachedFunction then
          reachedFunction(rv.x, rv.y, rv.z)
        end

        blocksChecked = blocksChecked + 1
      end
    end

    checkBlocks(blocks)
    if continuous then
      repeat
        blocks = scanForMatchingBlocks(block, state, posFunction)
        totalBlocks = totalBlocks + #blocks
        checkBlocks(blocks)
      until #blocks == 0
    end

    return 0
  end

  --- Sets the bounding box / safe area for the turtle.
  -- @param minX number
  -- @param minY number
  -- @param minZ number
  -- @param maxX number
  -- @param maxY number
  -- @param maxZ number
  local function setBoundingBox(minX, minY, minZ, maxX, maxY, maxZ)
    expect(1, minX, "number")
    expect(2, minY, "number")
    expect(3, minZ, "number")
    expect(4, maxX, "number")
    expect(5, maxY, "number")
    expect(6, maxZ, "number")

    initWorld()

    boundingBox = {
      min = {
        x = minX,
        y = minY,
        z = minZ,
      },
      max = {
        x = maxX,
        y = maxY,
        z = maxZ
      }
    }
  end

  --- Counts the amount of items the turtle has in its inventory.
  -- @param what string The item to search for.
  -- @returns count The total count of items.
  -- @returns slots A table containing the slots the items were found in.
  local function countItems(what)
    expect(1, what, "string")

    local inventory = getInventory()
    local count = 0
    local slots = {}

    for i, v in pairs(inventory) do
      if v.name == what then
        count = count + v.count
        table.insert(slots, i)
      end
    end

    return count, slots
  end

  if willUseAbsolute then initWorld() end

  return {
    findFreeSlot = findFreeSlot,
    goToRelativePosition = goToRelativePosition,
    move = move,
    dig = dig,
    equip = equip,
    select = select,
    goToAbsolutePosition = goToAbsolutePosition,
    goToClosestBlock = goToClosestBlock,
    setBoundingBox = setBoundingBox,
    place = place,
    count = countItems,
    goToAll = goToAll,
    getWorldPosition = function()
      initWorld()
      return x, y, z
    end,
    getFacing = function()
      initWorld()
      return facing
    end,
    scan = scan,
    getInventory = getInventory
  }
end

return {
  new = new,
  items = items
}