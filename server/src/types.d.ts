import { Facing, TurtleConfig, TurtleFullState, TurtleInventory, TurtleMap, TurtleState, Vector2, Vector3 } from "schemas";
import WebSocket from "ws";
import { z } from "zod";

export type Vector3 = z.infer<typeof Vector3>;
export type Vector2 = z.infer<typeof Vector2>
export type Facing = z.infer<typeof Facing>

// Server to client messages
export type BasicState = {
  id: number;
  warning: boolean;
  name: string;
};

export type FullState = z.infer<typeof TurtleFullState>;
export type TurtleMap = z.infer<typeof TurtleMap>["map"];
export type Inventory = z.infer<typeof TurtleInventory>["inventory"];
export type Config = z.infer<typeof TurtleConfig>["config"];