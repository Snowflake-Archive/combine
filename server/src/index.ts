import WebSocket from "ws";
import ws from "ws";
import { ClientSocket, Config, FullState, Inventory, Socket, TurtleMap, TurtleSocket } from "./types";
import "dotenv/config";

const port = process.env.PORT || 5678;
const server = new ws.Server({ port: Number(port), perMessageDeflate: false });
const clientSockets: ClientSocket[] = [];
const turtleSockets: TurtleSocket[] = [];

const states = new Map<number, FullState>();
const maps = new Map<number, TurtleMap>();
const inventories = new Map<number, Inventory>();
const configs = new Map<number, Config>();

/*
  Turtle State
  {
    type: "turtle",
    name: "turtle1",
    id: 1234,
    position: [0, 0, 0],
    facing: "east",
    target: [0, 0, 0],
    home: [0, 0, 0],
    inventory: {
      {
        name: "cobblestone",
        count: 64
      },
      ...
    },
    topLeft: [0, 0],
    boundsSize: [16, 16],
    fuel: 0,
    status: "idle"
  }
*/

const getAllBasicStates = () => {
  return Array.from(states.values()).map((item) => {
    return {
      id: item.id,
      hasWarning: item.warnings ? item.warnings.length > 0 : false,
      name: item.name,
      block: configs.get(item.id)?.block.name,
    };
  })
}

server.on("connection", (socket: Socket) => {
  console.log("New connection");

  socket.on("close", () => {
    console.log("Connection closed");
    if (socket.authedAs === "web") {
      clientSockets.splice(clientSockets.indexOf(socket as ClientSocket), 1);
    } else if (socket.authedAs === "turtle") {
      turtleSockets.splice(turtleSockets.indexOf(socket as TurtleSocket), 1);
      states.delete((socket as TurtleSocket).id);
      maps.delete((socket as TurtleSocket).id);
      inventories.delete((socket as TurtleSocket).id);

      clientSockets.forEach((client) => {
        if (client.subscriptions.includes((socket as TurtleSocket).id)) {
          client.subscriptions.splice(client.subscriptions.indexOf((socket as TurtleSocket).id), 1);

          client.send(
            JSON.stringify({
              type: "turtle_removed",
              id: (socket as TurtleSocket).id,
            })
          );
        }

        client.send(
          JSON.stringify({
            type: "basic_states",
            turtleStates: getAllBasicStates()
          })
        );
      })
    }
  });

  socket.on("message", (message: any) => {
    const data = JSON.parse(message);
    switch (data.type) {
      case "auth":
        if (data.key == process.env.WEB_TOKEN) {
          socket.authedAs = "web";
          clientSockets.push(socket as ClientSocket);
          socket.send(
            JSON.stringify({
              type: "auth",
              success: true,
              message: "web",
            })
          );

          setTimeout(() => {
            socket.send(
              JSON.stringify({
                type: "basic_states",
                of: data.id,
                turtleStates: getAllBasicStates()
              })
            );
          }, 500);

          console.log("Web client connected", socket.authedAs)

          if(socket.authedAs == "web") socket.subscriptions = [];
        } else if (data.key == process.env.TURTLE_TOKEN) {
          socket.authedAs = "turtle";
          (socket as TurtleSocket).id = data.id;
          turtleSockets.push(socket as TurtleSocket);

          console.log("Turtle connected", socket.authedAs, data.id)

          socket.send(
            JSON.stringify({
              type: "auth",
              success: true,
              message: "turtle",
            })
          );
        } else {
          socket.send(
            JSON.stringify({
              type: "auth",
              success: false,
            })
          );
          socket.close();
        }
        break;
      case "subscribe":
        if (socket.authedAs === "web") {
          socket.subscriptions.push(data.id);

          if (states.has(data.id)) {
            socket.send(
              JSON.stringify({
                type: "turtle_full",
                of: data.id,
                turtle: {
                  state: states.get(data.id),
                  map: maps.get(data.id),
                  inventory: inventories.get(data.id),
                  config: configs.get(data.id),
                },
              })
            );
          }
        }
        break;
      case "unsubscribe":
        if (socket.authedAs === "web") {
          socket.subscriptions.splice(socket.subscriptions.indexOf(data.id), 1);
        }
        break;
      case "command":
        if (socket.authedAs === "web") {
          const turtles = turtleSockets.filter((t) => t.id === data.id && t.readyState === WebSocket.OPEN)
          const turtle = turtles[0];
          if (turtle) {
            turtle.send(
              JSON.stringify({
                type: "command",
                id: data.id,
                command: data.command,
                data: data.data || {},
              })
            );
          }
        }
        break;
      case "turtle_state":
        if (socket.authedAs === "turtle") {
          socket.id = data.id;
          const newState: any = states.get(data.id) || { id: data.id };
          Object.keys(data).forEach((_key) => {
            const key = _key as any;
            if (key !== "type") {
              newState[key] = data[key] as any;
            }
          });

          states.set(data.id, newState as any);

          clientSockets.forEach((client) => {
            client.send(
              JSON.stringify({
                type: "basic_states",
                turtleStates: getAllBasicStates()
              })
            );

            if (!client.subscriptions.includes(data.id)) return;

            client.send(
              JSON.stringify({
                type: "turtle_state",
                of: data.id,
                turtleState: states.get(data.id),
              })
            );
          });
        }
        break;
      case "turtle_pos":
        if (socket.authedAs === "turtle") {
          const newState: FullState = states.get(data.id) || { id: data.id };
          newState.position = data.position;
          newState.facing = data.facing;
          states.set(data.id, newState);

          clientSockets.forEach((client) => {
            if (!client.subscriptions.includes(data.id)) return;

            client.send(
              JSON.stringify({
                type: "turtle_pos",
                of: data.id,
                position: data.position,
                facing: data.facing,
              })
            );
          });
        }
        break;
      case "turtle_map":
        if (socket.authedAs === "turtle") {
          maps.set(data.id, data.map);

          clientSockets.forEach((client) => {
            if (!client.subscriptions.includes(data.id)) return;

            client.send(
              JSON.stringify({
                type: "turtle_map",
                of: data.id,
                map: data.map,
              })
            );
          });
        }
        break;
      case "turtle_inventory":
        if (socket.authedAs === "turtle") {
          inventories.set(data.id, data.inventory);

          clientSockets.forEach((client) => {
            if (!client.subscriptions.includes(data.id)) return;

            client.send(
              JSON.stringify({
                type: "turtle_inventory",
                of: data.id,
                inventory: data.inventory,
              })
            );
          });
        }
        break;
      case "turtle_config":
        if (socket.authedAs === "turtle") {
          configs.set(data.id, data.config);

          clientSockets.forEach((client) => {
            if (!client.subscriptions.includes(data.id)) return;

            client.send(
              JSON.stringify({
                type: "turtle_config",
                of: data.id,
                config: data.config,
              })
            );
          });
        }
        break;
        
    }
  });

  socket.on("error", (err) => {
    console.error(err);
  });
});

server.on("error", (err) => {
  console.error(err);
})

server.on("listening", () => {
  console.log("Server listening on port", port);
});