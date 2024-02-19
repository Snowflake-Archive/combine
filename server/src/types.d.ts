import WebSocket from "ws";

export type ClientSocket = WebSocket & {
  authedAs: "web";
  subscriptions: number[];
}
export type TurtleSocket = WebSocket & {
  authedAs: "turtle";
  id: number;
}
export type Socket = ClientSocket |  TurtleSocket;

// Primitive types for the client and server to use
export type Message = {
  type: string;
};

export type Vector3 = [number, number, number];
export type Vector2 = [number, number];
export type Facing = "north" | "south" | "east" | "west";

// Server to client messages
export type BasicState = {
  id: number;
  warning: boolean;
  name: string;
};

export type FullState = {
  name?: string;
  id: number;
  position?: Vector3;
  facing?: Facing;
  target?: Vector3;
  home?: Vector3;
  topLeft?: Vector3;
  boundsSize?: Vector2;
  fuel?: number;
  state?: string;
  warnings?: string[];
};

export type TurtleMap = {
  x: number;
  z: number;
  b: string;
  a: number;
}[];

export type Inventory = { count: number; name: string; nbt?: string }[];

export type Config = {
  item: {
    name: string;
    min: number;
    max: number;
  };
  seed:
    | {
        sameAsItem: false;
        name: string;
        min: number;
        max: number;
      }
    | { sameAsItem: true };
  home: Vector3;
  block: {
    name: string;
    age: number;
  };
  refuelLevel: number;
  dangerousFuelLevel: number;
  wasteItems: string[];
  bounds: {
    max: Vector3;
    min: Vector3;
  };
  fuelLimit: number | "unlimited";
};
