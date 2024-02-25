import { WebSocket } from "ws";

export default abstract class Socket {
  public socket: WebSocket;
  public authedAs: "web" | "turtle";

  constructor(client: WebSocket, authAs: "web" | "turtle", _authMessage: unknown) {
    this.socket = client;
    this.authedAs = authAs;
  }

  abstract onClose(): void;
  abstract onMessage(message: unknown): void;
  abstract onAnyMessage(message: unknown): void;

  public close() {
    this.socket.close();
  }

  public send(message: string) {
    this.socket.send(message);
  }
}