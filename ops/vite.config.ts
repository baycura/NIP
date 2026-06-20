import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

// Visual identity is intentionally minimal here — the NIP cold/editorial
// aesthetic is layered later via design tokens (see src/styles/tokens.css).
export default defineConfig({
  // Served at root in dev/preview. Deployment subpath (e.g. GitHub Pages) is
  // deferred; set this + index.html refs when we wire hosting.
  base: "/",
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.svg"],
      manifest: {
        name: "NOT IN PARIS — Operations",
        short_name: "NIP Ops",
        description: "NIP business operations: stock, POS, kitchen, tasks.",
        lang: "tr",
        dir: "ltr",
        display: "standalone",
        orientation: "portrait",
        background_color: "#ffffff",
        theme_color: "#ffffff",
        icons: [
          { src: "icon-192.png", sizes: "192x192", type: "image/png", purpose: "any maskable" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png", purpose: "any maskable" }
        ]
      }
    })
  ],
  server: {
    host: true,
    port: 5173
  }
});
