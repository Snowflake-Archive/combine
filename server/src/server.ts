import ws, { WebSocket } from "ws";
import { Auth, MessageBase, TurtleAuth } from "schemas";
import { ClientSocket } from "clientSocket";
import { TurtleSocket } from "turtleSocket";
import Socket from "socket";

const port = parseInt(process.env.PORT!) || 5678;

export class WebsocketServer {
  public static server: ws.Server = new ws.Server({ port: Number(port), perMessageDeflate: false });
  public static clientSockets: ClientSocket[] = [];
  public static turtleSockets: TurtleSocket[] = [];
  public static totalConnections = 0;

  constructor() {
    WebsocketServer.server.on("listening", () => {
      console.log(`Server listening on port ${port}`);
    });
    WebsocketServer.server.on("connection", this.handleNewConnection)
  }

  public static close() {
    WebsocketServer.server.close();
  }

  private handleNewConnection(socket: WebSocket) {
    const connection = WebsocketServer.totalConnections;
    console.log(`New connection (#${connection})`);
    WebsocketServer.totalConnections++;

    socket.once("close", () => {
      console.log(`Connection closed (#${connection})`);
    });

    socket.once("message", (rawMessage: Buffer) => {
      try { 
        const _message = JSON.parse(rawMessage.toString());
        const data = Auth.safeParse(_message);

        if (!data.success) throw new Error("Invalid message");

        const message = data.data;

        if (message.key == process.env.WEB_TOKEN) {
          const clientSocket = new ClientSocket(socket, message);
          WebsocketServer.clientSockets.push(clientSocket);
          WebsocketServer.prepSocket(clientSocket);
          console.log(`Connection authed as web (#${connection})`);
        } else if (message.key == process.env.TURTLE_TOKEN) {
          const turtleSocket = new TurtleSocket(socket, TurtleAuth.parse(message));
          WebsocketServer.turtleSockets.push(turtleSocket);
          WebsocketServer.prepSocket(turtleSocket);
          console.log(`Connection authed as turtle (#${connection})`);
        } else {
          throw new Error("Invalid key");
        }
      } catch (e) {
        socket.close();
      }
    })
  }

  public static getAllBasicStates() {
    return WebsocketServer.turtleSockets
      .filter((item) => {
        return item.state !== undefined && item.config !== undefined;
      })
      .map((item) => { 
        return {
          id: item.id,
          hasWarning: typeof (item.state.warnings) === "object" ? false : true,
          name: item.state.name,
          block: item.config?.block?.name,
        };
      })
  }

  public static prepSocket(socket: Socket) {
    try {
      socket.socket.on("message", (rawMessage: unknown) => {
        try {
          const message = JSON.parse(rawMessage as string);

          if (MessageBase.safeParse(message).success) {
            socket.onMessage(message);

            WebsocketServer.clientSockets.forEach((client) => {
              client.onAnyMessage(message);
            })

            WebsocketServer.turtleSockets.forEach((turtle) => {
              turtle.onAnyMessage(message);
            })
          }
        } catch (e) {
          console.error(e);
        }
      });

      socket.socket.on("close", () => {
        socket.onClose();
      });
    } catch (e) {
      console.error(e);
    }
  }
}
