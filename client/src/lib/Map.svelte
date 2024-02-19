<script lang="typescript">
  import { onMount } from "svelte";
  import type { Turtle } from "../types";

  export let turtle: Turtle;
  $: updateCanvas();

  export let updateIter = 0;
  $: if(updateIter > 0) { updateCanvas() }

  // extract numeric r, g, b values from `rgb(nn, nn, nn)` string
  function getRgb(color: string): {r: number, g: number, b: number} {
    let [r, g, b] = color.replace('rgb(', '')
      .replace(')', '')
      .split(',')
      .map(str => Number(str));;
    return {
      r,
      g,
      b
    }
  }

  function colorInterpolate(colorA: string, colorB: string, intval: number) {
    const rgbA = getRgb(colorA),
      rgbB = getRgb(colorB);
    const colorVal = (prop: "r" | "g" | "b") =>
      Math.round(rgbA[prop] * (1 - intval) + rgbB[prop] * intval);
    return {
      r: colorVal('r'),
      g: colorVal('g'),
      b: colorVal('b'),
    }
  }

  const cropColors: {[key: string]: [string, string]} = {
    greenscale: ["rgb(255, 0, 0)", "rgb(0, 255, 0)"],
    wheat: ["rgb(10, 69, 0)", "rgb(168, 131, 15)"],
    carrots: ["rgb(30, 73, 23)", "rgb(186, 105, 19)"],
  }

  const blockColors: {[key: string]: {r: number, b: number, g: number}} = {
    sand: { r: 224, g: 207, b: 148 },
    farmland: { r: 54, g: 41, b: 30 },
    water: {r: 0, g: 0, b: 255},
  }
  
  let canvas: HTMLCanvasElement | null;
  $: updateCanvas();

  function updateCanvas() {
    if(!canvas || !turtle || !turtle.state || !turtle.map) return;
    const ctx = canvas.getContext('2d');
    if(!ctx) {
      console.warn("Canvas context not available");
      return;
    };

    const size = Math.min(window.innerWidth, window.innerHeight);

    const cellSizeX = Math.round((1 / turtle.state.boundsSize[0]) * size);
    const cellSizeY = Math.round((1 / turtle.state.boundsSize[1]) * size);
    canvas.width = cellSizeX * turtle.state.boundsSize[0];
    canvas.height = cellSizeY * turtle.state.boundsSize[1];

    const turtleImage = new Image(cellSizeX, cellSizeY);
    turtleImage.src = `/turtle_${turtle.state.facing}.png`
    turtleImage.onload = () => {
      if(!turtle?.state) return;

      ctx.imageSmoothingEnabled = false;
      const x = Math.round((turtle.state.position[0] - turtle.state.topLeft[0])) * cellSizeX;
      const y = Math.round((turtle.state.position[2] - turtle.state.topLeft[2])) * cellSizeY;
      ctx.drawImage(turtleImage, x, y, cellSizeX, cellSizeY);
      ctx.imageSmoothingEnabled = true;
      ctx.restore();
    }

    const homeImage = new Image(cellSizeX, cellSizeY);
    homeImage.src = "/home.png"
    homeImage.onload = () => {
      if(!turtle?.state) return;

      const x = Math.round((turtle.state.home[0] - turtle.state.topLeft[0])) * cellSizeX;
      const y = Math.round((turtle.state.home[2] - turtle.state.topLeft[2])) * cellSizeY;
      ctx.drawImage(homeImage, x, y, cellSizeX, cellSizeY);
    }

    if(turtle.state.target) {
      const targetImage = new Image(cellSizeX, cellSizeY);
      targetImage.src = "/target.png"
      targetImage.onload = () => {
        if(!turtle?.state?.target) return;

        const x = Math.round((turtle.state.target[0] - turtle.state.topLeft[0])) * cellSizeX;
        const y = Math.round((turtle.state.target[2] - turtle.state.topLeft[2])) * cellSizeY;
        ctx.drawImage(targetImage, x, y, cellSizeX, cellSizeY);
      }
    }

    turtle.map.forEach((item) => {
      if(!turtle?.state || !canvas) return;

      const x = Math.round((turtle.state.home[0] + item.x) - turtle.state.topLeft[0]) * cellSizeX;
      const y = Math.round((turtle.state.home[2] + item.z) - turtle.state.topLeft[2]) * cellSizeY;
      if(x < 0 || y < 0) return;
      if(x > canvas.width || y > canvas.height) return;

      const cropColor = item.a !== undefined ? cropColors[item.b] : undefined
      const blockColor = blockColors[item.b]

      ctx.beginPath();
      const colorData = 
        cropColor
          ? colorInterpolate(cropColors[item.b][0], cropColors[item.b][1], item.a) 
          : blockColor
          ? blockColor
          : { r: 0, g: 0, b: 0 };
      const fillStyle =`rgb(${colorData.r}, ${colorData.g}, ${colorData.b})`;
      ctx.fillStyle = fillStyle
      ctx.rect(x, y, cellSizeX, cellSizeY);
      ctx.fill();

      if(item.a == 1) {
        ctx.strokeStyle = "rgba(0, 255, 0, 0.5)";
        ctx.stroke();
      }
    })
  }

  onMount(() => {
    updateCanvas();
  })
</script>

<canvas bind:this={canvas} class="max-w-[512px] max-h-[512px] w-full h-full bg-slate-800" width={512} height={512} style="image-rendering: optimizeSpeed;"></canvas>
