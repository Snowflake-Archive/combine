import { WebsocketServer } from "server";
import Socket from "socket";
import { TurtleAuth, TurtleMessages } from "schemas";
import { Config, FullState, Inventory, TurtleMap } from "types";
import WebSocket from "ws";
import { z } from "zod";

export class TurtleSocket extends Socket {
  public state: FullState;
  public map: TurtleMap;
  public inventory: Inventory;
  public config: Config;
  public id: number;

  constructor(socket: WebSocket, authMessage: z.infer<typeof TurtleAuth>) {
    super(socket, "turtle", authMessage);

    socket.send(
      JSON.stringify({
        type: "auth",
        success: true,
        message: "turtle",
      })
    );

    this.id = authMessage.id;
  }

  onMessage(_message: unknown): void {
    const test = TurtleMessages.safeParse(_message)
    if (!test.success) {
      //console.log((_message as any).type)
      //console.log(test.error);
      return;
    }
    const message = _message as z.infer<typeof TurtleMessages>;

    if (message.type === "turtle_config") {
      this.config = message.config;
    } else if (message.type === "turtle_inventory") {
      this.inventory = message.inventory;

      this.transmitToSubscribers(JSON.stringify({
        type: "turtle_inventory",
        of: this.id,
        inventory: this.inventory,
      }))
    } else if (message.type === "turtle_map") {
      this.map = message.map;

      this.transmitToSubscribers(JSON.stringify({
        type: "turtle_map",
        of: this.id,
        map: this.map,
      }));
    } else if (message.type === "turtle_state") {
      this.state = message;

      WebsocketServer.clientSockets.forEach((client) => {
        client.socket.send(
          JSON.stringify({
            type: "basic_states",
            turtleStates: WebsocketServer.getAllBasicStates()
          })
        );
      });

      this.transmitToSubscribers(JSON.stringify({
        type: "turtle_state",
        of: this.id,
        turtleState: this.state,
      }));
    } else if (message.type === "turtle_pos") {
      if (this.state === undefined) return;
      this.state.position = message.position;
      this.state.facing = message.facing;

      this.transmitToSubscribers(JSON.stringify({
        type: "turtle_pos",
        of: this.id,
        position: message.position,
        facing: message.facing,
      }));
    }
  }

  onAnyMessage(_message: unknown): void {
  }

  onClose(): void {
    this.transmitToSubscribers(JSON.stringify({
      type: "turtle_removed",
      id: this.id,
    }))

    // Remove this socket from the list of turtle sockets
    WebsocketServer.turtleSockets.splice(WebsocketServer.turtleSockets.indexOf(this), 1);

    WebsocketServer.clientSockets.forEach((client) => {
      client.socket.send(
        JSON.stringify({
          type: "basic_states",
          turtleStates: WebsocketServer.getAllBasicStates()
        })
      );
    });
  }

  private transmitToSubscribers(message: string) {
    WebsocketServer.clientSockets.forEach((client) => {
      if (client.subscriptions.includes(this.id)) {
        client.send(message);
      }
    });
  }
}