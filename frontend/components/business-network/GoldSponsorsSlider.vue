<template>
  <div
    class="gold-sponsors-slider relative mt-2 px-3 bg-gradient-to-r from-amber-50/50 to-yellow-50/50 dark:from-amber-900/10 dark:to-yellow-900/10 rounded-xl border border-amber-100/50 dark:border-amber-900/30 backdrop-blur-sm shadow-sm"
  >
    <!-- Top pattern decoration -->
    <div class="absolute top-0 left-0 right-0 h-1.5 overflow-hidden">
      <div
        class="h-full w-full bg-gradient-to-r from-amber-500/0 via-amber-500 to-amber-500/0 animate-shimmer"
      ></div>
    </div>
    <div class="flex items-center justify-between px-2 my-2">
      <h3 class="text-sm font-semibold flex items-center">
        <div class="w-5 h-5 flex items-center justify-center mr-1.5 relative">
          <div class="absolute inset-0 rounded-full golden-border"></div>
          <UIcon
            name="i-heroicons-star"
            class="w-4 h-4 text-amber-500 relative z-10"
          />
        </div>
        <span class="text-gold-gradient">
          {{ $t("gold_sponsors") }}
        </span>
      </h3>
      <NuxtLink
        to="/business-network/gold-sponsors"
        class="text-xs text-amber-600 dark:text-amber-400 hover:text-amber-700 dark:hover:text-amber-300 font-medium flex items-center group transition-colors"
      >
        {{ $t("view_all") }}
        <UIcon
          name="i-heroicons-chevron-right"
          class="w-4 h-4 ml-0.5 group-hover:translate-x-0.5 transition-transform"
        />
      </NuxtLink>
    </div>
    <!-- Sponsors Grid -->
    <div class="sponsors-container overflow-hidden relative">
      <!-- Loading state -->
      <div
        v-if="isLoading"
        class="flex py-3 gap-3 px-2 overflow-hidden justify-between"
      >
        <!-- Mobile Skeletons (3) -->
        <div
          v-for="i in 3"
          :key="i"
          class="flex-shrink-0 animate-pulse md:hidden"
        >
          <div class="flex flex-col items-center p-2">
            <div
              class="size-20 rounded-full bg-amber-100 dark:bg-amber-900/30 mb-2 relative overflow-hidden"
            >
              <div class="absolute inset-0 golden-border opacity-30"></div>
              <!-- Skeleton badge -->
              <div
                class="absolute -bottom-1 -right-1 bg-amber-200/70 dark:bg-amber-800/50 rounded-full w-5 h-5"
              ></div>
            </div>
            <div
              class="h-5 bg-amber-100 dark:bg-amber-900/30 rounded w-20 mt-1"
            ></div>
          </div>
        </div>

        <!-- Desktop Skeletons (5) -->
        <div
          v-for="i in 5"
          :key="i + 3"
          class="flex-shrink-0 animate-pulse hidden md:block"
        >
          <div class="flex flex-col items-center p-2">
            <div
              class="w-14 h-14 rounded-full bg-amber-100 dark:bg-amber-900/30 mb-2 relative overflow-hidden"
            >
              <div class="absolute inset-0 golden-border opacity-30"></div>
              <!-- Skeleton badge -->
              <div
                class="absolute -bottom-1 -right-1 bg-amber-200/70 dark:bg-amber-800/50 rounded-full w-5 h-5"
              ></div>
            </div>
            <div
              class="h-4 bg-amber-100 dark:bg-amber-900/30 rounded w-16 mt-1"
            ></div>
          </div>
        </div>
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="py-3 px-4">
        <div class="text-center text-amber-600 dark:text-amber-400">
          <UIcon
            name="i-heroicons-exclamation-triangle"
            class="w-5 h-5 mx-auto mb-2"
          />
          <p class="text-sm">{{ error }}</p>
        </div>
      </div>
      <!-- Content -->
      <div
        v-else
        class="flex py-2 gap-1.5 justify-between md:justify-between overflow-hidden"
      >
        <!-- Mobile View (3 sponsors) -->
        <div
          v-for="(sponsor, index) in sponsors.slice(0, 3)"
          :key="'mobile-' + index"
          class="sponsor-item md:hidden"
          :data-sponsor-id="sponsor.id"
        >
          <div
            class="block p-2 cursor-pointer"
            @click="openSponsorModal(sponsor)"
          >
            <div class="flex flex-col items-center">
              <!-- Profile image with gold border -->
              <div
                class="relative mb-2 group-hover:scale-105 transition-transform duration-300"
              >
                <div class="absolute inset-0 rounded-full golden-border"></div>
                <img
                  :src="sponsor.image || '/static/frontend/avatar.png'"
                  :alt="sponsor.name"
                  class="size-20 rounded-full object-cover border-2 border-white dark:border-slate-700 relative z-10"
                />
                <!-- Gold badge -->
                <div
                  class="absolute -bottom-1 -right-1 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-sm z-20 transform transition-transform group-hover: group-hover:rotate-12"
                >
                  <UIcon name="i-heroicons-star" class="w-3 h-3 text-white" />
                </div>
              </div>
              <!-- Name with hover underline -->
              <h4
                class="text-base font-medium text-gray-800 dark:text-gray-200 text-center group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors relative"
              >
                {{ sponsor.name }}
                <span
                  class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-0 h-0.5 bg-amber-500 group-hover:w-full transition-all duration-300"
                ></span>
              </h4>
            </div>
          </div>
        </div>
        <!-- Desktop View (5 sponsors) -->
        <div
          v-for="(sponsor, index) in sponsors.slice(0, 5)"
          :key="'desktop-' + index"
          class="sponsor-item hidden md:block"
          :data-sponsor-id="sponsor.id"
        >
          <div
            class="block p-2 cursor-pointer"
            @click="openSponsorModal(sponsor)"
          >
            <div class="flex flex-col items-center">
              <!-- Profile image with gold border -->
              <div
                class="relative mb-2 group-hover:scale-105 transition-transform duration-300"
              >
                <div class="absolute inset-0 rounded-full golden-border"></div>
                <img
                  :src="sponsor.image || '/static/frontend/avatar.png'"
                  :alt="sponsor.name"
                  class="w-14 h-14 rounded-full object-cover border-2 border-white dark:border-slate-700 relative z-10"
                />
                <!-- Gold badge -->
                <div
                  class="absolute -bottom-1 -right-1 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-sm z-20 transform transition-transform group-hover: group-hover:rotate-12"
                >
                  <UIcon name="i-heroicons-star" class="w-3 h-3 text-white" />
                </div>
              </div>
              <!-- Name with hover underline -->
              <h4
                class="text-sm font-medium text-gray-800 dark:text-gray-200 text-center group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors relative"
              >
                {{ sponsor.name }}
                <span
                  class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-0 h-0.5 bg-amber-500 group-hover:w-full transition-all duration-300"
                ></span>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Sponsor Detail Modal -->
    <Teleport to="body">
      <transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="transform scale-95 opacity-0"
        enter-to-class="transform scale-100 opacity-100"
        leave-active-class="transition duration-200 ease-in"
        leave-from-class="transform scale-100 opacity-100"
        leave-to-class="transform scale-95 opacity-0"
      >
        <div
          v-if="showModal"
          class="fixed inset-0 z-50 overflow-y-auto"
          aria-labelledby="modal-title"
          role="dialog"
          aria-modal="true"
        >
          <div
            class="flex items-start sm:items-end justify-center min-h-screen pt-16 text-center sm:block sm:p-0"
          >
            <!-- Background overlay -->
            <div
              class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
              aria-hidden="true"
              @click="closeModal"
            ></div>

            <!-- Modal panel -->
            <div
              class="inline-block align-bottom mt-10 sm:mt-20 bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl w-full"
            >
              <div class="absolute top-0 right-0 pt-4 pr-4 z-50">
                <button
                  type="button"
                  @click="closeModal"
                  class="bg-white dark:bg-slate-700 rounded-full pt-1 px-1 text-gray-400 hover:text-gray-500 dark:hover:text-gray-300 focus:outline-none shadow-md"
                >
                  <span class="sr-only">Close</span>
                  <UIcon name="i-heroicons-x-mark" class="h-6 w-6" />
                </button>
              </div>
              <div v-if="selectedSponsor" class="relative">
                <!-- Banner Slider (above sponsor details) -->
                <div
                  class="relative h-56 bg-gradient-to-r from-amber-50 to-yellow-50 dark:from-amber-900/20 dark:to-yellow-900/20"
                >
                  <div class="swiper-container h-full relative">
                    <div class="swiper-wrapper">
                      <!-- Placeholder banners (in real implementation, would come from API) -->
                      <div
                        class="swiper-slide"
                        v-for="(banner, index) in sponsorBanners"
                        :key="index"
                      >
                        <img
                          :src="banner"
                          class="w-full h-full object-cover"
                          :alt="`${selectedSponsor.name} banner`"
                        />
                      </div>
                    </div>
                    <!-- Pagination dots -->
                    <div class="swiper-pagination absolute bottom-2"></div>
                    <!-- Navigation arrows (hidden but functional) -->
                    <div class="swiper-button-next opacity-0"></div>
                    <div class="swiper-button-prev opacity-0"></div>
                  </div>
                </div>
                <!-- Sponsor Profile -->
                <div class="py-6 px-2 bg-white dark:bg-slate-800">
                  <!-- Description area first -->
                  <div class="space-y-4 mb-4 md:mb-6">
                    <div
                      v-html="
                        selectedSponsor.business_description ||
                        `${selectedSponsor.name} is one of our esteemed gold sponsors, contributing significantly to our business network. Their commitment to excellence and innovation has made them a valuable member of our community.`
                      "
                      class="text-gray-600 dark:text-gray-300 text-sm md:text-base"
                    ></div>
                  </div>
                  <!-- Profile and contact side by side -->
                  <div
                    class="flex flex-row gap-6 mt-4 border-t border-gray-100 dark:border-gray-700 pt-6"
                  >
                    <!-- Left side: Profile photo and badge -->
                    <div class="flex-shrink-0 mt-2 flex flex-col items-center">
                      <div class="relative">
                        <div
                          class="absolute inset-0 rounded-lg golden-border"
                        ></div>
                        <img
                          :src="
                            selectedSponsor.image ||
                            '/static/frontend/avatar.png'
                          "
                          :alt="selectedSponsor.name"
                          class="w-24 h-24 md:w-32 md:h-32 rounded-lg object-cover border-4 border-white dark:border-slate-700 relative z-10"
                        />
                        <!-- Gold badge -->
                        <div
                          class="absolute bottom-0 right-0 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-8 h-8 md:w-10 md:h-10 flex items-center justify-center shadow-md z-20"
                        >
                          <UIcon
                            name="i-heroicons-star"
                            class="w-5 h-5 md:w-6 md:h-6 text-white"
                          />
                        </div>
                      </div>
                      <!-- Gold sponsor text under profile -->
                      <p
                        class="text-amber-600 dark:text-amber-400 mt-3 font-medium text-sm md:text-base"
                      >
                        Gold Sponsor
                      </p>
                    </div>
                    <!-- Right side: Name and contact details -->
                    <div class="flex-grow space-y-2 md:space-y-3">
                      <h2
                        class="text-xl font-semibold text-gray-800 dark:text-white"
                      >
                        {{ selectedSponsor.name }}
                      </h2>

                      <div
                        v-if="selectedSponsor.contact_email"
                        class="flex items-center"
                      >
                        <UIcon
                          name="i-heroicons-envelope"
                          class="w-5 h-5 mr-2 text-amber-500 flex-shrink-0"
                        />
                        <span
                          class="text-gray-600 dark:text-gray-300 text-sm md:text-base"
                          >{{ selectedSponsor.contact_email }}</span
                        >
                      </div>

                      <div
                        v-if="selectedSponsor.phone_number"
                        class="flex items-center"
                      >
                        <UIcon
                          name="i-heroicons-phone"
                          class="w-5 h-5 mr-2 text-amber-500 flex-shrink-0"
                        />
                        <span
                          class="text-gray-600 dark:text-gray-300 text-sm md:text-base"
                          >{{ selectedSponsor.phone_number }}</span
                        >
                      </div>

                      <div
                        v-if="selectedSponsor.website"
                        class="flex items-center"
                      >
                        <UIcon
                          name="i-heroicons-globe-alt"
                          class="w-5 h-5 mr-2 text-amber-500 flex-shrink-0"
                        />
                        <a
                          :href="selectedSponsor.website"
                          target="_blank"
                          class="text-gray-600 dark:text-gray-300 text-sm md:text-base hover:text-amber-600 dark:hover:text-amber-400"
                          >{{ selectedSponsor.website }}</a
                        >
                      </div>
                      <!-- View full profile button -->
                      <div class="pt-3 md:pt-4">
                        <component
                          :is="
                            selectedSponsor.profile_url &&
                            selectedSponsor.profile_url.startsWith('http')
                              ? 'a'
                              : 'NuxtLink'
                          "
                          :to="
                            selectedSponsor.profile_url
                              ? selectedSponsor.profile_url
                              : `/business-network/profile/${selectedSponsor.id}`
                          "
                          :href="
                            selectedSponsor.profile_url &&
                            selectedSponsor.profile_url.startsWith('http')
                              ? selectedSponsor.profile_url
                              : null
                          "
                          :target="
                            selectedSponsor.profile_url &&
                            selectedSponsor.profile_url.startsWith('http')
                              ? '_blank'
                              : '_self'
                          "
                          class="inline-flex items-center px-3 py-1.5 md:px-4 md:py-2 bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 text-white rounded-md transition-all duration-300 text-sm md:text-base"
                        >
                          Visit Sponsor's Profile
                          <UIcon
                            name="i-heroicons-arrow-right"
                            class="ml-1 w-4 h-4 md:w-5 md:h-5"
                          />
                        </component>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted, watchEffect } from "vue";
import { useApi } from "~/composables/useApi";
import { useI18n } from "vue-i18n";

const { t } = useI18n();
const { get, post } = useApi();

// Sample data (will be replaced with API call)
const sponsors = ref([]);
const isLoading = ref(true);
const error = ref(null);

// Modal state
const showModal = ref(false);
const selectedSponsor = ref(null);

// Placeholder banners for the slider (would come from API in real implementation)
const sponsorBanners = ref([]);

// Track which sponsors have had their views counted
const viewedSponsors = ref(new Set());

// Open sponsor modal
async function openSponsorModal(sponsor) {
  selectedSponsor.value = sponsor;
  showModal.value = true;

  // Increment sponsor views when modal is opened
  try {
    await incrementSponsorViews(sponsor.id);
  } catch (error) {
    console.error("Failed to increment sponsor views:", error);
  }

  // Fetch sponsor banners
  try {
    await fetchSponsorBanners(sponsor.id);
  } catch (error) {
    console.error("Failed to fetch sponsor banners:", error);
    // Use placeholder banners if fetch fails
    sponsorBanners.value = [
      "https://placehold.co/1200x400/fff5e0/ffa500?text=Banner+1",
      "https://placehold.co/1200x400/fff8e7/ffb700?text=Banner+2",
      "https://placehold.co/1200x400/fffaf0/ffc800?text=Banner+3",
    ];
  }

  // Initialize swiper in the next tick after DOM update
  setTimeout(() => {
    if (typeof window !== "undefined" && window.Swiper) {
      new window.Swiper(".swiper-container", {
        slidesPerView: 1,
        spaceBetween: 0,
        loop: true,
        autoplay: {
          delay: 5000,
          disableOnInteraction: false,
        },
        pagination: {
          el: ".swiper-pagination",
          clickable: true,
        },
        navigation: {
          nextEl: ".swiper-button-next",
          prevEl: ".swiper-button-prev",
        },
        // Enhanced touch settings
        touchEventsTarget: "container",
        grabCursor: true,
        touchRatio: 1,
        touchAngle: 45,
        threshold: 5,
      });
    }
  }, 100);
}

// Close sponsor modal
function closeModal() {
  showModal.value = false;
  selectedSponsor.value = null;
}

// Fetch gold sponsors
async function fetchGoldSponsors() {
  try {
    isLoading.value = true;
    error.value = null;

    // Fetch active/featured gold sponsors from API
    const result = await get("/bn/gold-sponsors/list/");

    // Check if the API call was successful
    if (result.error) {
      console.error("API Error:", result.error);
      error.value = "Failed to load gold sponsors";
      sponsors.value = [];
    } else if (result.data && Array.isArray(result.data)) {
      // Map API response to component format
      sponsors.value = result.data.map((sponsor) => ({
        id: sponsor.id,
        name: sponsor.business_name,
        banners: sponsor.banners,
        image: sponsor.logo ? sponsor.logo : "/static/frontend/avatar.png",
        business_description: sponsor.business_description,
        contact_email: sponsor.contact_email,
        phone_number: sponsor.phone_number,
        website: sponsor.website,
        profile_url: sponsor.profile_url,
        package: sponsor.package,
        start_date: sponsor.start_date,
        end_date: sponsor.end_date,
        status: sponsor.status,
        is_featured: sponsor.is_featured,
      }));

      console.log("Gold sponsors loaded:", sponsors.value.length);
    } else {
      // If no sponsors or unexpected response format
      console.log("No sponsors data received");
      sponsors.value = [];
    }

    isLoading.value = false;
  } catch (err) {
    console.error("Error fetching gold sponsors:", err);
    error.value = "Failed to load gold sponsors";
    isLoading.value = false;

    // Fallback to empty array instead of dummy data
    sponsors.value = [];
  }
}

// Increment sponsor views
async function incrementSponsorViews(sponsorId) {
  try {
    const result = await post(
      `/bn/gold-sponsors/increment-views/${sponsorId}/`,
      {}
    );
    if (result.error) {
      console.error("Error incrementing sponsor views:", result.error);
    }
  } catch (error) {
    console.error("Error incrementing sponsor views:", error);
  }
}

// Fetch sponsor banners
async function fetchSponsorBanners(sponsorId) {
  try {
    const result = await get(`/bn/gold-sponsors/${sponsorId}/banners/`);
    console.log("Banners fetched:", result.data);
    if (result.error) {
      console.error("Error fetching sponsor banners:", result.error);
      sponsorBanners.value = [];
    } else if (result.data && Array.isArray(result.data)) {
      // Map banner data to image URLs

      sponsorBanners.value = result.data
        .filter((banner) => banner.is_active && banner.image)
        .sort((a, b) => a.order - b.order)
        .map((banner) => banner.image);

      // If no banners, use placeholder
      if (sponsorBanners.value.length === 0) {
        sponsorBanners.value = [
          "https://placehold.co/1200x400/fff5e0/ffa500?text=No+Banners+Available",
        ];
      }
    } else {
      sponsorBanners.value = [];
    }
  } catch (error) {
    console.error("Error fetching sponsor banners:", error);
    sponsorBanners.value = [];
  }
}

// Setup intersection observer to track when sponsors become visible
function setupIntersectionObserver() {
  if (typeof window === "undefined" || !window.IntersectionObserver) return;

  // Create a new intersection observer
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(async (entry) => {
        // If element is visible and has a sponsor ID
        if (entry.isIntersecting) {
          const sponsorId = entry.target.dataset.sponsorId;

          // Check if we've already counted this sponsor in this session
          if (sponsorId && !viewedSponsors.value.has(sponsorId)) {
            // Mark this sponsor as viewed in this session
            viewedSponsors.value.add(sponsorId);

            // Increment the views for this sponsor
            try {
              await incrementSponsorViews(sponsorId);
              console.log(
                `Incremented view count for sponsor ID: ${sponsorId}`
              );
            } catch (error) {
              console.error(
                `Failed to increment views for sponsor ID: ${sponsorId}`,
                error
              );
            }
          }
        }
      });
    },
    {
      // Options: trigger when at least 70% of the element is visible
      threshold: 0.7,
      // Add root margin to trigger a bit earlier before the sponsor becomes fully visible
      rootMargin: "0px 0px -10% 0px",
    }
  );

  // Observer all sponsor elements
  const sponsorElements = document.querySelectorAll(".sponsor-item");
  sponsorElements.forEach((element) => {
    observer.observe(element);
  });

  // Return the observer to be able to disconnect it later
  return observer;
}

// Watch for changes in the sponsors array to re-setup the observer
let intersectionObserver = null;
watchEffect(() => {
  // Only run this after the sponsors have been loaded and aren't empty
  if (sponsors.value.length > 0 && !isLoading.value) {
    // Wait for the DOM to update with the new sponsors
    setTimeout(() => {
      // Disconnect the previous observer if it exists
      if (intersectionObserver) {
        intersectionObserver.disconnect();
      }
      // Setup a new observer
      intersectionObserver = setupIntersectionObserver();
    }, 100);
  }
});

// Initialize
onMounted(() => {
  fetchGoldSponsors();
});
</script>

<style scoped>
.golden-border {
  background: linear-gradient(
    45deg,
    #f59e0b,
    #f59e0b 25%,
    #eab308 50%,
    #f59e0b 75%,
    #f59e0b
  );
  opacity: 0.7;
  border-radius: 9999px;
  transform: scale(1.1);
  z-index: -1;
  animation: spin 12s linear infinite;
}

@keyframes pulse-subtle {
  0%,
  100% {
    opacity: 0.6;
  }
  50% {
    opacity: 0.8;
  }
}

@keyframes spin {
  100% {
    transform: scale(1.1) rotate(360deg);
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Enhanced styling for gold sponsor items */
.sponsor-slide:hover {
  transform: translateY(-4px);
  transition: transform 0.3s ease-out;
}

/* Gradient text effect for gold sponsors heading */
.text-gold-gradient {
  background: linear-gradient(to right, #d97706, #fbbf24, #d97706);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

/* Hide scrollbar */
.sponsors-container {
  scrollbar-width: none;
  -webkit-overflow-scrolling: touch; /* Smooth scrolling on iOS */
  touch-action: pan-x; /* Optimize for horizontal touch */
}
.sponsors-container::-webkit-scrollbar {
  display: none;
}

/* Ensure smoother animations */
.sponsors-track {
  will-change: transform;
  cursor: grab;
  user-select: none;
}

.sponsors-track:active {
  cursor: grabbing;
}

/* Shimmer animation for the top border */
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}

/* Optimize for touch devices */
@media (pointer: coarse) {
  .sponsors-container {
    touch-action: pan-x;
  }

  /* Make the slides slightly larger on touch devices for better tapping */
  .sponsor-slide img {
    min-width: 56px;
    min-height: 56px;
  }
}

/* Modal styles */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

/* Swiper custom styles */
.swiper-container .swiper-pagination-bullet {
  background: white;
  opacity: 0.7;
}
.swiper-container .swiper-pagination-bullet-active {
  background: #f59e0b;
  opacity: 1;
}
.swiper-button-next,
.swiper-button-prev {
  color: white !important;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}

/* Enhanced touch interaction */
.swiper-container {
  touch-action: pan-y;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
  cursor: grab;
}
.swiper-container:active {
  cursor: grabbing;
}
</style>
