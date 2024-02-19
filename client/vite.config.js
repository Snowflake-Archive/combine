import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import { vitePreprocess } from "@sveltejs/vite-plugin-svelte";
import autoPreprocess from "svelte-preprocess";
import typescript from "@rollup/plugin-typescript";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    svelte({ preprocess: autoPreprocess() }),
    typescript({ sourceMap: true }),
  ],
  preprocess: vitePreprocess(),
});
