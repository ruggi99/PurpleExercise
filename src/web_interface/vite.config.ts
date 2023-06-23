// @ts-nocheck
import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [svelte()],
  build: {
    outDir: "dist",
    rollupOptions: {
      input: {
        main: resolve(__dirname, "src/index.html"),
        red_team: resolve(__dirname, "src/red_team.html"),
      },
      output: {
        assetFileNames: "static/assets/[name]-[hash][extname]",
        chunkFileNames: "static/assets/[name]-[hash].js",
        entryFileNames: "static/assets/[name]-[hash].js",
      }
    },
  },
});
