// @ts-nocheck
import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [svelte()],
  build: {
    outDir: "../server/templates/",
    rollupOptions: {
      input: {
        main: resolve(__dirname, "index.html"),
        red_team: resolve(__dirname, "red_team.html"),
      },
    },
  },
});
