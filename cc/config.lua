return {
  -- Arguments to execute with every time
  execArgs = {},
  ws = {
    -- Websocket server url
    url = "ws://localhost:5678",
    -- Websocket server key
    key = "5678"
  },
  -- The item to search for.
  item = {
    name = "minecraft:wheat",
    -- The minimum amount of items to keep in the inventory. 
    min = 16,
    -- The maximum amount of items to keep in the inventory. 
    -- If this number is exceeded the turtle will drop the items.
    max = 64
  },
  seed = {
    -- Set to true if the seed is the same as the item.
    sameAsItem = true,
    name = "minecraft:wheat_seeds",
    min = 16,
    max = 64
  },
  -- The home position of the turtle.
  home = {-24, 58, 7},
  block = {
    -- The block to search for on the farmland.
    name = "minecraft:carrots",
    -- The age of the block to search for.
    age = 7
  },
  -- If the turtle is below this fuel level it will return home to refuel.
  refuelLevel = 512,
  -- If the turtle is below this fuel level it will refuse to run
  -- until it is refueled.
  dangerousFuelLevel = 256,
  -- Items that the turtle does not need, such as poisonous potatoes.
  wasteItems = {},
  -- The area to search for farmland and to keep the turtle within.
  bounds = {
    -- The +X, +Y, +Z corner of the area.
    max = {-17, 58, 15},
    -- The -X, -Y, -Z corner of the area.
    min = {-32, 57, 0}
  }
}
