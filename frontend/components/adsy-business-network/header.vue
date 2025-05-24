<template>
  <div class="fixed top-0 left-0 right-0 z-[9999999999999] w-full mx-auto">
    <header class="backdrop-blur-sm bg-white/95 dark:bg-gray-900/95 shadow-sm">
      <div class="max-w-5xl mx-auto pl-1 pr-2 sm:px-4">
        <div
          class="flex items-center justify-between h-16 sm:h-18 bg-gray-100/40"
        >
          <!-- Left Section: Sidebar Toggle (mobile only) + Logo -->
          <div class="flex items-center space-x-1 sm:gap-5">
            <!-- Sidebar Toggle Button - MOBILE ONLY -->
            <button
              @click="cart.toggleBurgerMenu()"
              class="flex sm:hidden group relative size-7 flex-shrink-0 items-center justify-center rounded-full bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 transition-all"
              aria-label="Toggle sidebar"
            >
              <div
                class="flex flex-col justify-center items-center w-5 space-y-1.5 transform transition-all duration-300"
              >
                <span
                  class="block h-0.5 w-5 bg-gray-600 dark:bg-gray-300 transform transition-all duration-300 group-hover:bg-blue-600 dark:group-hover:bg-blue-400"
                ></span>
                <span
                  class="block h-0.5 w-3.5 bg-gray-600 dark:bg-gray-300 transform transition-all duration-300 group-hover:bg-blue-600 dark:group-hover:bg-blue-400 group-hover:w-5"
                ></span>
                <span
                  class="block h-0.5 w-5 bg-gray-600 dark:bg-gray-300 transform transition-all duration-300 group-hover:bg-blue-600 dark:group-hover:bg-blue-400"
                ></span>
              </div>

              <!-- Ripple effect on click -->
              <span
                class="absolute inset-0 rounded-full transform scale-0 bg-blue-100 dark:bg-blue-900/40 animate-ripple"
              ></span>
            </button>

            <!-- Logo with Hover Effect -->
            <NuxtLink
              to="/business-network/"
              class="flex items-center overflow-hidden transform hover:scale-[1.02] transition-transform duration-300"
              aria-label="Logo"
            >
              <div class="relative">
                <NuxtImg
                  v-if="logo[0]?.image"
                  :src="logo[0].image"
                  alt="Adsy Logo"
                  width="150"
                  height="50"
                  class="h-7 sm:h-10 w-auto object-contain"
                  loading="eager"
                />
                <div
                  class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-0 hover:opacity-100 -translate-x-full hover:translate-x-full transition-all duration-1000 ease-in-out"
                ></div>
              </div>
            </NuxtLink>
          </div>

          <!-- Right Section: Search + Navigation + User Menu -->
          <div class="flex items-center sm:gap-3 relative">
            <!-- Search Component -->
            <CommonSearchDropdown ref="searchDropdownRef" />

            <!-- Navigation Buttons - DESKTOP ONLY (AdsyClub & AdsyNews) -->
            <div class="hidden sm:flex items-center gap-2">
              <!-- AdsyClub Button -->
              <NuxtLink
                to="/"
                class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all group"
                aria-label="Go to AdsyClub"
              >
                <div
                  class="p-1 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 text-white transition-transform group-hover:scale-110 group-hover:rotate-3"
                >
                  <BarChartBig class="h-3.5 w-3.5" />
                </div>
                <span class="relative overflow-hidden">
                  AdsyClub
                  <span
                    class="absolute bottom-0 left-0 w-full h-0.5 bg-blue-500 transform scale-x-0 origin-left transition-transform group-hover:scale-x-100"
                  ></span>
                </span>
              </NuxtLink>

              <!-- AdsyNews Button -->
              <NuxtLink
                to="/adsy-news"
                class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all group"
                aria-label="Go to AdsyNews"
              >
                <div
                  class="p-1 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 text-white transition-transform group-hover:scale-110 group-hover:rotate-3"
                >
                  <Newspaper class="h-3.5 w-3.5" />
                </div>
                <span class="relative overflow-hidden">
                  AdsyNews
                  <span
                    class="absolute bottom-0 left-0 w-full h-0.5 bg-orange-500 transform scale-x-0 origin-left transition-transform group-hover:scale-x-100"
                  ></span>
                </span>
              </NuxtLink>
            </div>

            <!-- Translate Component - Desktop only -->
            <PublicTranslateHandler class="hidden sm:block px-2" />
            <div v-if="!user" class="flex relative menu-container">
              <UButton
                to="/auth/login"
                label="Login/Register"
                color="gray"
                :ui="{
                  size: {
                    sm: 'text-xs md:text-sm',
                  },
                  padding: {
                    sm: 'px-2 py-1 md:px-2.5 md:py-1.5',
                  },
                  icon: {
                    size: {
                      sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
                    },
                  },
                }"
                size="md"
              >
              </UButton>
            </div>
            <UButton
              v-else
              size="sm"
              color="primary"
              variant="outline"
              @click="openMenu = !openMenu"
              :ui="{
                gap: {
                  sm: 'gap-x-0.5',
                },
                size: {
                  sm: 'text-xs sm:text-sm',
                },
                padding: {
                  sm: 'px-1.5 py-1 md:px-2.5 md:py-1.5',
                },
                icon: {
                  size: {
                    sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
                  },
                },
              }"
              ref="userButtonRef"
            >
              <span
                v-if="user?.user?.is_pro"
                class="text-xs px-0.5 py-0.5 text-blue-800 rounded-full font-medium shadow-sm"
              >
                <div class="flex items-center">
                  <UIcon name="i-heroicons-shield-check" class="size-4" />
                </div>
              </span>
              <UIcon
                v-if="user?.user?.kyc"
                name="mdi:check-decagram"
                class="w-4 h-4 text-blue-600"
              />
              <UIcon v-else name="i-heroicons-user-circle" class="text-xl" />

              Hi {{ user?.user?.first_name.slice(0, 8) }}
              <UIcon
                name="i-heroicons-chevron-down-16-solid"
                v-if="!openMenu"
              />
              <UIcon name="i-heroicons-chevron-up-16-solid" v-if="openMenu" />
            </UButton>            <!-- User dropdown menu component -->
            <BusinessNetworkDropdownMenu
              :user="user"
              :is-open="openMenu"
              @update:is-open="openMenu = $event"
              @upgrade-to-pro="upgradeToPro"
              @manage-subscription="manageSubscription"
              @logout="logout"
              ref="menuRef"
            />
          </div>
        </div>
      </div>
    </header>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted, onUnmounted, computed } from "vue";
import { useI18n } from "vue-i18n";
import { useApi } from "~/composables/useApi";
import { useAuth } from "~/composables/useAuth";
import { useStoreCart } from "~/store/cart";
import { useRouter } from "vue-router";
import BusinessNetworkDropdownMenu from './business-network-dropdown-menu.vue';
import {
  SunIcon,
  MenuIcon,
  XIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  Newspaper,
  BarChartBig,
} from "lucide-vue-next";

const { t } = useI18n();
const { get } = useApi();
const { user, logout } = useAuth();
const logo = ref([]);
const cart = useStoreCart();
const showQr = ref(false);
const openMenu = ref(false);
const menuRef = ref(null);
const userButtonRef = ref(null);
const searchDropdownRef = ref(null);
const router = useRouter();

async function getLogo() {
  const { data } = await get("/bn-logo/");
  logo.value = data;
}

await getLogo();

// Navigation state
const mobileMenuOpen = ref(false);

// Handle clicks outside of user menu dropdown to close it
const handleClickOutside = (event) => {
  // For user menu dropdown
  // Only proceed if the menu is open and we have valid refs
  if (openMenu.value) {
    // Get the menu element and the button that opens it
    const menuElement = menuRef.value;
    const userButton = userButtonRef.value?.$el || userButtonRef.value;

    // Check if click was outside both elements
    if (
      menuElement &&
      userButton &&
      !menuElement.contains(event.target) &&
      !userButton.contains(event.target)
    ) {
      // Close the menu
      openMenu.value = false;
    }
  }
};

// Use a proper lifecycle hook to add the global listener
onMounted(() => {
  // Let the DOM render first before attaching listeners
  nextTick(() => {
    document.addEventListener("click", handleClickOutside, true);
  });
});

// Clean up event listeners
onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside, true);
});

function upgradeToPro() {
  openMenu.value = false;
  router.push("/upgrade-to-pro");
}

function manageSubscription() {
  openMenu.value = false;
  router.push("/account/subscription");
}

function formatDate(date) {
  return new Date(date).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
</script>

<style scoped>
:root {
  --color-primary: #e53e3e;
  --color-primary-dark: #c53030;
}

.bg-primary {
  background-color: var(--color-primary);
}

.text-primary {
  color: var(--color-primary);
}

.hover\:text-primary:hover {
  color: var(--color-primary);
}

.hover\:text-primary-dark:hover {
  color: var(--color-primary-dark);
}

.hover\:bg-primary-dark:hover {
  background-color: var(--color-primary-dark);
}

.focus\:ring-primary:focus {
  --tw-ring-color: var(--color-primary);
}

.focus\:border-primary:focus {
  border-color: var(--color-primary);
}

.border-primary {
  border-color: var(--color-primary);
}

/* Ticker animation */
.ticker-container {
  animation: ticker 20s linear infinite;
}

.ticker-item {
  margin-right: 50px;
}

@keyframes ticker {
  0% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

/* Transition effects */
.comment-list-enter-active,
.comment-list-leave-active {
  transition: all 0.5s ease;
}
.comment-list-enter-from,
.comment-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

/* Line clamp for article summaries */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Glass effect for header */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
}

/* Custom shadow for dropdown */
.search-dropdown-container {
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1),
    0 8px 10px -6px rgba(0, 0, 0, 0.05);
}

/* Ripple animation for sidebar toggle button */
@keyframes ripple {
  0% {
    transform: scale(0);
    opacity: 1;
  }
  80% {
    transform: scale(1.5);
    opacity: 0.2;
  }
  100% {
    transform: scale(2);
    opacity: 0;
  }
}

.animate-ripple {
  animation: ripple 0.8s ease-out;
  animation-iteration-count: 1;
  opacity: 0;
}

/* Improved search input focus styles */
.search-input:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.3);
}

/* Improve scrollbar for search results */
.search-dropdown-container div {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.search-dropdown-container div::-webkit-scrollbar {
  width: 4px;
}

.search-dropdown-container div::-webkit-scrollbar-track {
  background: transparent;
}

.search-dropdown-container div::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 9999px;
}

/* Mobile adjustments - FIXED POSITIONING */
@media (max-width: 640px) {
  .search-dropdown-container {
    position: fixed;
    width: calc(100% - 2rem);
    max-width: 400px;
    left: 50%;
    transform: translateX(-50%);
    top: 5rem;
    margin: 0 auto;
    z-index: 1000;
  }
}
</style>
