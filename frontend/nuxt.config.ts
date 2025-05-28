// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2024-04-03",
  devtools: { enabled: true },
  colorMode: {
    preference: "light",
  },  ssr: false,
  
  css: ["~/assets/css/main.css"],
  modules: [
    "@nuxt/ui",
    "@nuxt/image",
    "@nuxtjs/i18n",
    "nuxt-tiptap-editor",
    "nuxt-aos",
    "@nuxtjs/google-fonts",
    "@pinia/nuxt",
  ],

  pinia: {
    storesDirs: ["./store/**"],
  },

  tiptap: {
    prefix: "Tiptap", //prefix for Tiptap imports, composables not included
  },
  i18n: {
    vueI18n: "~/i18n.config.ts",
    bundle: {
      optimizeTranslationDirective: false,
    },
  },
  googleFonts: {
    families: {
      "Anek+Bangla": { wght: "200..800" },
    },
    display: "swap", // Optional: This is a good practice to improve performance
  },
  app: {
    buildAssetsDir: "/static/frontend/",
    head: {
      title:
        "AdsyClub – Bangladesh's 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
      meta: [
        {
          name: "description",
          content:
            "AdsyClub – Bangladesh's 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
        },
        { name: "viewport", content: "width=device-width, initial-scale=1" },
        // PWA meta tags
        { name: "theme-color", content: "#10b981" },
        { name: "apple-mobile-web-app-capable", content: "yes" },
        { name: "apple-mobile-web-app-status-bar-style", content: "black-translucent" },
        { name: "apple-mobile-web-app-title", content: "AdsyClub" },
        { name: "mobile-web-app-capable", content: "yes" },
        { name: "application-name", content: "AdsyClub" },
      ],      link: [
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
        // PWA manifest
        {
          rel: "manifest",
          href: "/manifest.json",
        },
        // Apple touch icons
        {
          rel: "apple-touch-icon",
          href: "/static/frontend/icons/icon-192x192.png",
        },
        {
          rel: "apple-touch-icon",
          sizes: "152x152",
          href: "/static/frontend/icons/icon-152x152.png",
        },
        {
          rel: "apple-touch-icon",
          sizes: "180x180",
          href: "/static/frontend/icons/icon-192x192.png",
        },
        {
          rel: "apple-touch-startup-image",
          href: "/static/frontend/icons/splash-640x1136.png",
          media: "(device-width: 320px) and (device-height: 568px) and (-webkit-device-pixel-ratio: 2)",
        },
        // Swiper CSS
        {
          rel: "stylesheet",
          href: "https://cdn.jsdelivr.net/npm/swiper@9/swiper-bundle.min.css",
        },
      ],
      script: [
        {
          src: "https://cdn.jsdelivr.net/npm/swiper@9/swiper-bundle.min.js",
          defer: true,
        },
      ],
    },
  },  runtimeConfig: {
    public: {
      baseURL: "http://127.0.0.1:8000",
      cookieOptions: {
        default: {
          httpOnly: false,
          secure: false, // Set to true in production with HTTPS
          sameSite: 'lax',
          maxAge: 60 * 60 * 24 * 30, // 30 days to match JWT token and session lifetime
        }
      }
    },
  },  $production: {
    runtimeConfig: {
      public: {
        baseURL: "https://adsyclub.com",
        cookieOptions: {
          default: {
            httpOnly: false,
            secure: true, // Enable secure cookies in production with HTTPS
            sameSite: 'lax',
            maxAge: 60 * 60 * 24 * 30, // 30 days to match JWT token and session lifetime
          }
        }
      },
    },
  },
  image: {
    dir: "/static/frontend/",
  },
  pages: true, // Enable file-based routing
  
});
