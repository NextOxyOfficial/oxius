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
  runtimeConfig: {
    public: {
      baseURL: "http://127.0.0.1:8000",
    },
  },
  $production: {
    runtimeConfig: {
      public: {
        baseURL: "https://adsyclub.com",
      },
    },
  },
  image: {
    dir: "public",
  },
});
