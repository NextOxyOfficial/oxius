<template>
  <div>
    <!-- Global Popup -->
    <Teleport to="body">
      <div
        v-if="showPopup && currentPopup"
        class="fixed inset-0 z-[80] flex items-center justify-center p-2 bg-black/50 backdrop-blur-sm animate-fade-in"
      >
        <div
          class="relative bg-white dark:bg-gray-900 rounded-2xl shadow-2xl sm:max-w-3xl h-[45vh] w-full overflow-hidden animate-scale-in"
          @click.stop
        >
          <!-- Close Button -->
          <button
            @click="closePopup"
            class="absolute flex top-4 right-4 z-[90] p-2 rounded-full bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            :aria-label="`Close popup ${currentPopup.id}`"
          >
            <UIcon
              name="i-heroicons-x-mark"
              class="w-5 h-5 text-gray-600 dark:text-gray-400"
            />
          </button>

          <!-- Loading state -->
          <div
            v-if="!currentPopup.image"
            class="w-full h-full flex items-center justify-center bg-gray-100 dark:bg-gray-800"
          >
            <div class="text-gray-500 dark:text-gray-400">Loading...</div>
          </div>

          <!-- Content -->
          <div v-else class="w-full h-full">
            <!-- Image failed to load - show fallback -->
            <div
              v-if="imageLoadError"
              class="w-full h-full flex flex-col items-center justify-center bg-gradient-to-br from-blue-500 to-purple-600 text-white p-8"
            >
              <div class="text-center">
                <div class="text-6xl mb-4">🎉</div>
                <div class="text-2xl font-bold mb-2">Special Announcement!</div>
                <div class="text-lg opacity-90">
                  We have something exciting to share with you!
                </div>
              </div>
            </div>

            <!-- Try to load image -->
            <NuxtLink
              v-else
              :to="currentPopup.link"
              :target="currentPopup.open_external ? '_blank' : '_self'"
              class="block w-full h-full hover:cursor-pointer"
            >
              <img
                :src="currentPopup?.image"
                :alt="`Popup ${currentPopup.id}`"
                class="w-full h-full object-cover rounded-t-2xl"
                @load="onPopupShown"
                @error="onImageError"
                loading="eager"
                crossorigin="anonymous"
              />
            </NuxtLink>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
const { get, post } = useApi();
const { isAuthenticated } = useAuth();

// Reactive state
const showPopup = ref(false);
const currentPopup = ref(null);
const isDesktop = ref(true);
const hasTrackedView = ref(false);
const imageLoadError = ref(false);

// Detect device type
onMounted(async () => {
  isDesktop.value = window.innerWidth >= 640; // sm breakpoint

  // Listen for window resize to update device type
  window.addEventListener("resize", () => {
    const newIsDesktop = window.innerWidth >= 640;
    if (newIsDesktop !== isDesktop.value) {
      isDesktop.value = newIsDesktop;
    }
  });

  // Add keyboard event listener for ESC key
  window.addEventListener("keydown", handleKeydown);

  // Wait for authentication state to be ready
  await waitForAuth();

  // Load appropriate popup
  loadPopup();
});

// Wait for auth state to be ready
async function waitForAuth() {
  // Give some time for auth to initialize
  await new Promise((resolve) => setTimeout(resolve, 500));

  // Check if we have user data or can determine auth state
  const maxWait = 3000; // Max 3 seconds
  const startTime = Date.now();

  while (Date.now() - startTime < maxWait) {
    try {
      // Try to get user state - this will help determine if auth is ready
      const authState = isAuthenticated.value;

      // If we can determine auth state, we're ready
      if (authState !== undefined) {
        return;
      }
    } catch (error) {
      // Auth not ready yet, continue waiting
    }

    await new Promise((resolve) => setTimeout(resolve, 200));
  }
}

// Cleanup event listeners
onUnmounted(() => {
  window.removeEventListener("keydown", handleKeydown);
});

// Handle keyboard events
function handleKeydown(event) {
  if (event.key === "Escape" && showPopup.value) {
    closePopup();
  }
}

// Load popup based on device type
async function loadPopup() {
  try {
    const endpoint = isDesktop.value
      ? "/global-popup/desktop/"
      : "/global-popup/mobile/";

    const response = await get(endpoint);

    if (
      response &&
      response.data &&
      Array.isArray(response.data) &&
      response.data.length > 0
    ) {
      // Get the first active popup that should be shown
      const popup = response.data[0];

      // Validate popup has required fields
      if (popup.id && popup.image) {
        currentPopup.value = popup;
        imageLoadError.value = false; // Reset error state
        showPopup.value = true;
      } else {
        showPopup.value = false;
      }
    } else {
      showPopup.value = false;
    }
  } catch (error) {
    console.error("Error fetching popup:", error);
    showPopup.value = false;
  }
}

// Track popup view when image loads (popup is actually shown)
async function onPopupShown() {
  if (!currentPopup.value || hasTrackedView.value) return;

  try {
    const payload = {
      popup_type: isDesktop.value ? "desktop" : "mobile",
      popup_id: currentPopup.value.id,
    };

    await post("/global-popup/track-view/", payload);
    hasTrackedView.value = true;
  } catch (error) {
    console.error("Error tracking popup view:", error);
    // Don't prevent popup from showing if tracking fails
  }
}

// Handle image load error
function onImageError() {
  // Show fallback content instead of hiding popup
  imageLoadError.value = true;

  // Still track the view since popup is being shown
  if (!hasTrackedView.value) {
    onPopupShown();
  }
}

// Process image URL for better compatibility
function getImageUrl(imageUrl) {
  if (!imageUrl) return "";

  // If it's already a full URL, return as is
  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return imageUrl;
  }

  // If it's a relative path, construct full URL
  if (imageUrl.startsWith("/media/")) {
    const { baseURL } = useApi();
    const fullUrl = baseURL.replace("/api", "") + imageUrl;
    return fullUrl;
  }

  return imageUrl;
}

// Close popup
function closePopup() {
  showPopup.value = false;
}

// Watch for device type changes and reload popup if needed
watch(isDesktop, (newValue, oldValue) => {
  if (newValue !== oldValue) {
    hasTrackedView.value = false;
    currentPopup.value = null;
    loadPopup();
  }
});

// Watch for authentication changes and reload popup if needed
watch(isAuthenticated, (newValue, oldValue) => {
  if (newValue !== oldValue) {
    hasTrackedView.value = false;
    currentPopup.value = null;
    loadPopup();
  }
});
</script>
