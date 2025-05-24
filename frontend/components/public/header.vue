<template>  <div
    class="py-3 z-[99999999] bg-slate-200/70 shadow-sm rounded-b-lg dark:bg-black max-w-[1280px] md:mx-auto"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 mx-auto backdrop-blur-sm border-b border-slate-200/50 rounded-b-lg'
        : 'sticky',
      'mobile-app-header' // Adding class for mobile app styling
    ]"
  >
    <!-- Subscription Warnings - Always visible regardless of scroll state -->
    <div class="subscription-warnings relative px-4">
      <!-- Pre-expiration Warning (Closable) -->
      <transition name="fade">
        <div
          v-if="shouldShowWarning && !warningDismissed"
          class="mx-auto my-2 px-4 relative overflow-hidden rounded-lg border border-amber-300/70 dark:border-amber-600/50 group transition-all duration-300 hover:shadow-sm"
        >
          <!-- Premium glass background -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-amber-50/90 via-amber-50/80 to-amber-100/90 dark:from-amber-900/30 dark:via-amber-800/20 dark:to-amber-900/30 backdrop-blur-md"
          ></div>

          <!-- Premium effects -->
          <div
            class="absolute -left-20 -top-20 w-40 h-40 bg-amber-200/20 rounded-full blur-2xl transform-gpu"
          ></div>
          <div
            class="absolute -right-20 -bottom-20 w-40 h-40 bg-amber-300/20 rounded-full blur-2xl transform-gpu"
          ></div>

          <!-- Shimmering line -->
          <div
            class="absolute left-0 top-0 h-px w-full bg-gradient-to-r from-transparent via-amber-400/50 dark:via-amber-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>
          <div
            class="absolute left-0 bottom-0 h-px w-full bg-gradient-to-r from-transparent via-amber-400/50 dark:via-amber-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>

          <div
            class="relative z-10 p-2.5 sm:p-3.5 flex items-center justify-between"
          >
            <!-- Left side with icon and text -->
            <div class="flex items-center gap-2 sm:gap-3">
              <!-- Premium icon with pulse effect -->
              <div class="relative hidden xs:block">
                <div
                  class="w-10 h-10 rounded-full bg-gradient-to-br from-amber-100 to-amber-200 dark:from-amber-800 dark:to-amber-700 border border-amber-300/50 dark:border-amber-600/30 flex items-center justify-center shadow-inner"
                >
                  <UIcon
                    name="i-heroicons-clock"
                    class="w-5 h-5 text-amber-600 dark:text-amber-400"
                  />
                </div>
                <div
                  class="absolute -inset-1.5 bg-amber-300/20 blur-md rounded-full animate-pulse-slow opacity-50"
                ></div>
              </div>

              <!-- Alert content - simplified to just the title -->

              <div class="inline-flex items-center gap-2">
                <UIcon
                  name="i-icon-park-outline-caution"
                  class="size-5 text-amber-800"
                />
                <h3 class="text-xs sm:text-sm font-medium text-amber-800">
                  {{ $t("subscription_expiring") }}
                  <span class="inline-block ml-1 font-semibold">
                    {{ daysRemaining }}
                    {{ daysRemaining === 1 ? $t("day") : $t("days") }}
                  </span>
                </h3>
              </div>
            </div>

            <!-- Right side with actions -->
            <div class="flex items-center gap-2">
              <UButton
                @click="dismissWarning"
                size="2xs"
                variant="ghost"
                color="gray"
                icon="i-heroicons-x-mark"
                class="!p-1 hover:rotate-90 transition-transform"
                aria-label="Dismiss"
              />
            </div>
          </div>
        </div>
      </transition>

      <!-- Post-expiration Alert (Not Closable) -->
      <transition name="fade">
        <div
          v-if="isExpired"
          class="mx-auto my-2 relative overflow-hidden rounded-lg border border-red-400/70 dark:border-red-600/40 group transition-all duration-300 shadow-sm hover:shadow-sm"
        >
          <!-- Premium glass background with subtle animation -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-red-50/90 via-red-100/80 to-red-50/90 dark:from-red-900/30 dark:via-red-800/20 dark:to-red-900/30 backdrop-blur-md"
          ></div>

          <!-- Premium effects -->
          <div
            class="absolute -left-20 -top-20 w-40 h-40 bg-red-200/20 rounded-full blur-2xl transform-gpu"
          ></div>
          <div
            class="absolute -right-20 -bottom-20 w-40 h-40 bg-red-300/20 rounded-full blur-2xl transform-gpu"
          ></div>

          <!-- Pulsing border effect -->
          <div
            class="absolute inset-0 rounded-lg border-2 border-red-400/20 dark:border-red-600/20 scale-[0.98] animate-pulse-slow"
          ></div>

          <!-- Shimmering lines -->
          <div
            class="absolute left-0 top-0 h-px w-full bg-gradient-to-r from-transparent via-red-400/50 dark:via-red-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>
          <div
            class="absolute left-0 bottom-0 h-px w-full bg-gradient-to-r from-transparent via-red-400/50 dark:via-red-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>

          <div
            class="relative z-10 p-3 sm:p-3.5 flex items-center justify-between"
          >
            <!-- Left side with icon and text -->
            <div class="flex items-center gap-2 sm:gap-3">
              <!-- Premium alert icon with effect -->
              <div class="relative hidden xs:block">
                <div
                  class="w-10 h-10 rounded-full bg-gradient-to-br from-red-100 to-red-200 dark:from-red-800 dark:to-red-700 border border-red-300/50 dark:border-red-600/30 flex items-center justify-center shadow-inner"
                >
                  <UIcon
                    name="i-heroicons-exclamation-triangle"
                    class="w-5 h-5 text-red-600 dark:text-red-400"
                  />
                </div>
                <div
                  class="absolute -inset-1.5 bg-red-300/30 blur-md rounded-full animate-pulse opacity-70"
                ></div>
              </div>

              <!-- Simplified alert content - just the title -->
              <h3
                class="text-xs sm:text-sm font-medium text-red-800 dark:text-red-300"
              >
                {{ $t("subscription_expired") }}
              </h3>
            </div>

            <!-- Premium renewal button -->
            <UButton
              @click="renewSubscription"
              size="2xs"
              color="red"
              variant="solid"
              class="!py-1 !px-2.5 group hover:bg-red-600 transition-colors duration-300 relative overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gradient-to-r from-red-400/0 via-white/10 to-red-400/0 -translate-x-full group-hover:translate-x-full transition-transform duration-700 ease-in-out"
              ></div>
              <span
                class="text-2xs sm:text-xs whitespace-nowrap flex items-center gap-1 relative z-10"
              >
                {{ $t("renew_now") }}
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 group-hover:translate-x-0.5 transition-transform"
                />
              </span>
            </UButton>
          </div>
        </div>
      </transition>
    </div>    <UContainer>
      <!-- <PublicDonation /> -->
      <USlideover
        v-model="isOpen"
        side="left"
        :ui="{
          width: 'w-screen max-w-[300px]',
          height: 'max-h-screen',
        }"
        class="bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800 shadow-sm"
      >
        <UCard
          :ui="{
            header: {
              padding: 'pb-0.5',
            },
            ring: '',
            rounded: '',
            shadow: '',
            body: {
              padding: '',
            },
          }"
          class="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 mt-4 overflow-y-scroll"
        >
          <div class="w-full flex justify-end pt-12 px-4">
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark-20-solid"
              class="text-gray-500 hover:text-gray-700 dark:text-gray-500 dark:hover:text-gray-300 transition-transform transform hover:scale-110"
              @click="isOpen = false"
            />
          </div>
          <div class="px-4">
            <PublicTranslateHandler class="px-2 mt-3" />
          </div>
          <!-- Navigation Links -->
          <div class="px-4 py-6">
            <h3
              class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-2 px-4"
            >
              {{ $t("menu") }}
            </h3>
            <UVerticalNavigation
              :links="[
                {
                  label: $t('home'),
                  to: '/',
                  icon: 'i-heroicons-home',
                },
                {
                  label: $t('classified_service'),
                  to: '#classified-services',
                  icon: 'i-heroicons-clipboard-document-list',
                },
                {
                  label: $t('earn_money'),
                  to: '#micro-gigs',
                  icon: 'i-healthicons:money-bag-outline',
                },
                {
                  label: $t('faq'),
                  to: '/faq/',
                  icon: 'i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question',
                },
                {
                  label: 'মোবাইল রিচার্জ',
                  to: '/mobile-recharge',
                  icon: 'i-ic-baseline-install-mobile',
                },
              ]"
              :ui="{
                padding: 'py-3 px-4',
              }"
              class="space-y-2"
            >
              <template #default="{ link }">
                <span @click="isOpen = false">{{ link.label }}</span>
              </template>
            </UVerticalNavigation>
          </div>

          <!-- Download App Section -->
          <div class="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <h3
              class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-4"
            >
              {{ $t("download_our_app") }}
            </h3>
            <div class="flex items-center gap-4">
              <NuxtLink
                to="/coming-soon"
                class="w-32 h-10 bg-gray-100 dark:bg-gray-800 rounded-lg shadow-sm flex items-center justify-center hover:bg-gray-200 dark:hover:bg-gray-700 transition overflow-hidden"
              >
                <img
                  src="/static/frontend/images/google.png"
                  alt="Google Play"
                  class="w-full h-full object-contain"
                />
              </NuxtLink>
              <NuxtLink
                href="/coming-soon"
                class="w-32 h-10 bg-gray-100 dark:bg-gray-800 rounded-lg shadow-sm flex items-center justify-center hover:bg-gray-200 dark:hover:bg-gray-700 transition overflow-hidden"
              >
                <img
                  src="/static/frontend/images/apple.png"
                  alt="App Store"
                  class="w-full h-full object-contain"
                />
              </NuxtLink>
            </div>
          </div>

          <!-- Social Media Share Section -->
          <div class="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <h3
              class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-4"
            >
              {{ $t("follow_us") }}
            </h3>
            <div class="flex items-center gap-4">              <a
                href="https://www.facebook.com/profile.php?id=61573940373294"
                target="_blank"
                class="w-10 h-10 rounded-full bg-blue-500 text-white flex items-center justify-center hover:bg-blue-600 transition"
                aria-label="Facebook"
              >
                <UIcon name="i-logos-facebook" class="w-5 h-5" />
              </a>
              
            </div>
          </div>

          <!-- Footer Section -->
        </UCard>
      </USlideover>
      
      <div class="flex items-center justify-between gap-2 lg:gap-6 px-3">        
        <!-- Mobile Layout: Menu Button and Logo grouped together -->
        <div class="flex items-center gap-4">
          <!-- Mobile View - Sidebar Menu Button (only visible on mobile) -->
          <div class="md:hidden">
            <UButton
              @click="isOpen = true"
              icon="i-ci-hamburger-md"
              variant="outline"
              color="gray"
              size="sm"
            />
          </div>
          
          <!-- Logo for all screens - positioned next to hamburger on mobile -->
          <PublicLogo />
        </div>
        
        <!-- Desktop Navigation Menu -->
        <div class="hidden md:block">
          <UHorizontalNavigation
            :links="[
              {
                label: $t('home'),
                to: '/#home',
                icon: 'i-heroicons-home',
              },
              {
                label: $t('business_network'),
                to: '/business-network',
                icon: 'i-lucide-globe',
              },
              {
                label: $t('adsy_news'),
                to: '/adsy-news',
                icon: 'i-lucide-newspaper',
              },
              {
                label: $t('earn_money'),
                to: '/#micro-gigs',
                icon: 'i-healthicons:money-bag-outline',
              },
              {
                label: $t('mobile_recharge'),
                to: '/mobile-recharge',
                icon: 'i-uil-mobile-vibrate',
              },
            ]"
            class="border-b border-gray-200 dark:border-gray-800 text-lg"
            :ui="{
              wrapper: 'w-auto',
              label: 'text-base',
              active: 'after:hidden',
            }"
          />
        </div>
          <!-- Not Logged In User Section -->
        <div v-if="!user" class="flex relative menu-container items-center">
          <!-- Desktop language switcher -->
          <PublicTranslateHandler class="px-2 max-sm:hidden" />
          
          <!-- Mobile Profile Icon -->
          <div class="sm:hidden">
            <NuxtLink to="/auth/login">
              <div 
                class="size-10 rounded-full flex pl-1 items-center justify-center bg-gray-100 border border-gray-200 shadow-sm"
              >
                <UIcon name="i-material-symbols-person-rounded" class="size-7 text-gray-500" />
              </div>
            </NuxtLink>
          </div>
          
          <!-- Login Button -->
          <UButton
            to="/auth/login"
            label="Login/Register"
            color="gray"
            class="max-sm:hidden"
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
          <!-- Logged In User Section -->
        <div v-else class="flex relative menu-container items-center z-40">
          <!-- Desktop language switcher -->
          <PublicTranslateHandler class="px-2 max-sm:hidden" />
          
          <!-- QR Code Button -->
          <div class="flex items-center" v-if="user && user.user">
            <UButton
              icon="i-ic:twotone-qr-code-scanner"
              size="xl"
              :ui="{
                size: { md: 'text-sm' },
                padding: { md: 'px-2.5 py-1.5 sm:px-3 sm:py-2' },
              }"
              color="primary"
              variant="ghost"
              @click="showQr = !showQr"
              block
            />
            <UModal
              v-model="showQr"
              :ui="{
                width: 'w-full sm:max-w-md',
                background: 'bg-slate-100',
              }"
            >
              <div
                class="px-4 py-12 flex flex-col gap-4 items-center justify-center relative rounded-3xl overflow-hidden"
              >
                <UButton
                  icon="i-heroicons-x-mark"
                  size="md"
                  color="primary"
                  variant="solid"
                  @click="showQr = false"
                  class="absolute top-1 rounded-full"
                />

                <h3 class="text-xl font-semibold text-green-700">AdsyPay</h3>
                <h3 class="text-xl font-semibold">Scan My QR Code</h3>
                <div class="border p-4 rounded-lg shadow-sm bg-white">
                  <NuxtImg
                    class="w-[250px]"
                    :src="`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${user.user.phone}`"
                  ></NuxtImg>
                </div>
              </div>
            </UModal>
          </div>          
          <!-- Mobile User Profile Avatar -->
          <div 
            @click="openMenu = !openMenu"
            class="sm:hidden relative cursor-pointer"
          >            <div class="relative">
              <!-- User profile image with pink gradient border for Pro users -->
              <div 
                :class="[
                  'size-11 rounded-full flex items-center justify-center overflow-hidden shadow-sm',
                  user?.user?.is_pro ? 'pro-profile-pink-border' : 'border-2 border-white'
                ]"
              >
                <img 
                  v-if="user?.user?.image"
                  :src="user.user.image"
                  :alt="user.user.name || user.user.first_name"
                  class="size-full object-cover rounded-full relative z-1"
                  style="position: relative; z-index: 1;"
                />
                <UIcon v-else name="i-heroicons-user" class="size-6 text-gray-500 relative z-1" style="position: relative; z-index: 1;" />
              </div>
              
              <!-- Pro Badge for mobile - text at top right -->
              <span
                v-if="user?.user?.is_pro"
                class="absolute -top-1 -right-3.5 px-2  bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-full text-2xs font-semibold shadow-sm"
              >
                Pro
              </span>
              
              <!-- Verification Badge for mobile -->
              <span
                v-if="user?.user?.kyc"
                class="absolute -bottom-1 -right-1 size-4 flex items-center justify-center bg-white rounded-full shadow-sm"
              >
                <UIcon
                  name="mdi:check-decagram"
                  class="size-4 text-blue-600"
                />
              </span>
            </div>
          </div>
          
          <!-- Desktop User Profile Button -->
          <UButton
            size="sm"
            color="primary"
            variant="outline"
            @click="openMenu = !openMenu"
            class="max-sm:hidden"
            :ui="{
              gap: {
                sm: 'gap-x-1 md:gap-x-1.5',
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
          >
            <span
              v-if="user?.user?.is_pro"
              class="text-2xs px-2 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm"
            >
              <div class="flex items-center gap-1">
                <UIcon
                  name="i-heroicons-shield-check"
                  class="size-4 text-white"
                />
                <span class="text-xs">Pro</span>
              </div>
            </span>
            <UIcon
              v-if="user?.user?.kyc"
              name="mdi:check-decagram"
              class="w-5 h-5 text-blue-600"
            />
            <UIcon v-else name="i-heroicons-user-circle" class="text-xl" />

            Hi {{ (user?.user?.first_name).slice(0, 8) }}            <UIcon name="i-heroicons-chevron-down-16-solid" v-if="!openMenu" />
            <UIcon name="i-heroicons-chevron-up-16-solid" v-if="openMenu" /></UButton>
          
          <!-- Modern Glass-Morphism Dropdown Menu using the new component -->
          <UserDropdownMenu 
            :user="user" 
            :is-open="openMenu" 
            @update:is-open="openMenu = $event"
            @upgrade-to-pro="upgradeToPro"
            @manage-subscription="manageSubscription" 
            @logout="logout"
          />
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import UserDropdownMenu from './user-dropdown-menu.vue';
const { t } = useI18n();
const { user, logout } = useAuth();
const { get } = useApi();
const openMenu = ref(false);
const router = useRouter();
const open = ref(true);
const logo = ref({});
const isOpen = ref(false);
const showQr = ref(false);
// Subscription alert state
const warningDismissed = ref(false);

// Calculate days remaining before subscription expiration
const daysRemaining = computed(() => {
  if (!user.value?.user?.pro_validity) return 0;

  const today = new Date();
  const expiryDate = new Date(user.value.user.pro_validity);
  const diffTime = expiryDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays > 0 ? Math.min(diffDays, 7) : 0;
});

// Should show warning only if user is pro and has 1-7 days left
const shouldShowWarning = computed(() => {
  if (!user.value?.user?.is_pro) return false;

  const today = new Date();
  const expiryDate = new Date(user.value?.user?.pro_validity || null);
  const diffTime = expiryDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays > 0 && diffDays <= 7;
});

// Check if subscription is expired
const isExpired = computed(() => {
  if (!user.value?.user?.is_pro || !user.value?.user?.pro_validity)
    return false;

  const today = new Date();
  const expiryDate = new Date(user.value.user.pro_validity);

  return today > expiryDate;
});

// Dismiss the warning for the current session
function dismissWarning() {
  warningDismissed.value = true;
  // Store in localStorage to remember dismissal
  localStorage.setItem("subscription_warning_dismissed", "true");
  localStorage.setItem(
    "subscription_warning_dismissed_date",
    new Date().toDateString()
  );
}

// Open the subscription renewal page
function renewSubscription() {
  openMenu.value = false; // Close any open menu
  router.push("/upgrade-to-pro");
}

// Check localStorage on mount to see if warning was dismissed
onMounted(() => {
  const storedDismissalDate = localStorage.getItem(
    "subscription_warning_dismissed_date"
  );
  if (storedDismissalDate) {
    // Only consider it dismissed if the stored date is from today
    const today = new Date().toDateString();
    warningDismissed.value = storedDismissalDate === today;
  } else {
    warningDismissed.value = false;
  }

  // Rest of your existing onMounted code...
});
const colorMode = useColorMode();
colorMode.preference = "light";
onMounted(() => {
  localStorage.setItem("nuxt-color-mode", "light");
});

async function getLogo() {
  const res = await get("/logo/");
  logo.value = res.data;
}
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
getLogo();

defineShortcuts({
  o: () => (open.value = !open.value),
});

const handleClickOutside = (event) => {
  const menuContainer = document.querySelector(".menu-container");
  if (menuContainer && !menuContainer.contains(event.target)) {
    openMenu.value = false;
  }
};

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
});

// if sidebar clicked and route changes, close sidebar if opened
watch(router.currentRoute, () => {
  if (openMenu.value) {
    openMenu.value = false;
    isOpen.value = false;
  }
});

const isScrolled = ref(false);

// Function to handle scroll event
const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

// Add event listener on component mount
onMounted(() => {
  window.addEventListener("scroll", handleScroll);
  document.addEventListener("click", handleClickOutside);
});

// Clean up event listeners
onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
  document.removeEventListener("click", handleClickOutside);
});

// Example logic for subscription warnings
onMounted(() => {
  const subscriptionEndDate = new Date(user?.user?.pro_validity);
  const currentDate = new Date();
  const timeDifference = subscriptionEndDate - currentDate;
  daysRemaining.value = Math.ceil(timeDifference / (1000 * 60 * 60 * 24));

  if (daysRemaining.value <= 7 && daysRemaining.value > 0) {
    shouldShowWarning.value = true;
  } else if (daysRemaining.value <= 0) {
    isExpired.value = true;
  }
});
</script>

<style scoped>
/* Mobile app specific styling for the header */
@media (max-width: 640px) {
  .mobile-app-header {
    padding-top: 6px;
    padding-bottom: 6px;
  }

  .mobile-app-header .menu-container {
    gap: 8px;
  }
  
  /* App-like native styling */
  .mobile-app-header .flex {
    justify-content: space-between;
  }
  
  /* Make the logo slightly smaller on mobile for better spacing */
  .mobile-app-header .public-logo img {
    max-height: 34px;
  }
}

/* Menu container positioning for desktop */
@media (min-width: 641px) {
  .menu-container {
    position: relative;
  }
  
  .dropdown-menu-position {
    right: 0;
    top: calc(100% + 0.5rem);
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  }
}

/* Add this style if you want to animate the transition */
.fixed {
  animation: slideDown 0.3s ease-in-out;
  width: 100%;
  max-width: 1280px;
}

@keyframes slideDown {
  from {
    transform: translateY(-100%);
  }
  to {
    transform: translateY(0);
  }
}
.text-2xs {
  font-size: 0.65rem;
  line-height: 1rem;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* For extra small screens */
@media (max-width: 385px) {
  .xs\:block {
    display: block;
  }
}
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 3s linear infinite;
}

.animate-pulse-slow {
  animation: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

/* Dropdown menu positioning */
@media (min-width: 641px) {
  .menu-container > div.absolute {
    right: 0 !important;
  }
  
  .dropdown-menu-position {
    right: 0;
    top: calc(100% + 0.5rem);
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  }
}

/* Pink gradient border for Pro user profile */
.pro-profile-pink-border {
  position: relative;
  border: none;
  isolation: isolate; /* Create a new stacking context */
}

/* Pink gradient outline - the outer ring */
.pro-profile-pink-border::before {
  content: '';
  position: absolute;
  inset: -3px; /* Creates border effect */
  background: linear-gradient(135deg, #ec4899, #d946ef, #c026d3);
  border-radius: 100%;
  z-index: 0; /* Changed from -1 to 0 */
  animation: rotate-border 6s linear infinite; /* Slowed down animation for better performance */
  will-change: transform; /* Optimize animation performance */
}

/* Inner white space to create the outline effect */
.pro-profile-pink-border::after {
  content: '';
  position: absolute;
  inset: -1px; /* Slightly smaller than outer ring to create outline */
  background: var(--bg-color, white); /* Use CSS variable for background color */
  border-radius: 100%;
  z-index: 0; /* Changed from -1 to 0 */
}

/* Set background color for light/dark mode */
:root {
  --bg-color: white;
}

.dark .pro-profile-pink-border::after {
  --bg-color: #1e293b; /* Dark mode background color - matches slate-800 */
}

@keyframes rotate-border {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

/* Media query to disable animations on low-performance devices or when battery is low */
@media (prefers-reduced-motion: reduce) {
  .pro-profile-pink-border::before {
    animation: none;
  }
}
</style>
