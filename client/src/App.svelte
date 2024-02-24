<script lang="ts">
  import { onMount } from 'svelte'
  import Warning from './lib/Warning.svelte';
  import type { BasicState, Turtle, WebConfig } from './types';
  import CropFarm from './lib/CropFarm.svelte';
  import json5 from "json5";

  let socket: WebSocket;
  let config: WebConfig;

  fetch("/config.json5").then(async (res) => {
    config = json5.parse(await res.text());
  }).catch((err) => {
    console.error(err);
    alert("Failed to load config: " + err);
  })

  async function auth() {
    await new Promise<void>((res) => { 
      const wait = () => {
        if(config) {
          res();
        } else {
          setTimeout(wait, 100);
        }
      }

      wait();
    });

    console.log(import.meta.env)
    const tempSocket = new WebSocket(config.websocket);
    tempSocket.addEventListener("error", (ev) => {
      console.error(ev);
      loginMessage = "Failed to connect to server";
    })

    tempSocket.addEventListener("open", () => {
      tempSocket.send(JSON.stringify({
        type: "auth",
        key
      }))
    })

    const listener = (ev: MessageEvent) => {
      const message = JSON.parse(ev.data);
      if(message.type == "auth" && message.success) {
        console.log("Successful authentication")
        tempSocket.removeEventListener("message", listener);
        loginMessage = "";
        isAuthed = true;
        socket = tempSocket;

        if(remember) {
          localStorage.setItem("key", key);
        }

        socket.addEventListener("message", (event) => {
          const message = JSON.parse(event.data);
          switch(message.type) {
            case "basic_states": 
              allStates = message.turtleStates;
              break;
            case "turtle_full_state":
              if(currentTurtle?.id == message.turtleState.id) {
                currentTurtle!.state = message.turtleState;
              }
              updateIter++;
              break;
            case "turtle_state":
              if(!currentTurtle) return;
              currentTurtle.state = message.turtleState;
              updateIter++;
              break;
            case "turtle_map":
              if(!currentTurtle) return;
              currentTurtle.map = message.map;
              updateIter++;
              break;
            case "turtle_pos":
              if(!currentTurtle?.state) return;
              currentTurtle.state.position = message.position;
              currentTurtle.state.facing = message.facing;
              updateIter++;
              break;
            case "turtle_inventory":
              if(!currentTurtle) return;
              currentTurtle.inventory = message.inventory;
              invUpdateIter++;
              break;
            case "turtle_config":
              if(!currentTurtle) return;
              currentTurtle.config = message.config;
              updateIter++;
              break;
            case "turtle_full":
              currentTurtle = {
                id: message.of,
                state: message.turtle.state,
                map: message.turtle.map,
                inventory: message.turtle.inventory,
                config: message.turtle.config,
              };
              updateIter++;
              break;
            case "turtle_removed":
              if(currentTurtle?.id == message.id) {
                currentTurtle = undefined;
              }
              break;
          }
        })
      } else {
        loginMessage = "Invalid key";
      }
    }

    tempSocket.addEventListener("message", listener)
  }

  let currentTurtle: Turtle | undefined;
  let allStates: BasicState[] = [];
  let updateIter = 0;
  let invUpdateIter = 0;

  let key = "";
  let loginMessage = "";

  let menuVisible = false;
  let isAuthed = false;
  let remember = false;

  onMount(() => {
    key = localStorage.getItem("key") || "";
    if(key) {
      auth();
    }
  })
</script>

<main class="bg-slate-900 min-h-screen flex flex-row">
  {#if isAuthed && config}
    <main class="w-full">
      <nav class={`h-screen max-xl:w-full w-64 bg-slate-800 border-r-slate-950 border-r-[1px] border-solid py-4 flex flex-col justify-between fixed max-xl:py-2 ${menuVisible ? "" : "max-xl:h-11"} overflow-hidden transition-all duration-500 z-50`}>
        <div class="flex flex-col">
          <div class="text-lg px-4 font-bold pb-2 flex flex-row justify-between items-center">
            { config?.name || "Snowflake Combine" }
            <button class="max-xl:visible invisible" on:click={() => {
              menuVisible = !menuVisible;
            }}>
            {#if !menuVisible}
              <svg xmlns="http://www.w3.org/2000/svg" class="fill-white" height="24" viewBox="0 -960 960 960" width="24"><path d="M120-240v-80h720v80H120Zm0-200v-80h720v80H120Zm0-200v-80h720v80H120Z"/></svg>
            {:else}
              <svg xmlns="http://www.w3.org/2000/svg" class="fill-white" height="24" viewBox="0 -960 960 960" width="24"><path d="m256-200-56-56 224-224-224-224 56-56 224 224 224-224 56 56-224 224 224 224-56 56-224-224-224 224Z"/></svg>
            {/if}
            </button>
          </div>
          <div class="uppercase text-xs opacity-40 px-4 pb-1">Crop Farms</div>
          {#each [...allStates] as turtle}
            <!-- svelte-ignore a11y-click-events-have-key-events -->
            <div class={`flex items-center px-4 py-1 hover:bg-slate-700 ${currentTurtle?.id == turtle.id ? "bg-slate-600" : ""} cursor-pointer`} on:click={() => {
              menuVisible = false;

              if(currentTurtle && currentTurtle.id == turtle.id) return;
              if(currentTurtle) {
                socket.send(JSON.stringify({
                  type: "unsubscribe",
                  id: currentTurtle.id
                }))
              }

              socket.send(JSON.stringify({
                type: "subscribe",
                id: turtle.id
              }))

              currentTurtle = {
                id: turtle.id
              }
            }}>
              {#if turtle.hasWarning}
                <Warning className="fill-orange-500 pr-1" />
              {/if}
              <img src={config.cropIcons[turtle.block] || "/icons/minecraft/textures/item/diamond_hoe.png"} class="w-6 h-6" style="image-rendering: crisp-edges;" alt="turtle" />
              <div class="pl-2 h-6 text-nowrap overflow-hidden whitespace-nowrap text-ellipsis">{turtle.name}</div>
            </div>
          {/each}
        </div>
        <div class="px-2">
          <div class="">Snowflake Combine Web</div>
          <div class="opacity-50 leading-3 text-xs">v2.0.0</div>
          <div class="opacity-50 leading-3 text-xs">
            {#if socket.readyState == 1}
              Connected
            {:else}
              Disconnected
            {/if}
          </div>
        </div>
      </nav>
      <main class={`p-4 w-full max-xl:p-2 max-xl:pl-2 max-xl:pt-[2.25rem] pl-[18rem]`}>
        {#if currentTurtle}
          <CropFarm currentTurtle={currentTurtle} updateIter={updateIter} invUpdateIter={invUpdateIter} socket={socket} config={config} />
        {:else}
          <div class="flex items-center justify-center h-screen">
            <div class="text-2xl font-bold">Select a turtle to view</div>
          </div>
        {/if}
      </main>
    </main>
  {:else}
    <main class="flex flex-col justify-between h-screen w-screen">
      <div></div>
      <div class="flex items-center justify-center  flex-col gap-2">
        <div class="text-2xl font-bold">{ config?.name || "Snowflake Combine" }</div>
        <input type="password" class="bg-slate-600 border-slate-500 border rounded-lg p-1 px-2" bind:value={key} />
        <label class="flex items-center gap-2">
          <input type="checkbox" class="border-slate-500 border rounded-lg p-1 px-2" bind:checked={remember} />
          <span class="white">Remember me</span>
        </label>
        <button class="bg-slate-600 border-slate-500 border rounded-lg p-1 px-2 hover:border-slate-400 transition-colors" on:click={auth}>Log In</button>
        {#if loginMessage}
          <div class="text-red-500">{loginMessage}</div>
        {/if}
      </div>
      <footer class="pb-5 text-center text-slate-500">
        <div class="leading-5">2.0.0-pre1</div>
        <div class="leading-5">Built by Snowflake Software © 2024</div>
      </footer>
    </main>
  {/if}
</main>