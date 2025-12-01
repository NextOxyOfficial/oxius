<template>
  <!-- Modern Glass-Morphism Dropdown Menu -->
  <div
    class="absolute right-0 top-12 w-72 sm:w-80 overflow-hidden transition-all duration-300 origin-top-right transform-gpu z-50"
    :class="[
      isOpen
        ? 'opacity-100 scale-100 translate-y-0'
        : 'opacity-0 scale-95 translate-y-2 pointer-events-none',
      'sm:dropdown-menu-position'
    ]"
  >
    <!-- Frosted glass container with modern shadow -->
    <div
      class="backdrop-blur-lg bg-white/95 dark:bg-slate-800/95 rounded-xl shadow-md border border-slate-200/50 dark:border-slate-700/50 overflow-hidden"
      style="box-shadow: 0 4px 16px rgba(0,0,0,0.08);"
    >
      <!-- Animated gradient accent -->
      <div
        class="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-primary-400 via-indigo-500 to-primary-600 animate-gradient-x"
      ></div>

      <!-- User Profile Section -->
      <div class="p-2 relative overflow-hidden">
        <!-- Background pattern -->
        <div
          class="absolute inset-0 bg-grid-slate-100 dark:bg-grid-slate-700/30 opacity-20"
        ></div>
      </div>

      <!-- Membership Section -->
      <div
        class="px-2 pb-3"
        :class="user?.user?.is_pro ? 'pointer-events-none' : ''"
      >
        <!-- Free User Version -->
        <div
          v-if="!user?.user?.is_pro"
          class="relative rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 group transition-all duration-300 hover:shadow-sm hover:border-primary-200 dark:hover:border-primary-800/50"
        >
          <!-- Subtle background pattern -->
          <div
            class="absolute inset-0 bg-graph-paper-slate-100 dark:bg-graph-paper-slate-900 opacity-[0.03] group-hover:opacity-[0.05]"
          ></div>

          <!-- Top Section: Current Plan -->
          <div
            class="relative bg-slate-50 dark:bg-slate-800/60 px-3 py-2.5 border-b border-slate-200 dark:border-slate-700"
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-user"
                  class="w-4 h-4 text-slate-500 dark:text-slate-400"
                />
                <span
                  class="text-xs font-medium text-gray-600 dark:text-slate-300"
                  >{{ $t("current_plan") }}</span
                >
              </div>
              <span
                class="text-2xs px-2 py-0.5 bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-full font-medium"
              >
                {{ $t("free") }}
              </span>
            </div>
          </div>

          <!-- Bottom Section: Upgrade Action with enhanced hover effects -->
          <div
            @click="upgradeToPro"
            class="relative p-3.5 cursor-pointer group overflow-hidden"
          >
            <!-- Hover background effect -->
            <div
              class="absolute inset-0 bg-gradient-to-r from-indigo-50/0 via-indigo-50 to-indigo-50/0 dark:from-indigo-900/0 dark:via-indigo-900/20 dark:to-indigo-900/0 opacity-0 group-hover:opacity-100 -translate-x-full group-hover:translate-x-0 transition-all duration-700"
            ></div>

            <div class="flex items-center gap-2 relative z-10">
              <!-- Pro Badge Icon with 3D effect -->
              <div
                class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-100 to-purple-100 dark:from-indigo-900/30 dark:to-purple-900/40 flex items-center justify-center shadow-sm border border-indigo-200/80 dark:border-indigo-800/30 transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3"
              >
                <div
                  class="w-5 h-5 text-transparent bg-clip-text bg-gradient-to-br from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400"
                >
                  ⭐
                </div>
              </div>

              <!-- Upgrade Text with micro-interactions -->
              <div class="flex-1">
                <h4
                  class="font-medium text-gray-800 dark:text-white text-sm flex items-center"
                >
                  {{ $t("upgrade_pro") }}
                  <span
                    class="ml-1.5 inline-flex items-center justify-center w-4 h-4 bg-gradient-to-r from-amber-400 to-amber-500 rounded-full text-xs text-white font-semibold transform group-hover:scale-110 transition-transform"
                  >
                    +
                  </span>
                </h4>
                <p
                  class="text-xs text-gray-600 dark:text-slate-400 mt-0.5 max-w-[180px]"
                >
                  {{ $t("upgrade_pro_text") }}
                </p>
              </div>

              <!-- Enhanced Switch Toggle Design -->
              <div
                class="w-11 h-6 rounded-full bg-gradient-to-r from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 p-0.5 flex items-center cursor-pointer relative overflow-hidden group-hover:from-indigo-400 group-hover:to-purple-500 transition-all duration-300"
              >
                <div
                  class="absolute left-0.5 w-5 h-5 rounded-full bg-white shadow-sm transform transition-all duration-500 group-hover:translate-x-5"
                ></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Pro User Version -->
        <div
          v-else
          class="relative rounded-xl overflow-hidden border border-indigo-200 dark:border-indigo-800/40 group transition-all duration-300 hover:shadow-sm"
        >
          <!-- Animated pattern background -->
          <div
            class="absolute inset-0 bg-center opacity-[0.03] group-hover:opacity-[0.07]"
          ></div>

          <!-- Top Section: Current Plan with premium styling -->
          <div
            class="relative bg-gradient-to-r from-indigo-50 to-blue-50 dark:from-indigo-900/50 dark:to-blue-900/30 px-3 py-2.5 border-b border-indigo-100 dark:border-indigo-800/30"
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-sparkles"
                  class="w-4 h-4 text-indigo-600 dark:text-indigo-400"
                />
                <span
                  class="text-xs font-medium text-indigo-700 dark:text-indigo-300"
                  >{{ $t("premium_access") }}</span
                >
              </div>
              <span
                class="text-2xs px-2 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm"
              >
                <div class="flex items-center gap-1">
                  <UIcon
                    name="i-heroicons-shield-check"
                    class="size-4 text-white"
                  />
                  <span>{{ $t("pro") }}</span>
                </div>
              </span>
            </div>
          </div>

          <!-- Bottom Section: Pro Status with enhanced styling -->
          <div
            @click="manageSubscription"
            class="relative p-3.5 cursor-pointer group/inner overflow-hidden"
          >
            <!-- Hover background effect -->
            <div
              class="absolute inset-0 bg-gradient-to-r from-blue-50/0 via-blue-50 to-blue-50/0 dark:from-blue-900/0 dark:via-blue-900/20 dark:to-blue-900/0 opacity-0 group-hover:opacity-100 -translate-x-full group-hover:translate-x-0 transition-all duration-700"
            ></div>

            <div class="flex items-center gap-3 relative z-10">
              <!-- Premium badge with glow effect -->
              <div
                class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/10 to-blue-500/10 dark:from-indigo-600/20 dark:to-blue-600/20 flex items-center justify-center border border-indigo-300 dark:border-indigo-700/50 shadow-sm group-hover/inner:shadow-indigo-200 dark:group-hover/inner:shadow-indigo-900/30 transform transition-all duration-300 group-hover/inner:scale-110"
              >
                <div class="relative">
                  <UIcon
                    name="i-heroicons-shield-check"
                    class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
                  />
                  <div
                    class="absolute inset-0 bg-indigo-400 blur-xl opacity-0 group-hover/inner:opacity-30 transition-opacity duration-500"
                  ></div>
                </div>
              </div>

              <!-- Pro Status Text -->
              <div class="flex-1">
                <h4 class="font-medium text-gray-800 dark:text-white">
                  {{ $t("pro_member") }}
                </h4>
                <p
                  class="text-xs text-gray-600 dark:text-slate-400 mt-0.5 flex items-center"
                >
                  Valid until {{ formatDate(user?.user?.pro_validity) }}
                </p>
              </div>

              <!-- Active premium switch style -->
              <div
                class="w-11 h-6 rounded-full bg-gradient-to-r from-indigo-400 to-blue-500 p-0.5 flex items-center justify-end cursor-pointer shadow-inner"
              >
                <div
                  class="w-5 h-5 rounded-full bg-white shadow-sm transform transition-transform"
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 2026 New Year Reward Section -->
      <div class="px-2 pb-3">
        <NuxtLink
          to="/refer-a-friend#how-it-works"
          @click="closeMenu"
          class="block relative rounded-xl overflow-hidden border border-emerald-200 dark:border-emerald-800/40 group transition-all duration-300 hover:shadow-md hover:border-emerald-300 cursor-pointer"
        >
          <!-- Animated gradient background -->
          <div class="absolute inset-0 bg-gradient-to-r from-emerald-50 via-teal-50 to-emerald-50 dark:from-emerald-900/20 dark:via-teal-900/20 dark:to-emerald-900/20 opacity-80"></div>
          
          <!-- Sparkle decorations -->
          <div class="absolute top-1 right-2 text-lg opacity-70 group-hover:opacity-100 transition-opacity">✨</div>
          <div class="absolute bottom-1 left-2 text-sm opacity-50 group-hover:opacity-80 transition-opacity">🎉</div>

          <div class="relative p-3 flex items-center gap-3">
            <!-- Gift Icon -->
            <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-500 flex items-center justify-center shadow-sm transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3">
              <UIcon name="i-heroicons-gift" class="w-5 h-5 text-white" />
            </div>

            <!-- Text Content -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <h4 class="font-semibold text-emerald-800 dark:text-emerald-300 text-sm">
                  2026 New Year Reward
                </h4>
                <span class="px-1.5 py-0.5 bg-gradient-to-r from-amber-400 to-orange-400 text-white text-[10px] font-bold rounded-full animate-pulse">
                  NEW
                </span>
              </div>
              <p class="text-xs text-emerald-600 dark:text-emerald-400 mt-0.5 truncate">
                Refer friends & earn ৳10!
              </p>
            </div>

            <!-- Arrow -->
            <UIcon 
              name="i-heroicons-arrow-right" 
              class="w-4 h-4 text-emerald-500 transform transition-transform group-hover:translate-x-1" 
            />
          </div>
        </NuxtLink>
      </div>

      <!-- Main Navigation Links with enhanced styling -->
      <div class="px-4 pt-2 pb-3">
        <div class="grid grid-cols-2 gap-2">
          <NuxtLink
            v-for="(link, index) in navigationLinks"
            :key="index"
            :to="link.to"
            class="flex flex-col items-center justify-center py-3 px-2 rounded-xl border bg-gradient-to-br transition-all duration-300 group text-center relative hover:shadow-sm hover:-translate-y-0.5 cursor-pointer"
            :class="[`bg-${link.bg}`, `${link.border}`]"
            @click="closeMenu"
          >
            <!-- FREE Badge (for বিজ্ঞাপন) -->
            <div
              v-if="
                link.badge &&
                link.badge.show &&
                link.badge.type === 'free'
              "
              class="absolute -top-1.5 -right-1.5 bg-white dark:bg-slate-800 rounded-full p-0.5 shadow-sm transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3 z-10"
            >
              <div
                class="bg-gradient-to-r from-slate-400 to-slate-500 text-white text-xs font-semibold px-1.5 py-0.5 rounded-full"
              >
                {{ link.badge.text }}
              </div>
            </div>

            <!-- PRO Badge (for eShop) -->
            <div
              v-if="
                link.badge &&
                link.badge.show &&
                link.badge.type === 'pro'
              "
              class="absolute -top-1.5 -right-1.5 bg-white dark:bg-slate-800 rounded-full p-0.5 shadow-sm transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3 z-10"
            >
              <div
                class="bg-gradient-to-r from-indigo-500 to-blue-600 text-white text-xs font-semibold px-1.5 py-0.5 rounded-full flex items-center"
              >
                <UIcon
                  name="i-heroicons-sparkles"
                  class="w-2 h-2 mr-0.5 text-yellow-200"
                />
                {{ link.badge.text }}
              </div>
            </div>

            <div
              :class="`w-9 h-9 rounded-full flex items-center justify-center ${link.color} mb-1 
                         group-hover:scale-110 transition-transform group-hover:rotate-3`"
            >
              <UIcon :name="link.icon" class="w-5 h-5" />
            </div>
            <span
              class="text-xs font-medium text-slate-700 dark:text-slate-200 relative overflow-hidden"
            >
              {{ link.label }}
              <span
                class="absolute bottom-0 left-0 w-full h-0.5 bg-current transform scale-x-0 origin-left transition-transform group-hover:scale-x-100"
              ></span>
            </span>
          </NuxtLink>
        </div>
      </div>

      <!-- Settings & Logout -->
      <div
        class="px-4 py-3 border-t border-slate-100 dark:border-slate-700/50 space-y-0.5"
      >
        <div class="flex justify-between">
          <!-- Settings Link -->
          <NuxtLink
            to="/settings"
            class="flex items-center gap-2 py-2 px-3 rounded-lg text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/50 transition-colors group"
            @click="closeMenu"
          >
            <div
              class="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center group-hover:bg-slate-200 dark:group-hover:bg-slate-700 transition-colors"
            >
              <UIcon
                name="i-heroicons-cog-6-tooth"
                class="w-4 h-4 text-slate-500 dark:text-slate-400"
              />
            </div>
            <span class="text-sm">{{ $t("settings") }}</span>
          </NuxtLink>

          <!-- Support Link -->
          <NuxtLink
            to="/upload-center"
            class="flex items-center gap-2 py-2 px-3 rounded-lg text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/50 transition-colors group"
            @click="closeMenu"
          >
            <div
              class="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center group-hover:bg-slate-200 dark:group-hover:bg-slate-700 transition-colors"
            >
              <UIcon
                name="i-material-symbols-drive-folder-upload-outline-sharp"
                class="w-4 h-4 text-slate-500 dark:text-slate-400"
              />
            </div>
            <span class="text-sm">{{ $t("verification") }}</span>
          </NuxtLink>
        </div>

        <!-- Logout button with polished design -->
        <button
          @click="handleLogout"
          class="w-full flex items-center gap-2 py-2 px-3 mt-1 rounded-lg text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-all duration-300 group"
        >
          <div
            class="w-7 h-7 rounded-full bg-red-50 dark:bg-red-900/20 flex items-center justify-center group-hover:bg-red-100 dark:group-hover:bg-red-800/30 transition-colors"
          >
            <UIcon
              name="i-heroicons-arrow-right-on-rectangle"
              class="w-4 h-4 text-red-500 dark:text-red-400 transform transition-transform group-hover:-translate-x-0.5"
            />
          </div>
          <span class="text-sm font-medium">{{ $t("logout") }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, useRoute, useI18n } from "#imports";

const { t } = useI18n();
const props = defineProps({
  user: {
    type: Object,
    default: null,
  },
  isOpen: {
    type: Boolean,
    default: false,
  }
});

const emit = defineEmits(['update:isOpen', 'logout', 'upgradeToPro', 'manageSubscription']);

const router = useRouter();
const route = useRoute();

// Navigation links
const navigationLinks = computed(() => [
  {
    label: route.path.includes('/business-network')
      ? 'AdsyClub'
      : t('business_network'),
    to: route.path.includes('/business-network')
      ? '/'
      : '/business-network',
    icon: route.path.includes('/business-network')
      ? 'i-lucide-chart-bar-big'
      : 'i-eos-icons-network',
    color: 'text-orange-600 dark:text-orange-400',
    bg: 'from-orange-100 to-orange-50 dark:from-orange-900/30 dark:to-orange-900/10',
    border: 'border-orange-200 dark:border-orange-800/30',
  },
  {
    label: t('adsy_news'),
    to: '/adsy-news',
    icon: 'i-mdi-newspaper-variant-multiple-outline',
    color: 'text-purple-600 dark:text-purple-400',
    bg: 'from-purple-100 to-purple-50 dark:from-purple-900/30 dark:to-purple-900/10',
    border: 'border-purple-200 dark:border-purple-800/30',
  },
  {
    label: t('ad'),
    to: '/my-classified-services/',
    icon: 'i-heroicons-megaphone',
    color: 'text-emerald-600 dark:text-emerald-400',
    bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
    border: 'border-emerald-200 dark:border-emerald-800/30',
    badge: {
      show: true,
      type: 'free',
      text: t('free'),
    },
  },
  {
    label: t('eshop_manager'),
    to: '/shop-manager/',
    icon: 'i-heroicons-shopping-bag',
    color: 'text-blue-600 dark:text-blue-400',
    bg: 'from-blue-100 to-blue-50 dark:from-blue-900/30 dark:to-blue-900/10',
    border: 'border-blue-200 dark:border-blue-800/30',
    badge: {
      show: true,
      type: 'pro',
      text: t('pro'),
    },
  },
  {
    label: t('adsy_pay'),
    to: '/deposit-withdraw',
    icon: 'i-heroicons-banknotes',
    color: 'text-emerald-600 dark:text-emerald-400',
    bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
    border: 'border-emerald-200 dark:border-emerald-800/30',
  },
  {
    label: t('mobile_recharge'),
    to: '/mobile-recharge',
    icon: 'i-uil-mobile-vibrate',
    color: 'text-orange-600 dark:text-orange-400',
    bg: 'from-orange-100 to-orange-50 dark:from-orange-900/30 dark:to-orange-900/10',
    border: 'border-orange-200 dark:border-orange-800/30',
  },
]);

// Methods
function closeMenu() {
  emit('update:isOpen', false);
}

function upgradeToPro() {
  closeMenu();
  emit('upgradeToPro');
}

function manageSubscription() {
  closeMenu();
  emit('manageSubscription');
}

function handleLogout() {
  emit('logout');
  closeMenu();
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
/* Dropdown menu positioning */
@media (min-width: 641px) {
  .dropdown-menu-position {
    right: 0;
    top: calc(100% + 0.5rem);
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  }
}

.text-2xs {
  font-size: 0.65rem;
  line-height: 1rem;
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

@keyframes gradient-x {
  0%, 100% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
}

.animate-gradient-x {
  animation: gradient-x 10s ease infinite;
  background-size: 200% 200%;
}
</style>
