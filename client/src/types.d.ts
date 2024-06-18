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
  hasWarning: boolean;
  name: string;
  block: string;
};

export type FullState = {
  name: string;
  id: number;
  position: Vector3;
  facing: Facing;
  target: Vector3?;
  home: Vector3;
  topLeft: Vector3;
  boundsSize: Vector2;
  fuel: number;
  state: string;
  warnings: string[];
  paused: boolean;
};

export type TurtleMap = {
  x: number;
  z: number;
  b: string;
  a: number;
}[];

export type Inventory = {
  count: number;
  name: string;
  rawName: string;
  displayName: string;
}[];

//  Messages

export type BasicStateMessage = {
  type: "basic_states";
  turtleStates: BasicState[];
};

export type FullStateMessage = {
  type: "turtle_full_state";
  of: number;
} & FullState;

export type FullPositionMessage = {
  type: "turtle_pos";
  of: number;
  position: Vector3;
  facing: Facing;
};

export type FullMapMessage = {
  type: "turtle_map";
  of: number;
  target: Vector3;
};

export type FullInventoryMessage = {
  type: "turtle_inventory";
  of: number;
  inventory: Inventory[];
};

export type Turtle = {
  id: number;
  state?: FullState;
  map?: TurtleMap;
  inventory?: Inventory;
  config?: Config;
  yields?: {
    [key: number]: {
      items: number;
      seeds: number;
    };
  };
};

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
  version: string;
};

export type WebConfig = {
  websocket: string;
  name: string
  cropColors: { [key: string]: string };
  cropIcons: { [key: string]: string };
  blockColors: { [key: string]: string };
  nameOverrides: { [key: string]: string };
}