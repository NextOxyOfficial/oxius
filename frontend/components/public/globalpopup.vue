<template>
  <Teleport to="body">
    <div
      v-if="showPopup && currentPopup"
      class="fixed inset-0 z-[80] flex items-center justify-center p-2 bg-black/50 backdrop-blur-sm animate-fade-in"
    >
      <div
        class="relative max-w-[calc(100vw-24px)] max-h-[72vh] animate-scale-in"
        @click.stop
      >
        <button
          @click="closePopup"
          class="absolute flex -top-3 -right-2 z-[90] p-2 rounded-full bg-white text-slate-900 shadow-lg hover:bg-slate-50 transition-colors"
          :aria-label="`Close popup ${currentPopup.id}`"
        >
          <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
        </button>

        <NuxtLink
          :to="currentPopup.link || '/'"
          :target="currentPopup.open_external ? '_blank' : '_self'"
          class="block hover:cursor-pointer"
        >
          <img
            :src="getImageUrl(currentPopup.image)"
            :alt="`Popup ${currentPopup.id}`"
            class="block max-w-[calc(100vw-24px)] max-h-[72vh] object-contain rounded-2xl"
            @load="onPopupShown"
            @error="closePopup"
          />
        </NuxtLink>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
const { get, post, baseURL } = useApi();
const { isAuthenticated } = useAuth();

const showPopup = ref(false);
const currentPopup = ref(null);
const isDesktop = ref(true);
const hasTrackedView = ref(false);

onMounted(async () => {
  isDesktop.value = window.innerWidth >= 640;
  window.addEventListener("resize", handleResize);
  window.addEventListener("keydown", handleKeydown);

  await waitForAuth();
  loadPopup();
});

onUnmounted(() => {
  window.removeEventListener("resize", handleResize);
  window.removeEventListener("keydown", handleKeydown);
});

function handleResize() {
  const newIsDesktop = window.innerWidth >= 640;
  if (newIsDesktop !== isDesktop.value) {
    isDesktop.value = newIsDesktop;
  }
}

function handleKeydown(event) {
  if (event.key === "Escape" && showPopup.value) {
    closePopup();
  }
}

async function waitForAuth() {
  await new Promise((resolve) => setTimeout(resolve, 500));

  const maxWait = 3000;
  const startTime = Date.now();

  while (Date.now() - startTime < maxWait) {
    try {
      if (isAuthenticated.value !== undefined) return;
    } catch (_) {}
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
}

async function loadPopup() {
  try {
    const endpoint = isDesktop.value
      ? "/global-popup/desktop/"
      : "/global-popup/mobile/";
    const response = await get(endpoint);
    const popups = Array.isArray(response?.data) ? response.data : [];
    const popup = popups.find((item) => item?.id && item?.image);

    if (!popup) {
      closePopup();
      return;
    }

    currentPopup.value = popup;
    hasTrackedView.value = false;
    showPopup.value = true;
  } catch (_) {
    closePopup();
  }
}

async function onPopupShown() {
  if (!currentPopup.value || hasTrackedView.value) return;

  try {
    await post("/global-popup/track-view/", {
      popup_type: isDesktop.value ? "desktop" : "mobile",
      popup_id: currentPopup.value.id,
    });
    hasTrackedView.value = true;
  } catch (_) {}
}

function getImageUrl(imageUrl) {
  if (!imageUrl) return "";
  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return imageUrl;
  }
  if (imageUrl.startsWith("/media/")) {
    return baseURL.replace("/api", "") + imageUrl;
  }
  return imageUrl;
}

function closePopup() {
  showPopup.value = false;
}

watch(isDesktop, (newValue, oldValue) => {
  if (newValue === oldValue) return;
  currentPopup.value = null;
  hasTrackedView.value = false;
  loadPopup();
});

watch(isAuthenticated, (newValue, oldValue) => {
  if (newValue === oldValue) return;
  currentPopup.value = null;
  hasTrackedView.value = false;
  loadPopup();
});
</script>
