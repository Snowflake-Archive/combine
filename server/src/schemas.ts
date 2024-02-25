import { z } from "zod";

export const Vector2 = z.array(z.number()).length(2);
export const Vector3 = z.array(z.number()).length(3);
export const Facing = z.enum(["north", "east", "south", "west"]);

export const MessageBase = z.object({
  type: z.enum(
    [
      "auth",
      "subscribe",
      "unsubscribe",
      "command",
      "turtle_state",
      "turtle_pos",
      "turtle_map",
      "turtle_inventory",
      "turtle_config"
    ]
  ),
});

export const ClientAuth = z.object({
  type: z.literal("auth"),
  key: z.string()
});

export const TurtleAuth = z.object({
  type: z.literal("auth"),
  key: z.string(),
  id: z.number()
})

export const Auth = z.union(
  [
    ClientAuth,
    TurtleAuth
  ]
)

export const Subscribe = z.object({
  type: z.literal("subscribe"),
  id: z.number()
});

export const Unsubscribe = z.object({
  type: z.literal("unsubscribe"),
  id: z.number()
});

export const Command = z.object({
  type: z.literal("command"),
  id: z.number(),
  command: z.string(),
  data: z.any(),
});

export const TurtleFullState = z.object({
  id: z.number(),
  name: z.string(),
  position: Vector3,
  facing: Facing,
  target: Vector3.optional(),
  home: Vector3,
  topLeft: Vector3,
  boundsSize: Vector2,
  fuel: z.number(),
  state: z.string(),
  warnings: z.array(z.string()).or(z.object({}))
})

export const TurtleState = z.object({
  type: z.literal("turtle_state"),
}).merge(TurtleFullState);

export const TurtlePos = z.object({
  type: z.literal("turtle_pos"),
  id: z.number(),
  position: Vector3,
  facing: Facing
});

export const TurtleMap = z.object({
  type: z.literal("turtle_map"),
  id: z.number(),
  map: z.array(z.object({
    x: z.number(),
    z: z.number(),
    b: z.string(),
    a: z.number().optional()
  }))
});

export const TurtleInventory = z.object({
  type: z.literal("turtle_inventory"),
  id: z.number(),
  inventory: z.array(z.object({
    count: z.number(),
    name: z.string(),
  }).partial().or(z.null())).max(16)
});

export const TurtleConfig = z.object({
  type: z.literal("turtle_config"),
  id: z.number(),
  config: z.object({
    item: z.object({
      name: z.string(),
      min: z.number(),
      max: z.number()
    }),
    seed: z.union([
      z.object({
        sameAsItem: z.literal(false),
        name: z.string(),
        min: z.number(),
        max: z.number()
      }),
      z.object({
        sameAsItem: z.literal(true)
      })
    ]),
    home: Vector3,
    block: z.object({
      name: z.string(),
      age: z.number()
    }),
    refuelLevel: z.number(),
    dangerousFuelLevel: z.number(),
    wasteItems: z.array(z.string()).or(z.object({})),
    bounds: z.object({
      max: Vector3,
      min: Vector3
    }),
    fuelLimit: z.union([z.number(), z.literal("unlimited")])
  }).partial()
});

export const TurtleMessages = z.union(
  [
    TurtleState,
    TurtlePos,
    TurtleMap,
    TurtleInventory,
    TurtleConfig
  ]
);

export const ClientMessages = z.union(
  [
    Subscribe,
    Unsubscribe,
    Command
  ]
);

export const Messages = z.union(
  [
    Auth,
    Subscribe,
    Unsubscribe,
    Command,
    TurtleState,
    TurtlePos,
    TurtleMap,
    TurtleInventory,
    TurtleConfig
  ]
);