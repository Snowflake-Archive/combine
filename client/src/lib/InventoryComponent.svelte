<script lang="ts">
  import { onMount } from "svelte";
  import type { Inventory, WebConfig } from "../types";

  let inventoryItems = new Array<
  { 
    count: number;
    name: string;
    rawName: string;
    displayName: string; 
  } | undefined>(16);
  inventoryItems.fill(undefined);
  Object.seal(inventoryItems);

  export let inventory: Inventory | undefined;
  $: updateInventory();

  export let updateIter = 0;
  $: if(updateIter > 0) { updateInventory() }

  export let config: WebConfig;

  function updateInventory() {
    if(!inventory) return;

    for(let i = 0; i < 16; i++) {
      if(inventory[i]) {
        inventoryItems[i] = inventory[i]
      } else {
        inventoryItems[i] = undefined;
      }
    }
  }

  function filePathFromName(rawName: string) {
    let [type, namespace, name1, name2] = rawName.split(".");
    if(config.nameOverrides[name1]) name1 = config.nameOverrides[name1];
    return `/icons/${namespace}/textures/${type}/${name2 || name1}.png`;
  }

  onMount(() => {
    updateInventory()
  });

</script>
<div>
  <div class="inline-grid grid-cols-4 border-t-2 border-l-2 border-slate-700">
    {#each inventoryItems as item}
      <div class="flex flex-col items-center w-[52px] h-[52px] bg-slate-400 border-r-2 border-b-2 border-slate-700">
        <div class="relative w-full h-full">
          {#if item}
            {#if item.count > 1} 
              <div class="absolute right-[2px] bottom-[2px] px-[0.125rem] rounded text-white text-xs bg-[rgba(0,0,0,0.5)]">{item.count}</div>
            {/if}
            <img src={filePathFromName(item.rawName)} alt={item.name} class="w-full h-full" style="image-rendering: crisp-edges;" />
          {/if}
        </div>
      </div>
    {/each}
  </div>
</div>