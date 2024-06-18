<script lang="ts">
  import { onMount } from "svelte";
  import type { Turtle } from "../types";
  import Chart from "chart.js/auto";
  import "chartjs-adapter-date-fns";
  import App from "../App.svelte";

  export let currentTurtle: Turtle;
  export let updateIter: number;
  $: if (updateIter > 0) {
    updateCanvas();
  }

  let chart: Chart;

  const updateCanvas = () => {
    if (!canvas) return;
    if (!currentTurtle.yields) return;
    if (!chart) return;

    const keys = Object.keys(currentTurtle.yields).map(
      (k) => new Date((k as any) / 1),
    );
    const values = Object.values(currentTurtle.yields);

    chart.data = {
      labels: keys,
      datasets: [
        {
          label: "Items Produced",
          data: values.map((state) => state.items),
          borderColor: "rgb(255, 99, 132)",
          tension: 0.1,
        },
        {
          label: "Seeds Produced",
          data: values.map((state) => state.seeds),
          borderColor: "rgb(54, 162, 235)",
          tension: 0.1,
        },
      ],
    };

    chart.update();
  };

  let canvas: HTMLCanvasElement | null;
  $: updateCanvas();

  onMount(() => {
    chart = new Chart(canvas!, {
      type: "line",
      data: {
        labels: [],
        datasets: [
          {
            label: "Items Produced",
            data: [],
            borderColor: "rgb(255, 99, 132)",
            tension: 0.1,
          },
          {
            label: "Seeds Produced",
            data: [],
            borderColor: "rgb(54, 162, 235)",
            tension: 0.1,
          },
        ],
      },
      options: {
        scales: {
          x: {
            type: "time",
          },
          y: {
            beginAtZero: true,
          },
        },
        animation: {
          duration: 0,
        },
      },
    });

    chart.resize();
  });
</script>

<canvas
  bind:this={canvas}
  id="yields"
  class="max-w-full max-h-[512px] flex-shrink h-full bg-slate-800"
  style="image-rendering: optimizeSpeed;"
></canvas>
