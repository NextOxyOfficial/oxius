// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2024-04-03",
  devtools: { enabled: true },
  colorMode: {
    preference: "light",
  },
  ssr: false,
  css: ["~/assets/css/main.css"],
  modules: ["@nuxt/ui", "@nuxt/image", "@nuxtjs/i18n", "nuxt-tiptap-editor", "nuxt-aos"],
  tiptap: {
    prefix: "Tiptap", //prefix for Tiptap imports, composables not included
  },
  i18n: {
    vueI18n: "./i18n.config.ts",
  },
  app: {
    buildAssetsDir: "/static/frontend/",
    head: {
      title: "AdsyClub | Earn Quick Money & Simplify Daily Life",
      meta: [
        { name: "description", content: "AdsyClub | Earn Quick Money & Simplify Daily Life" },
        { name: "viewport", content: "width=device-width, initial-scale=1" },
      ],
      link: [
        {
          rel: "icon",
          type: "image/x-icon",
          href: "/static/frontend/favicon.png",
          sizes: "32x32",
        },
        {
          rel: "icon",
          type: "image/png",
          href: "/static/frontend/favicon.png",
          sizes: "180x180",
        },
      ],
    },
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
    dir: "/static/frontend/",
  },
});
