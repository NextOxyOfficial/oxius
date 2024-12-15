// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2024-04-03",
  devtools: { enabled: true },
  ssr: false,
  css: ["~/assets/css/main.css"],
  modules: ["@nuxt/ui", "@nuxt/image"],
  app: {
    buildAssetsDir: "/static/frontend",
  },
});
