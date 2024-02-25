import { WebsocketServer } from "server";

new WebsocketServer();

process.on("SIGINT", () => {
  WebsocketServer.close();
  process.exit();
});

process.on("SIGTERM", () => {
  WebsocketServer.close();
  process.exit();
});