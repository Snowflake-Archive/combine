import { WebsocketServer } from "server";

new WebsocketServer();

function shutdown() {
  console.log("Shutting down.")
  WebsocketServer.close();
  process.exit();
}

process.addListener("SIGINT", shutdown);
process.addListener("SIGTERM", shutdown);
