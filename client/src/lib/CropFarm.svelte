<script lang="ts">
  import type { Turtle, WebConfig } from "../types";
  import InventoryComponent from "./InventoryComponent.svelte";
  import Map from "./Map.svelte";
  import Warning from "./Warning.svelte";

  export let currentTurtle: Turtle;
  export let updateIter: number;
  export let invUpdateIter: number;
  export let socket: WebSocket;
  export let config: WebConfig;
  
  let updateScreenVisible = false;
  let tortiseURL: string | undefined = undefined;
  let mainURL: string | undefined = undefined;

  function pauseResume() {
    socket.send(JSON.stringify({
      type: "command",
      command: currentTurtle.state?.paused ? "resume" : "pause",
      id: currentTurtle.id
    }))
  }

  function restart() {
    socket.send(JSON.stringify({
      type: "command",
      command: "restart",
      id: currentTurtle.id
    }))
  }

  function sendUpdate() {
    if (!tortiseURL && !mainURL) {
      alert("Please fill out at least one field");
      return;
    }

    socket.send(JSON.stringify({
      type: "command",
      command: "update",
      id: currentTurtle.id,
      data: {
        files: {
          "tortise.lua": tortiseURL,
          "main.lua": mainURL
        }
      }
    }))

    updateScreenVisible = false;
  }
</script>

{#if updateScreenVisible}
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-slate-800 p-6 rounded-xl">
      <h1 class="text-2xl font-bold">Send OTA Update</h1>
      <div class="mt-1">
        <div>Main file URL</div>
        <input placeholder="URL" class="bg-slate-700 px-4 py-1 rounded-xl w-full" bind:value={mainURL} />
      </div>
      <div class="mt-1">
        <div>Tortise file URL</div>
        <input placeholder="URL" class="bg-slate-700 px-4 py-1 rounded-xl w-full" bind:value={tortiseURL} />
      </div>
      <p class="mt-1 max-w-72 leading-4 text-xs">
        Upon clicking "Send", this turtle will receive the update file sent. If the update fails, you will need to install the update manually.
      </p>
      <p class="mt-1 max-w-72 leading-4 text-xs">
        This turtle will also disconnect momentarily while it installs the update.
      </p>
      <div class="flex flex-row gap-2 mt-3">
        <button class="px-3 py-1 bg-green-500 rounded-full pt-[0.125rem] hover:bg-green-400" on:click={sendUpdate}>
          Send
        </button>
        <button class="px-3 py-1 bg-red-500 rounded-full pt-[0.125rem] hover:bg-red-400" on:click={() => updateScreenVisible = false}>
          Cancel
        </button>
      </div>
    </div>
  </div>
{/if}

{#if currentTurtle && currentTurtle.state}
  <div class="flex flex-row gap-8 mt-4 max-xl:flex-col">
    <div class="flex flex-col gap-4 max-w-52 max-xl:max-w-full">
      <header>
        <h1 class="text-2xl font-bold flex flex-row items-center w-full">
          {#if currentTurtle.state.warnings.length > 0}
            <Warning className="fill-orange-500 pr-2 h-8 w-8" />
          {/if}
          {currentTurtle.state.name}
        </h1>

        <h1 class="text-lg leading-5">{currentTurtle.state.state}</h1>
      </header>

      <div class="flex flex-row gap-2">
        <button class={`px-3 py-1  rounded-full pt-[0.125rem] ${currentTurtle?.state.paused ? "hover:bg-green-400 bg-green-500" : "hover:bg-orange-400 bg-orange-500"}`} on:click={pauseResume}>
          {#if currentTurtle?.state.paused}
            Resume
          {:else}
            Pause
          {/if}
        </button>
        <button class="px-3 py-1 bg-red-500 rounded-full pt-[0.125rem] hover:bg-red-400" on:click={restart}>
          Restart
        </button>
      </div>
      
      {#if Array.isArray(currentTurtle.state.warnings)}
        {#each currentTurtle.state.warnings as warning}
          <h3 class="leading-5 text-orange-500 font-bold">{warning}</h3>
        {/each}
      {/if}

      {#if currentTurtle.config?.fuelLimit !== "unlimited" && currentTurtle.config?.fuelLimit}
        <div>
          <header class="font-bold text-md leading-5">Fuel level</header>
          <div class="text-sm leading-3">{currentTurtle.state.fuel} / {currentTurtle.config.fuelLimit}</div>
        </div>
      {/if}

      <InventoryComponent inventory={currentTurtle.inventory} updateIter={invUpdateIter} />
      <div class="grid grid-cols-2">
        <div>
          <header class="uppercase font-bold text-xs leading-4">Version</header>
          <div class="text-xs leading-3">{currentTurtle.config?.version}</div>
        </div>
      </div>

      <button class="px-3 py-1 bg-blue-500 rounded-full pt-[0.125rem] hover:bg-blue-400" on:click={() => updateScreenVisible = true}>
        Send Update...
      </button>
    </div>

    <Map turtle={currentTurtle} updateIter={updateIter} config={config} />
    
  </div>
{:else}
  <div class="flex items-center justify-center h-screen">
    <div class="text-2xl font-bold">Loading...</div>
  </div>
{/if}