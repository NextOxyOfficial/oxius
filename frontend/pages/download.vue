<template>
  <PublicSection>
    <UContainer>
      <div class="relative overflow-hidden rounded-[32px] bg-slate-950 text-white min-h-[38vh]">
        <div class="absolute inset-0 bg-[radial-gradient(circle_at_top_left,_rgba(16,185,129,0.24),_transparent_34%),radial-gradient(circle_at_bottom_right,_rgba(59,130,246,0.24),_transparent_30%)]"></div>
        <div class="absolute inset-0 opacity-20 bg-[linear-gradient(135deg,transparent_0%,transparent_45%,rgba(255,255,255,0.12)_50%,transparent_55%,transparent_100%)]"></div>

        <div class="relative grid gap-8 lg:grid-cols-[1.2fr_0.8fr] p-6 md:p-10 lg:p-14 items-center">
          <div class="space-y-6">
            <div class="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-4 py-2 text-sm text-emerald-200 backdrop-blur">
              <span class="h-2 w-2 rounded-full bg-emerald-400"></span>
              Smart app redirect is active
            </div>

            <div class="space-y-4 max-w-2xl">
              <h1 class="text-3xl md:text-5xl font-semibold tracking-tight leading-tight">
                Open AdsyClub in the right place for this device.
              </h1>
              <p class="text-base md:text-lg text-slate-300 leading-relaxed">
                Mobile visitors are redirected to the right store automatically. If the app is already installed, use the direct app button below and jump in immediately.
              </p>
            </div>

            <div class="flex flex-wrap gap-3">
              <button
                @click="goToStore"
                class="inline-flex items-center justify-center gap-2 rounded-2xl bg-emerald-400 px-5 py-3 font-semibold text-slate-950 transition hover:bg-emerald-300"
              >
                <UIcon name="i-heroicons-arrow-top-right-on-square" class="w-5 h-5" />
                {{ primaryActionLabel }}
              </button>
              <button
                @click="openInstalledApp"
                class="inline-flex items-center justify-center gap-2 rounded-2xl border border-white/20 bg-white/10 px-5 py-3 font-semibold text-white transition hover:bg-white/15"
              >
                <UIcon name="i-heroicons-device-phone-mobile" class="w-5 h-5" />
                Open Installed App
              </button>
              <button
                @click="downloadAndroidApp"
                class="inline-flex items-center justify-center gap-2 rounded-2xl border border-white/15 px-5 py-3 font-semibold text-slate-200 transition hover:bg-white/10"
              >
                <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5" />
                Direct Android APK
              </button>
            </div>

            <div class="flex flex-wrap gap-3 text-sm text-slate-300">
              <div class="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
                Detected device: <span class="font-semibold text-white">{{ detectedDeviceLabel }}</span>
              </div>
              <div class="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
                Redirect status: <span class="font-semibold text-white">{{ redirectMessage }}</span>
              </div>
            </div>
          </div>

          <div class="rounded-[28px] border border-white/10 bg-white/8 backdrop-blur-xl p-6 md:p-8 shadow-2xl shadow-black/20">
            <div class="space-y-5">
              <div>
                <p class="text-sm uppercase tracking-[0.28em] text-slate-400">Routing logic</p>
                <h2 class="mt-3 text-2xl font-semibold text-white">What happens now</h2>
              </div>

              <div class="space-y-3 text-sm text-slate-300">
                <div class="rounded-2xl border border-white/10 bg-slate-900/50 p-4">
                  <p class="font-semibold text-white">Android</p>
                  <p class="mt-1">This page sends Android users straight to Google Play, with direct APK download still available as a fallback.</p>
                </div>
                <div class="rounded-2xl border border-white/10 bg-slate-900/50 p-4">
                  <p class="font-semibold text-white">iPhone and iPad</p>
                  <p class="mt-1">iOS users are sent to the App Store destination configured in Nuxt runtime settings.</p>
                </div>
                <div class="rounded-2xl border border-white/10 bg-slate-900/50 p-4">
                  <p class="font-semibold text-white">Desktop</p>
                  <p class="mt-1">Desktop visitors stay on this page and can choose a store link or the Android APK manually.</p>
                </div>
              </div>

              <div class="rounded-2xl border border-emerald-400/30 bg-emerald-400/10 p-4 text-sm text-emerald-100">
                Main homepage visitors on mobile now follow an app-first flow: open the installed app first, then fall back to the correct store if the app is not available.
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useAppDownload } from "~/composables/useAppDownload";

const toast = useToast();
const { getPlatform, getStoreUrl, redirectToStore, tryOpenApp } = useSmartAppLinks();
const { downloadApp, error } = useAppDownload();

const detectedPlatform = ref("desktop");
const redirectState = ref("ready");

const detectedDeviceLabel = computed(() => {
  if (detectedPlatform.value === "android") {
    return "Android";
  }

  if (detectedPlatform.value === "ios") {
    return "iPhone / iPad";
  }

  return "Desktop";
});

const primaryActionLabel = computed(() => {
  if (detectedPlatform.value === "android") {
    return "Continue to Google Play";
  }

  if (detectedPlatform.value === "ios") {
    return "Continue to App Store";
  }

  return "Choose a Mobile Store";
});

const redirectMessage = computed(() => {
  if (redirectState.value === "redirecting") {
    return "Redirecting now";
  }

  if (redirectState.value === "fallback") {
    return "Store fallback opened";
  }

  if (redirectState.value === "unavailable") {
    return "Store link is not configured";
  }

  return "Waiting for your action";
});

const downloadAndroidApp = async () => {
  try {
    const success = await downloadApp();

    if (success) {
      toast.add({
        title: "Download Started",
        description: "AdsyClub Android app is downloading...",
        color: "green",
        icon: "i-heroicons-check-circle",
      });
    } else {
      throw new Error(error.value || "Download failed");
    }
  } catch (err) {
    console.error("Download error:", err);
    toast.add({
      title: "Download Error",
      description: "Failed to start download. Please try again.",
      color: "red",
      icon: "i-heroicons-exclamation-triangle",
    });
  }
};

const goToStore = () => {
  const platform = getPlatform();
  const storeUrl = getStoreUrl(platform);

  if (!storeUrl && platform !== "android") {
    redirectState.value = "unavailable";
    toast.add({
      title: "Store Link Missing",
      description: "App Store link is not configured yet.",
      color: "orange",
      icon: "i-heroicons-exclamation-circle",
    });
    return;
  }

  redirectState.value = "redirecting";
  redirectToStore(platform, { fallbackToDownload: false });
};

const openInstalledApp = async () => {
  redirectState.value = "redirecting";
  const result = await tryOpenApp({
    fullPath: "/",
    fallbackToStore: true,
    fallbackDelayMs: 1400,
    cooldownMs: 0,
    force: true,
  });

  if (result === "fallback") {
    redirectState.value = "fallback";
    return;
  }

  if (result === "unavailable") {
    redirectState.value = "unavailable";
  }
};

onMounted(() => {
  detectedPlatform.value = getPlatform();

  if (detectedPlatform.value === "desktop") {
    redirectState.value = "ready";
    return;
  }

  redirectState.value = "redirecting";
  const didRedirect = redirectToStore(detectedPlatform.value as "android" | "ios", {
    fallbackToDownload: false,
  });

  if (!didRedirect) {
    redirectState.value = "unavailable";
  }
});
</script>