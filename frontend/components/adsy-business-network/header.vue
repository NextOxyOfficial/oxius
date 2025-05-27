<template>  <div
    class="py-3 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg transition-all duration-300 z-[99999999] w-full"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg border-gray-200/50 dark:border-gray-800/50'
        : 'sticky w-full shadow-sm',
      'sm:py-3 py-1.5', // Smaller padding on mobile
    ]"
  >
    <div class="max-w-5xl mx-auto px-4">
      <div class="flex items-center justify-between">
        <!-- Left Section: Sidebar Toggle (mobile only) + Logo -->
        <div class="flex items-center gap-2">          
          <!-- Sidebar Toggle Button - MOBILE ONLY -->
          <button
            @click="cart.toggleBurgerMenu()"
            class="flex sm:hidden group relative size-8 flex-shrink-0 items-center justify-center rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition-all duration-200"
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
                class="h-8 sm:h-10 w-auto object-contain"
                loading="eager"
              />
              <div
                class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-0 hover:opacity-100 -translate-x-full hover:translate-x-full transition-all duration-1000 ease-in-out"
              ></div>
            </div>
          </NuxtLink>
        </div>

        <!-- Right Section: Search + Navigation + User Menu -->
        <div class="flex items-center gap-1 sm:gap-1 relative">
          <!-- Search Component -->
          <CommonSearchDropdown ref="searchDropdownRef" />

          <!-- Navigation Buttons - DESKTOP ONLY (AdsyClub & AdsyNews) -->
          <div class="hidden sm:flex items-center gap-2">
      <!-- AdsyClub Button -->
            <NuxtLink
              to="/"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all duration-200 group"
              aria-label="Go to AdsyClub"
            >
              <div
                class="p-1 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-sm transition-transform duration-300 group-hover:scale-110 group-hover:rotate-3"
              >
                <BarChartBig class="h-3.5 w-3.5" />
              </div>
              <span class="relative overflow-hidden">
                AdsyClub
                <span
                  class="absolute bottom-0 left-0 w-full h-0.5 bg-blue-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                ></span>
              </span>
            </NuxtLink>            
            <!-- AdsyNews Button -->
            <NuxtLink
              to="/adsy-news"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all duration-200 group"
              aria-label="Go to AdsyNews"
            >
              <div
                class="p-1 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 text-white shadow-sm transition-transform duration-300 group-hover:scale-110 group-hover:rotate-3"
              >
                <Newspaper class="h-3.5 w-3.5" />
              </div>
              <span class="relative overflow-hidden">
                AdsyNews
                <span
                  class="absolute bottom-0 left-0 w-full h-0.5 bg-orange-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                ></span>
              </span>
            </NuxtLink>
          </div>

          <!-- Translate Component - Desktop only -->
          <PublicTranslateHandler class="hidden sm:block px-2" />            
          
          <!-- Not Logged In User Section -->
          <div v-if="!user" class="flex relative menu-container items-center">            <!-- Mobile Profile Icon -->
            <div class="sm:hidden">
              <NuxtLink to="/auth/login">
                <div 
                  class="size-10 rounded-full flex items-center justify-center bg-gray-100 border border-gray-200 shadow-sm hover:bg-gray-50 transition-colors duration-200"
                >
                  <UIcon name="i-material-symbols-person-rounded" class="w-6 h-6 text-gray-500" />
                </div>
              </NuxtLink>
            </div>
            
            <!-- Login Button (Desktop) -->
            <UButton
              to="/auth/login"
              label="Login/Register"
              color="gray"
              class="hidden sm:flex"
              :ui="{
                size: { sm: 'text-xs md:text-sm' },
                padding: { sm: 'px-2 py-1 md:px-2.5 md:py-1.5' },
                icon: { size: { sm: 'w-2 h-2 md:w-2.5 md:h-2.5' } },
              }"
              size="md"
            />
          </div>
          
          <!-- Logged In User Section -->
          <div v-else class="flex relative menu-container items-center z-40">
            <!-- User Action Buttons -->
            <div class="flex items-center gap-1.5 pr-1.5" v-if="user && user.user">              
              
              
              
              <!-- QR Code Button with Tailwind styling -->              
               <div @click="showQr = !showQr" class="relative cursor-pointer">
                <div class="size-10 flex items-center justify-center rounded-full transition-all duration-300 shadow-sm hover:bg-gray-100 dark:bg-green-900/30 dark:hover:bg-green-900/50">
                  <UIcon name="i-ic:twotone-qr-code-scanner" class="w-5 h-5 text-green-600 dark:text-green-400" />
                </div>
              </div>
                <!-- QR Code Modal -->
              <UModal v-model="showQr" :ui="{ width: 'w-full sm:max-w-md', background: 'bg-slate-100' }">
                <div class="px-4 py-12 flex flex-col gap-4 items-center justify-center relative rounded-3xl overflow-hidden">
                  <UButton
                    icon="i-heroicons-x-mark"
                    size="sm"
                    color="primary"
                    variant="solid"
                    @click="showQr = false"
                    class="absolute top-2 right-2 rounded-full hover:bg-blue-700 transition-colors duration-200"
                  />
                  <h3 class="text-xl font-semibold text-green-700">AdsyPay</h3>
                  <h3 class="text-xl font-semibold">Scan My QR Code</h3>
                  <div class="border p-4 rounded-lg shadow-sm bg-white">
                    <NuxtImg class="w-[250px]" :src="`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${user.user.phone}`" alt="QR Code" />
                  </div>
                </div>
              </UModal>
            </div>
            
            <!-- Mobile User Profile Avatar -->
            <div 
              @click="openMenu = !openMenu"
              class="sm:hidden relative cursor-pointer"
            >            
              <div class="relative">
                <!-- User profile image with Tailwind styling -->
                <div
                  :class=" [
                    'size-10 rounded-full flex items-center justify-center overflow-hidden border-2 border-white shadow-sm',
                    user?.user?.is_pro ? 'shadow-indigo-200 ring-2 ring-indigo-500' : '',
                  ]"
                >
                  <img 
                    v-if="user?.user?.image"
                    :src="user.user.image"
                    :alt="user.user.name || user.user.first_name"
                    class="w-full h-full object-cover rounded-full z-10"
                  />
                  <UIcon v-else name="i-heroicons-user" class="w-6 h-6 text-gray-500 ml-2.5 z-10" />
                </div>

                <!-- Pro Badge with Tailwind -->
                <div
                  v-if="user?.user?.is_pro"
                  class="absolute -top-2.5 -right-3.5 px-2 flex items-center gap-0.5 py-0.5 bg-gradient-to-r from-indigo-500 to-violet-600 text-white rounded-full text-[9px] font-medium shadow-sm"
                >
                  <UIcon name="i-heroicons-shield-check" class="w-3 h-3" />
                  <span>Pro</span>
                </div>

                <!-- Verification Badge with Tailwind -->
                <div
                  v-if="user?.user?.kyc"
                  class="absolute -bottom-1 -right-1 w-4 h-4 bg-white dark:bg-gray-800 flex items-center justify-center rounded-full shadow-sm"
                >
                  <UIcon name="mdi:check-decagram" class="w-4 h-4 text-blue-600" />
                </div>
              </div>
            </div>
            
            <!-- Desktop User Profile Button -->
            <div 
              @click="openMenu = !openMenu" 
              class="relative cursor-pointer transition-all duration-300 rounded-full hover:shadow-md max-sm:hidden"
            >              <div class="flex items-center gap-2 p-1 pl-1 pr-3 border border-gray-200 dark:border-gray-700 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200">
                <!-- Pro Badge -->
                <div 
                  v-if="user?.user?.is_pro"
                  class="flex items-center gap-1 py-0.5 px-2 bg-gradient-to-r from-indigo-500 to-blue-600 text-white text-xs font-medium rounded-full shadow-sm"
                >
                  <UIcon name="i-heroicons-shield-check" class="w-3.5 h-3.5" />
                  <span>Pro</span>
                </div>
                
                <!-- User Info -->
                <div class="flex items-center gap-1.5">
                  <!-- Verified Icon -->
                  <UIcon
                    v-if="user?.user?.kyc"
                    name="mdi:check-decagram"
                    class="w-4 h-4 text-blue-600 dark:text-blue-400" />
                  
                  <!-- Avatar -->
                  <div class="relative size-8 rounded-full overflow-hidden flex items-center justify-center bg-gray-100 dark:bg-gray-700 border border-gray-200 dark:border-gray-600">
                    <img 
                      v-if="user?.user?.image"
                      :src="user.user.image"
                      :alt="user.user.name || user.user.first_name"
                      class="w-full h-full object-cover"
                    />
                    <UIcon v-else name="i-heroicons-user-circle" class="w-6 h-6 text-gray-500 dark:text-gray-300" />
                  </div>
                </div>
                <!-- Dropdown indicator -->
                <UIcon 
                  :name="openMenu ? 'i-heroicons-chevron-up' : 'i-heroicons-chevron-down'" 
                  class="w-4 h-4 text-gray-500 dark:text-gray-400 transition-transform duration-200"
                />
              </div>
            </div>

            <!-- User Dropdown Menu -->
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
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted, onUnmounted, computed, watch } from "vue";
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
const badgeCount = ref(0);
const isScrolled = ref(false);

async function getLogo() {
  const { data } = await get("/bn-logo/");
  logo.value = data;
}

await getLogo();

// Handle clicks outside of user menu dropdown to close it
const handleClickOutside = (event) => {
  // For user menu dropdown
  // Only proceed if the menu is open
  if (openMenu.value) {
    // Get the menu element and any elements that trigger the menu
    const menuElement = menuRef.value;
    const userButton = userButtonRef.value?.$el || userButtonRef.value;
    
    // Find mobile profile avatar if it exists
    const mobileProfileAvatar = document.querySelector('.sm\\:hidden.relative.cursor-pointer');
    
    // Check if click was outside all menu-related elements
    if (
      menuElement && 
      !menuElement.contains(event.target) &&
      ((userButton && !userButton.contains(event.target)) || !userButton) &&
      ((mobileProfileAvatar && !mobileProfileAvatar.contains(event.target)) || !mobileProfileAvatar)
    ) {
      // Close the menu
      openMenu.value = false;
    }
  }
};

// Handle scroll events
const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

// Use proper lifecycle hooks
onMounted(() => {
  // Let the DOM render first before attaching listeners
  nextTick(() => {
    document.addEventListener("click", handleClickOutside, true);
    window.addEventListener("scroll", handleScroll);
  });
});

// Clean up event listeners
onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside, true);
  window.removeEventListener("scroll", handleScroll);
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

// Close sidebar if route changes
watch(() => router.currentRoute.value, () => {
  if (openMenu.value) {
    openMenu.value = false;
  }
});
</script>

<style>
/* Custom animations that can't be done with Tailwind alone */

@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
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

/* For very small screens */
@media (max-width: 385px) {
  .xs\:block { display: block; }
}
</style>
