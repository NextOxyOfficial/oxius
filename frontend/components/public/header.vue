<template>  <div
    class="professional-header z-[99999999] w-full"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 w-full backdrop-blur-md border-b border-slate-200/50 rounded-b-lg shadow-lg'
        : 'sticky w-full shadow-sm',
      'mobile-app-header', // Adding class for mobile app styling
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
    </div>
    <UContainer>
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
            <div class="mobile-menu-redesigned space-y-1 py-2">
              <!-- Home -->
              <NuxtLink to="/" class="mobile-nav-item" @click="isOpen = false">
                <div class="mobile-nav-icon bg-blue-100 text-blue-600">
                  <UIcon name="i-heroicons-home-20-solid" class="text-lg" />
                </div>
                <span class="mobile-nav-text text-blue-700">{{ $t('home') }}</span>
                <UIcon name="i-heroicons-chevron-right" 
                class="mobile-nav-arrow text-blue-500" />
              </NuxtLink>
              
              <!-- Classified Service -->
              <NuxtLink to="#classified-services" class="mobile-nav-item" @click="isOpen = false">
                <div class="mobile-nav-icon bg-emerald-100 text-emerald-600">
                  <UIcon name="i-heroicons-clipboard-document-list" class="text-lg" />
                </div>
                <span class="mobile-nav-text text-emerald-700">{{ $t('classified_service') }}</span>
                <UIcon name="i-heroicons-chevron-right" class="mobile-nav-arrow text-emerald-500" />
              </NuxtLink>
              
              <!-- E-Learning -->
              <NuxtLink to="/courses" class="mobile-nav-item" @click="isOpen = false">
                <div class="mobile-nav-icon bg-purple-100 text-purple-600">
                  <UIcon name="i-heroicons-academic-cap" class="text-lg" />
                </div>
                <span class="mobile-nav-text text-purple-700">{{ $t('elearning') }}</span>
                <UIcon name="i-heroicons-chevron-right" class="mobile-nav-arrow text-purple-500" />
              </NuxtLink>
              
              <!-- Earn Money -->
              <NuxtLink to="#micro-gigs" class="mobile-nav-item" @click="isOpen = false">
                <div class="mobile-nav-icon bg-amber-100 text-amber-600">
                  <UIcon name="i-healthicons:money-bag-outline" class="text-lg" />
                </div>
                <span class="mobile-nav-text text-amber-700">{{ $t('earn_money') }}</span>
                <UIcon name="i-heroicons-chevron-right" class="mobile-nav-arrow text-amber-500" />
              </NuxtLink>
              
              <!-- FAQ -->
              <NuxtLink to="/faq/" class="mobile-nav-item" @click="isOpen = false">
                <div class="mobile-nav-icon bg-red-100 text-red-600">
                  <UIcon name="i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question" class="text-lg" />
                </div>
                <span class="mobile-nav-text text-red-700">{{ $t('faq') }}</span>
                <UIcon name="i-heroicons-chevron-right" class="mobile-nav-arrow text-red-500" />
              </NuxtLink>
              
              <!-- Mobile Recharge -->
              <NuxtLink to="/mobile-recharge" class="mobile-nav-item" @click="isOpen = false">
                <div class="mobile-nav-icon bg-indigo-100 text-indigo-600">
                  <UIcon name="i-ic-baseline-install-mobile" class="text-lg" />
                </div>
                <span class="mobile-nav-text text-indigo-700">মোবাইল রিচার্জ</span>
                <UIcon name="i-heroicons-chevron-right" class="mobile-nav-arrow text-indigo-500" />
              </NuxtLink>
            </div>
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
            <div class="flex items-center gap-4">
              <a
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
        <div class="flex items-center gap-2">
          <!-- Mobile View - Sidebar Menu Button (only visible on mobile) -->
          <div class="md:hidden">
            <UButton
              @click="isOpen = true"
              icon="i-heroicons-bars-3"
              variant="ghost"
              color="gray"
              class="hover:bg-gray-100 rounded-lg transition-all duration-200"
              size="sm"
            />
          </div>

          <!-- Logo for all screens - positioned next to hamburger on mobile -->
          <PublicLogo />
        </div>
        
        <!-- Desktop Navigation Menu - Redesigned -->
        <nav class="hidden md:block">
          <div class="custom-nav-menu">
            <NuxtLink 
              to="/#home" 
              class="nav-item text-blue-600 hover:text-blue-800"
              :class="{ 'active': $route.path === '/' }"
            >
              <UIcon name="i-heroicons-home-20-solid" class="nav-icon" />
              <span>{{ $t('home') }}</span>
              <div class="nav-indicator bg-blue-500"></div>
            </NuxtLink>
            
            <NuxtLink 
              to="/business-network" 
              class="nav-item text-emerald-600 hover:text-emerald-800"
              :class="{ 'active': $route.path === '/business-network' }"
            >
              <UIcon name="i-lucide-globe" class="nav-icon" />
              <span>{{ $t('business_network') }}</span>
              <div class="nav-indicator bg-emerald-500"></div>
            </NuxtLink>
            
            <NuxtLink 
              to="/adsy-news" 
              class="nav-item text-amber-600 hover:text-amber-800"
              :class="{ 'active': $route.path === '/adsy-news' }"
            >
              <UIcon name="i-lucide-newspaper" class="nav-icon" />
              <span>{{ $t('adsy_news') }}</span>
              <div class="nav-indicator bg-amber-500"></div>
            </NuxtLink>
            
            <NuxtLink 
              to="/courses" 
              class="nav-item text-purple-600 hover:text-purple-800"
              :class="{ 'active': $route.path === '/courses' }"
            >
              <UIcon name="i-heroicons-academic-cap" class="nav-icon" />
              <span>{{ $t('elearning') }}</span>
              <div class="nav-indicator bg-purple-500"></div>
            </NuxtLink>
            
            <NuxtLink 
              to="/#micro-gigs" 
              class="nav-item text-red-600 hover:text-red-800"
              :class="{ 'active': $route.path === '/#micro-gigs' }"
            >
              <UIcon name="i-healthicons:money-bag-outline" class="nav-icon" />
              <span>{{ $t('earn_money') }}</span>
              <div class="nav-indicator bg-red-500"></div>
            </NuxtLink>
          </div>
        </nav>
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
                <UIcon
                  name="i-material-symbols-person-rounded"
                  class="size-7 text-gray-500"
                />
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
          <PublicTranslateHandler class="px-2 max-sm:hidden" />          <!-- User Action Buttons - Redesigned -->
          <div class="flex items-center gap-3" v-if="user && user.user">
            <!-- Inbox Button with improved design -->
            <NuxtLink to="/inbox/" class="action-button-container">
              <div class="action-button inbox-button">
                <UIcon name="i-material-symbols:mark-email-unread-outline" class="action-icon" />
                
                <!-- Enhanced Notification Badge -->
                <transition name="badge-pop">
                  <div 
                    v-if="badgeCount > 0" 
                    class="notification-badge"
                  >
                    {{ badgeCount > 99 ? '99+' : badgeCount }}
                  </div>
                </transition>
              </div>
            </NuxtLink>
            
            <!-- QR Code Button with improved design -->
            <div @click="showQr = !showQr" class="action-button-container">
              <div class="action-button qr-button">
                <UIcon name="i-ic:twotone-qr-code-scanner" class="action-icon" />
              </div>
            </div>
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
                  size="sm"
                  color="primary"
                  variant="solid"
                  @click="showQr = false"
                  class="absolute top-2 right-2 rounded-full"
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
          </div>          <!-- Redesigned Mobile User Profile Avatar -->
          <div
            @click="openMenu = !openMenu"
            class="sm:hidden relative cursor-pointer"
          >
            <div class="mobile-profile-container">
              <!-- User profile image with enhanced styling -->
              <div
                :class="[
                  'mobile-avatar-container',
                  user?.user?.is_pro ? 'pro-avatar' : 'standard-avatar',
                ]"
              >
                <img
                  v-if="user?.user?.image"
                  :src="user.user.image"
                  :alt="user.user.name || user.user.first_name"
                  class="mobile-avatar-image"
                />
                <UIcon
                  v-else
                  name="i-heroicons-user"
                  class="mobile-avatar-placeholder"
                />
              </div>

              <!-- Enhanced Pro Badge -->
              <div
                v-if="user?.user?.is_pro"
                class="mobile-pro-badge"
              >
                <UIcon name="i-heroicons-shield-check" class="mobile-pro-icon" />
                <span>Pro</span>
              </div>

              <!-- Enhanced Verification Badge -->
              <div
                v-if="user?.user?.kyc"
                class="mobile-verified-badge"
              >
                <UIcon name="mdi:check-decagram" class="mobile-verified-icon" />
              </div>
            </div>
          </div><!-- Redesigned Desktop User Profile Button -->
          <div 
            @click="openMenu = !openMenu" 
            class="user-profile-button max-sm:hidden"
          >
            <div class="user-profile-content">
              <!-- Pro Badge -->
              <div 
                v-if="user?.user?.is_pro"
                class="pro-badge"
              >
                <UIcon name="i-heroicons-shield-check" class="pro-icon" />
                <span>Pro</span>
              </div>
              
              <!-- User Info -->
              <div class="user-info">
                <!-- Verified Icon -->
                <UIcon
                  v-if="user?.user?.kyc"
                  name="mdi:check-decagram"
                  class="verified-icon" />
                
                <!-- Avatar & Name -->
                <div class="user-avatar">
                  <img 
                    v-if="user?.user?.image"
                    :src="user.user.image"
                    :alt="user.user.name || user.user.first_name"
                    class="avatar-image"
                  />
                  <UIcon v-else name="i-heroicons-user-circle" class="default-avatar" />
                </div>
               
              </div>
              
              <!-- Dropdown indicator -->
              <UIcon 
                :name="openMenu ? 'i-heroicons-chevron-up' : 'i-heroicons-chevron-down'" 
                class="dropdown-indicator"
              />
            </div>
          </div>

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
import UserDropdownMenu from "./user-dropdown-menu.vue";
const { t } = useI18n();
const { user, logout } = useAuth();
const { get } = useApi();
const { unreadTicketCount, fetchUnreadCount } = useTickets();
const badgeCount = ref(0);
const openMenu = ref(false);
const router = useRouter();
const open = ref(true);
const logo = ref({});
const isOpen = ref(false);
const showQr = ref(false);
// Subscription alert state
const warningDismissed = ref(false);

// Update badge count when unreadTicketCount changes
watch(() => unreadTicketCount.value, (newCount) => {
  badgeCount.value = newCount;
});

// Fetch unread ticket count when component mounts
onMounted(async () => {
  await fetchUnreadCount();
  badgeCount.value = unreadTicketCount.value;
});

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

function navigateToInbox() {
  router.push("/inbox/");
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
  content: "";
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
  content: "";
  position: absolute;
  inset: -1px; /* Slightly smaller than outer ring to create outline */
  background: var(
    --bg-color,
    white
  ); /* Use CSS variable for background color */
  border-radius: 100%;
  z-index: 0; /* Changed from -1 to 0 */
}

/* Set background color for light/dark mode */
:root {
  --bg-color: white;
}

/* Notification badge animation */
@keyframes pulse-subtle {
  0%, 100% {
    opacity: 0.9;
  }
  50% {
    opacity: 1;
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Professional Header Styling */
.professional-header {
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
  background-color: white;
  transition: all 0.3s ease-in-out;
  box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.1);
}

.dark .professional-header {
  background-color: #111827; /* dark:bg-gray-900 */
}

/* Desktop Navigation Menu */
.custom-nav-menu {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border-bottom: 1px solid transparent;
}

.nav-item {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem 0.5rem;
  font-weight: 500;
  transition: all 0.3s;
}

.nav-icon {
  width: 1.25rem;
  height: 1.25rem;
  transition: all 0.2s;
}

.nav-item:hover .nav-icon {
  transform: scale(1.1);
}

.nav-indicator {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 0.125rem;
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.3s;
}

.nav-item:hover .nav-indicator,
.nav-item.active .nav-indicator {
  transform: scaleX(1);
}

/* Mobile Menu Redesign */
.mobile-menu-redesigned {
  border-radius: 0.75rem;
  overflow: hidden;
  background-color: #f9fafb; /* bg-gray-50 */
}

.dark .mobile-menu-redesigned {
  background-color: #1f2937; /* dark:bg-gray-800 */
}

.mobile-nav-item {
  display: flex;
  align-items: center;
  padding: 0.75rem 1rem;
  transition: all 0.2s;
  gap: 0.75rem;
}

.mobile-nav-item:hover {
  background-color: #f3f4f6; /* hover:bg-gray-100 */
}

.dark .mobile-nav-item:hover {
  background-color: #374151; /* dark:hover:bg-gray-700 */
}

.mobile-nav-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2rem;
  height: 2rem;
  border-radius: 9999px;
}

.mobile-nav-text {
  flex: 1;
  font-weight: 500;
  font-size: 0.875rem;
}

.mobile-nav-arrow {
  width: 1rem;
  height: 1rem;
  opacity: 0.5;
}

.mobile-nav-item:hover .mobile-nav-arrow {
  transform: translateX(0.25rem);
  opacity: 0.9;
}

/* Action Buttons */
.action-button-container {
  position: relative;
  cursor: pointer;
}

.action-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 9999px;
  background-color: #f3f4f6; /* bg-gray-100 */
  transition: all 0.3s;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.action-button:hover {
  background-color: #e5e7eb; /* hover:bg-gray-200 */
}

.dark .action-button {
  background-color: #1f2937; /* dark:bg-gray-800 */
}

.dark .action-button:hover {
  background-color: #374151; /* dark:hover:bg-gray-700 */
}

.inbox-button {
  background-color: #eff6ff; /* bg-blue-50 */
}

.inbox-button:hover {
  background-color: #dbeafe; /* hover:bg-blue-100 */
}

.dark .inbox-button {
  background-color: rgba(30, 58, 138, 0.3); /* dark:bg-blue-900/30 */
}

.dark .inbox-button:hover {
  background-color: rgba(30, 58, 138, 0.5); /* dark:hover:bg-blue-900/50 */
}

.qr-button {
  background-color: #ecfdf5; /* bg-green-50 */
}

.qr-button:hover {
  background-color: #d1fae5; /* hover:bg-green-100 */
}

.dark .qr-button {
  background-color: rgba(6, 78, 59, 0.3); /* dark:bg-green-900/30 */
}

.dark .qr-button:hover {
  background-color: rgba(6, 78, 59, 0.5); /* dark:hover:bg-green-900/50 */
}

.action-icon {
  width: 1.25rem;
  height: 1.25rem;
  color: #374151; /* text-gray-700 */
}

.dark .action-icon {
  color: #d1d5db; /* dark:text-gray-300 */
}

.inbox-button .action-icon {
  color: #2563eb; /* text-blue-600 */
}

.dark .inbox-button .action-icon {
  color: #60a5fa; /* dark:text-blue-400 */
}

.qr-button .action-icon {
  color: #059669; /* text-green-600 */
}

.dark .qr-button .action-icon {
  color: #34d399; /* dark:text-green-400 */
}

/* Notification Badge */
.notification-badge {
  position: absolute;
  top: -0.25rem;
  right: -0.25rem;
  min-width: 1.25rem;
  height: 1.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  background-color: #ef4444; /* bg-red-500 */
  color: white;
  font-size: 0.75rem;
  padding: 0 0.25rem;
  font-weight: 600;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  animation: pulse-subtle 2s infinite;
}

/* User Profile Button */
.user-profile-button {
  position: relative;
  cursor: pointer;
  transition: all 0.3s;
  border-radius: 9999px;
}

.user-profile-button:hover {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.user-profile-content {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem;
  padding-left: 0.25rem;
  padding-right: 0.75rem;
  border: 1px solid #e5e7eb; /* border-gray-200 */
  border-radius: 9999px;
  background-color: white;
}

.dark .user-profile-content {
  background-color: #1f2937; /* dark:bg-gray-800 */
  border-color: #374151; /* dark:border-gray-700 */
}

.user-profile-content:hover {
  background-color: #f9fafb; /* hover:bg-gray-50 */
}

.dark .user-profile-content:hover {
  background-color: #374151; /* dark:hover:bg-gray-700 */
}

.pro-badge {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  background-image: linear-gradient(to right, #6366f1, #3b82f6); /* bg-gradient-to-r from-indigo-500 to-blue-600 */
  color: white;
  font-size: 0.75rem;
  padding: 0.125rem 0.5rem;
  border-radius: 9999px;
  font-weight: 500;
}

.pro-icon {
  width: 0.875rem;
  height: 0.875rem;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.verified-icon {
  width: 1rem;
  height: 1rem;
  color: #2563eb; /* text-blue-600 */
}

.dark .verified-icon {
  color: #60a5fa; /* dark:text-blue-400 */
}

.user-avatar {
  position: relative;
  width: 2rem;
  height: 2rem;
  border-radius: 9999px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f3f4f6; /* bg-gray-100 */
}

.avatar-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.default-avatar {
  width: 1.5rem;
  height: 1.5rem;
  color: #6b7280; /* text-gray-500 */
}

.user-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151; /* text-gray-700 */
}

.dark .user-name {
  color: #d1d5db; /* dark:text-gray-300 */
}

.dropdown-indicator {
  width: 1rem;
  height: 1rem;
  color: #6b7280; /* text-gray-500 */
  transition: transform 0.2s;
}

/* Mobile User Profile */
.mobile-profile-container {
  position: relative;
}

.mobile-avatar-container {
  width: 2.75rem;
  height: 2.75rem;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  border: 2px solid white;
}

.pro-avatar {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  background: linear-gradient(135deg, #fff 0%, #fff 100%);
  box-shadow: 0 0 0 2px white, 0 0 0 4px #6366f1;
}

.mobile-avatar-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 9999px;
  position: relative;
  z-index: 10;
}

.mobile-avatar-placeholder {
  width: 1.5rem;
  height: 1.5rem;
  color: #6b7280; /* text-gray-500 */
  margin-left: 0.625rem;
  position: relative;
  z-index: 10;
}

.mobile-pro-badge {
  position: absolute;
  top: -0.25rem;
  right: -0.875rem;
  display: flex;
  align-items: center;
  gap: 0.125rem;
  padding: 0.125rem 0.5rem;
  background-image: linear-gradient(to right, #6366f1, #8b5cf6); /* bg-gradient-to-r from-indigo-500 to-violet-600 */
  color: white;
  border-radius: 9999px;
  font-size: 0.65rem;
  font-weight: 500;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.mobile-pro-icon {
  width: 0.75rem;
  height: 0.75rem;
}

.mobile-verified-badge {
  position: absolute;
  bottom: -0.25rem;
  right: -0.25rem;
  width: 1rem;
  height: 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: white;
  border-radius: 9999px;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.dark .mobile-verified-badge {
  background-color: #1f2937; /* dark:bg-gray-800 */
}

.mobile-verified-icon {
  width: 1rem;
  height: 1rem;
  color: #2563eb; /* text-blue-600 */
}

/* Badge Animation */
.badge-pop-enter-active, .badge-pop-leave-active {
  transition: all 0.3s;
}

.badge-pop-enter-from, .badge-pop-leave-to {
  opacity: 0;
  transform: scale(0.5);
}

@keyframes pulse-subtle {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.9;
    transform: scale(1.05);
  }
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
