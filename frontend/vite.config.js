import { defineConfig } from "vite";
import elm from "vite-plugin-elm";

export default defineConfig({
  plugins: [elm()],
  server: {
    proxy: {
      "/api": "http://localhost:8000",
    },
  },
});
