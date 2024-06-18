import { WebsocketServer } from "server";
import Socket from "socket";
import { ClientAuth, ClientMessages, Messages } from "schemas";
import WebSocket from "ws";
import { z } from "zod";

export class ClientSocket extends Socket {
  public subscriptions: number[] = [];

  constructor(socket: WebSocket, authMessage: z.infer<typeof ClientAuth>) {
    super(socket, "web", authMessage);

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
          turtleStates: WebsocketServer.getAllBasicStates()
        })
      );
    }, 500);
  }

  onMessage(_message: unknown): void {
    if (!ClientMessages.safeParse(_message).success) return;
    const message = _message as z.infer<typeof ClientMessages>;

    if (message.type == "subscribe") {
      const turtle = WebsocketServer.turtleSockets.find((turtle) => turtle.id === message.id);
      if (!turtle || !turtle.state || !turtle.map || !turtle.inventory || !turtle.config) return;
        
      this.subscriptions.push(message.id);
      
      this.send(
        JSON.stringify({
          type: "turtle_full",
          of: message.id,
          turtle: {
            state: turtle.state,
            map: turtle.map,
            inventory: turtle.inventory,
            config: turtle.config,
            yields: turtle.yields,
          },
        })
      );
    } else if (message.type == "unsubscribe") {
      this.subscriptions.splice(this.subscriptions.indexOf(message.id), 1);
    } else if (message.type == "command") {
      const turtle = WebsocketServer.turtleSockets.find((t) => t.id === message.id);
      if (turtle) {
        turtle.socket.send(
          JSON.stringify({
            type: "command",
            id: message.id,
            command: message.command,
            data: message.data || {},
          })
        );
      }
    }
  }

  onAnyMessage(_message: unknown): void {
    if (!Messages.safeParse(_message).success) return;
    const message = _message as z.infer<typeof Messages>;

    if(message.type == "turtle_state") {
      
    }
  }

  onClose(): void {
    // Remove this socket from the list of client sockets
    WebsocketServer.clientSockets.splice(WebsocketServer.clientSockets.indexOf(this), 1);
  }
}