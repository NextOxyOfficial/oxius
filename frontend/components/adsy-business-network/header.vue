<template>
  <div
    class="fixed top-0 left-0 right-0 z-50 rounded-e-sm max-w-5xl w-full mx-auto"
  >
    <header class="sticky top-0 z-50 px-1">
      <div class="">
        <!-- Main Navigation -->
        <div
          class="flex flex-row gap-4 justify-between shadow-sm items-center px-4 py-2 sm:px-6 lg:px-8 bg-white rounded-b-md w-full"
        >
          <div @click="cart.toggleBurgerMenu()" class="sm:hidden">
            <UIcon name="i-lineicons-menu-hamburger-1" class="h-6 w-6" />
          </div>
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <NuxtLink to="/business-network/">
                <NuxtImg
                  v-if="logo[0]?.image"
                  :src="logo[0].image"
                  alt="Adsy News Logo"
                  width="150"
                  height="50"
                  class="h-7 mr-4 sm:h-10 w-auto object-fit"
                />
              </NuxtLink>
            </div>
          </div>
          <div class="flex items-center sm:justify-end space-x-2">
            <div class="relative max-sm:flex-1">
              <input
                type="text"
                placeholder="Search topics..."
                v-model="searchQuery"
                class="w-full sm:w-64 pl-2 pr-11 py-1 border border-gray-300 rounded-xl text-mb focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-200/80 text-gray-900"
                @input="performSearch"
              />
              <SearchIcon
                class="absolute right-3 top-2.5 h-4 w-4 text-gray-500"
              />
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="absolute right-7 top-2.5"
              >
                <XIcon class="h-4 w-4 text-gray-500" />
              </button>

              <!-- Auto-loading search results -->
              <div
                v-if="searchQuery"
                class="absolute top-full left-0 right-0 mt-2 bg-white rounded-md shadow-lg z-10 max-h-96 overflow-y-auto border border-gray-200"
              >
                <div class="p-3 border-b border-gray-200">
                  <p class="text-sm text-gray-700">
                    Search results for:
                    <span class="font-medium">{{ searchQuery }}</span>
                  </p>
                </div>
                <div class="divide-y divide-gray-100">
                  <div
                    v-for="result in searchResults"
                    :key="result.id"
                    class="p-3 hover:bg-gray-50 cursor-pointer"
                    @click="selectArticle(result)"
                  >
                    <p class="text-sm font-medium text-gray-900">
                      {{ result.title }}
                    </p>
                    <p class="text-xs text-gray-500 mt-1">
                      <span
                        class="bg-primary/10 text-primary px-2 py-0.5 rounded-full text-xs"
                      >
                        {{ getCategoryName(result.categoryId) }}
                      </span>
                    </p>
                  </div>
                </div>
                <div
                  v-if="searchResults.length === 0 && searchQuery"
                  class="p-4 text-center text-gray-500"
                >
                  No results found for "{{ searchQuery }}"
                </div>
              </div>
            </div>
          </div>
          <div class="flex gap-2 ml-auto max-sm:hidden">
            <UButton to="/" class="bg-slate-700/80 max-sm:hidden"
              >AdsyClub</UButton
            >
            <UButton to="/adsy-news" class="bg-slate-700/80 max-sm:hidden"
              >AdsyNews</UButton
            >
          </div>
          <div v-if="!user" class="flex relative menu-container">
            <PublicTranslateHandler class="px-2 max-sm:hidden" />
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
              <template #trailing>
                <UIcon
                  name="i-heroicons-arrow-right-20-solid"
                  class="w-5 h-5"
                />
              </template>
            </UButton>
          </div>
          <div v-else class="flex relative menu-container">
            <PublicTranslateHandler class="px-2 max-sm:hidden" />
            
            <UButton
              size="sm"
              color="primary"
              variant="outline"
              @click="openMenu = !openMenu"
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

              Hi {{ (user?.user?.first_name).slice(0, 8) }}
              <UIcon
                name="i-heroicons-chevron-down-16-solid"
                v-if="!openMenu"
              />
              <UIcon name="i-heroicons-chevron-up-16-solid" v-if="openMenu" />
            </UButton>

            <!-- Modern Glass-Morphism Dropdown Menu -->
            <div
              class="absolute right-3 top-11 w-72 overflow-hidden transition-all duration-300 origin-top-right transform-gpu"
              :class="
                openMenu
                  ? 'opacity-100 scale-100 translate-y-0'
                  : 'opacity-0 scale-95 translate-y-2 pointer-events-none'
              "
            >
              <!-- Frosted glass container with modern shadow -->
              <div
                class="backdrop-blur-lg bg-white/95 dark:bg-slate-800/95 rounded-2xl shadow-xl border border-slate-200/50 dark:border-slate-700/50 overflow-hidden"
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
                    class="relative rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 group transition-all duration-300 hover:shadow-md hover:border-primary-200 dark:hover:border-primary-800/50"
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
                            class="text-xs font-medium text-slate-600 dark:text-slate-300"
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
                            class="font-medium text-slate-800 dark:text-white text-sm flex items-center"
                          >
                            {{ $t("upgrade_pro") }}
                            <span
                              class="ml-1.5 inline-flex items-center justify-center w-4 h-4 bg-gradient-to-r from-amber-400 to-amber-500 rounded-full text-[8px] text-white font-bold transform group-hover:scale-110 transition-transform"
                            >
                              +
                            </span>
                          </h4>
                          <p
                            class="text-xs text-slate-600 dark:text-slate-400 mt-0.5 max-w-[180px]"
                          >
                            {{ $t("upgrade_pro_text") }}
                          </p>
                        </div>

                        <!-- Enhanced Switch Toggle Design -->
                        <div
                          class="w-11 h-6 rounded-full bg-gradient-to-r from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 p-0.5 flex items-center cursor-pointer relative overflow-hidden group-hover:from-indigo-400 group-hover:to-purple-500 transition-all duration-300"
                        >
                          <div
                            class="absolute left-0.5 w-5 h-5 rounded-full bg-white shadow-md transform transition-all duration-500 group-hover:translate-x-5"
                          ></div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Pro User Version -->
                  <div
                    v-else
                    class="relative rounded-xl overflow-hidden border border-indigo-200 dark:border-indigo-800/40 group transition-all duration-300 hover:shadow-md"
                  >
                    <!-- Animated pattern background -->
                    <div
                      class="absolute inset-0 bg-[url('/img/patterns/circuit.svg')] bg-center opacity-[0.03] group-hover:opacity-[0.07]"
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
                          <h4
                            class="font-medium text-slate-800 dark:text-white"
                          >
                            {{ $t("pro_member") }}
                          </h4>
                          <p
                            class="text-xs text-slate-600 dark:text-slate-400 mt-0.5 flex items-center"
                          >
                            Valid until
                            {{ formatDate(user?.user?.pro_validity) }}
                          </p>
                        </div>

                        <!-- Active premium switch style -->
                        <div
                          class="w-11 h-6 rounded-full bg-gradient-to-r from-indigo-400 to-blue-500 p-0.5 flex items-center justify-end cursor-pointer shadow-inner"
                        >
                          <div
                            class="w-5 h-5 rounded-full bg-white shadow-md transform transition-transform"
                          ></div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Main Navigation Links with enhanced styling -->
                <div class="px-4 pt-2 pb-3">
                  <div class="grid grid-cols-2 gap-2">
                    <NuxtLink
                      v-for="(link, index) in [
                        {
                          label: t('ad'),
                          to: '/my-classified-services/',
                          icon: 'i-heroicons-megaphone',
                          color: 'text-emerald-600 dark:text-emerald-400',
                          bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
                          border:
                            'border-emerald-200 dark:border-emerald-800/30',
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
                          label: t('business_network'),
                          to: '/business-network',
                          icon: 'i-eos-icons-network',
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
                          label: $t('transaction'),
                          to: '/deposit-withdraw',
                          icon: 'i-heroicons-banknotes',
                          color: 'text-emerald-600 dark:text-emerald-400',
                          bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
                          border:
                            'border-emerald-200 dark:border-emerald-800/30',
                        },
                        {
                          label: $t('mobile_recharge'),
                          to: '/mobile-recharge',
                          icon: 'i-uil-mobile-vibrate',
                          color: 'text-orange-600 dark:text-orange-400',
                          bg: 'from-orange-100 to-orange-50 dark:from-orange-900/30 dark:to-orange-900/10',
                          border: 'border-orange-200 dark:border-orange-800/30',
                        },
                      ]"
                      :key="index"
                      :to="link.to"
                      class="flex flex-col items-center justify-center py-3 px-2 rounded-xl border bg-gradient-to-br transition-all duration-300 group text-center relative hover:shadow-md hover:-translate-y-0.5 cursor-pointer"
                      :class="[`bg-${link.bg}`, `${link.border}`]"
                      @click="openMenu = false"
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
                          class="bg-gradient-to-r from-slate-400 to-slate-500 text-white text-[8px] font-bold px-1.5 py-0.5 rounded-full"
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
                          class="bg-gradient-to-r from-indigo-500 to-blue-600 text-white text-[8px] font-bold px-1.5 py-0.5 rounded-full flex items-center"
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
                      @click="openMenu = false"
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
                      @click="openMenu = false"
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
                    @click="
                      logout();
                      openMenu = false;
                    "
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
          </div>
        </div>
      </div>
    </header>
  </div>
</template>

<script setup>
const { t } = useI18n();
const { get } = useApi();
const { user, logout } = useAuth();
const logo = ref([]);
const cart = useStoreCart();
const showQr = ref(false);
const openMenu = ref(false);

async function getLogo() {
  const { data } = await get("/bn-logo/");
  logo.value = data;
}

await getLogo();

import {
  SunIcon,
  MenuIcon,
  XIcon,
  SearchIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  CalendarIcon,
  ClockIcon,
  MessageSquareIcon,
  ArrowRightIcon,
  ArrowLeftIcon,
  TwitterIcon,
  FacebookIcon,
  LinkIcon,
  CloudIcon,
  CloudRainIcon,
  LayoutGridIcon,
  LayoutListIcon,
  TrendingUpIcon,
} from "lucide-vue-next";

// Navigation state
const mobileMenuOpen = ref(false);

// Search state
const searchQuery = ref("");
const searchResults = ref([]);

// Perform search when query changes
const performSearch = () => {
  // Always show results as user types, even with just 1 character
  if (!searchQuery.value) {
    searchResults.value = [];
    return;
  }

  // Filter articles based on search query
  const query = searchQuery.value.toLowerCase();

  searchResults.value = articles.value.filter((article) => {
    return article.title.toLowerCase().includes(query);
  });
};

// Clear search
const clearSearch = () => {
  searchQuery.value = "";
  searchResults.value = [];
};

// Newsletter
const newsletterEmail = ref("");
const subscribeNewsletter = () => {
  // Simulate subscription
  alert(`Thank you for subscribing with ${newsletterEmail.value}!`);
  newsletterEmail.value = "";
};

// Categories
const categories = ref([
  { id: "all", name: "All News" },
  { id: "world", name: "World" },
  { id: "politics", name: "Politics" },
  { id: "business", name: "Business" },
  { id: "technology", name: "Technology" },
  { id: "science", name: "Science" },
  { id: "health", name: "Health" },
  { id: "sports", name: "Sports" },
  { id: "entertainment", name: "Entertainment" },
]);

const activeCategory = ref("all");
const setActiveCategory = (categoryId) => {
  activeCategory.value = categoryId;
  selectedArticle.value = null;
  mobileMenuOpen.value = false;
};

const getCategoryName = (categoryId) => {
  const category = categories.value.find((c) => c.id === categoryId);
  return category ? category.name : "Uncategorized";
};

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

// Layout options
const layouts = ref([
  { id: "grid", name: "Grid View" },
  { id: "list", name: "List View" },
]);
const currentLayout = ref("grid");

// Breaking news ticker
const breakingNews = ref([
  "Global Summit on Climate Change Reaches Historic Agreement",
  "New Technology Breakthrough Could Revolutionize Renewable Energy",
  "Major Economic Reform Bill Passes in Senate",
  "Scientists Discover Potential Cure for Rare Disease",
]);
const currentTickerIndex = ref(0);

const startTicker = () => {
  setInterval(() => {
    currentTickerIndex.value =
      (currentTickerIndex.value + 1) % breakingNews.value.length;
  }, 5000);
};

// Current date
const currentDate = computed(() => {
  return new Date().toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
});

// Weather data (simulated)
const weather = reactive({
  temp: 24,
  condition: "Partly Cloudy",
  icon: "cloud",
});

// Trending News Carousel
const trendingArticles = computed(() => {
  // Sort articles by number of comments (as a proxy for popularity)
  return [...articles.value]
    .sort((a, b) => b.comments.length - a.comments.length)
    .slice(0, 8); // Take top 8 trending articles
});

const trendingIndex = ref(0);
const trendingPerPage = computed(() => {
  if (window.innerWidth < 640) return 1;
  if (window.innerWidth < 768) return 2;
  if (window.innerWidth < 1024) return 3;
  return 4;
});

const nextTrending = () => {
  const maxIndex =
    Math.ceil(trendingArticles.value.length / trendingPerPage.value) - 1;
  trendingIndex.value =
    trendingIndex.value >= maxIndex ? 0 : trendingIndex.value + 1;
};

const prevTrending = () => {
  const maxIndex =
    Math.ceil(trendingArticles.value.length / trendingPerPage.value) - 1;
  trendingIndex.value =
    trendingIndex.value <= 0 ? maxIndex : trendingIndex.value - 1;
};

// Articles data
const articles = ref([
  {
    id: 1,
    title: "New Technology Breakthrough Could Revolutionize Renewable Energy",
    summary:
      "Scientists have developed a new method to harness solar energy with unprecedented efficiency, potentially making renewable energy more accessible worldwide.",
    content: `<p class="mb-4">Scientists at the National Renewable Energy Laboratory have announced a breakthrough in solar cell technology that could dramatically increase efficiency while reducing costs.</p>
                  <p class="mb-4">The new technology, which uses a novel arrangement of materials to capture a broader spectrum of sunlight, has achieved a record-breaking 39% efficiency in laboratory tests. This represents a significant improvement over current commercial solar panels, which typically operate at 15-20% efficiency.</p>
                  <p class="mb-4">"This is a game-changer for renewable energy," said Dr. Sarah Chen, lead researcher on the project. "With this level of efficiency, solar power becomes not just competitive with fossil fuels, but potentially more economical in many regions."</p>
                  <p class="mb-4">Industry analysts predict that if the technology can be successfully commercialized, it could accelerate the global transition to renewable energy sources and help combat climate change.</p>
                  <p class="mb-4">The breakthrough involves a new type of "tandem" solar cell that stacks multiple layers of light-absorbing materials. Each layer is designed to capture a different part of the solar spectrum, allowing the cell to harvest more energy from the same amount of sunlight.</p>
                  <p class="mb-4">What makes this development particularly promising is that the materials used are abundant and relatively inexpensive, addressing one of the key challenges in scaling up renewable energy technologies.</p>
                  <p class="mb-4">"We've been working on this for nearly a decade," Dr. Chen explained. "The real innovation came when we developed a new manufacturing process that allows these complex cells to be produced at scale without significantly increasing costs."</p>
                  <p class="mb-4">The research team is now working with industry partners to scale up production and expects the first commercial products to be available within three years.</p>
                  <p class="mb-4">Environmental groups have hailed the announcement as a potential turning point in the fight against climate change. "This kind of technological leap is exactly what we need to accelerate the transition away from fossil fuels," said James Rivera, director of the Climate Action Coalition.</p>
                  <p class="mb-4">The breakthrough comes at a critical time, as countries around the world are seeking to reduce carbon emissions and meet ambitious climate targets. If successfully deployed at scale, this technology could help nations achieve their renewable energy goals while potentially reducing electricity costs for consumers.</p>`,
    image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
    date: "May 15, 2023",
    readTime: 5,
    author: "John Doe",
    authorTitle: "Science Correspondent",
    authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
    categoryId: "technology",
    tags: ["renewable energy", "solar power", "climate change", "technology"],
    comments: [
      {
        name: "Alex Johnson",
        text: "This is incredible news! I wonder how long until we see this technology in commercial applications.",
        date: "May 15, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
      {
        name: "Maria Garcia",
        text: "I'm skeptical about the timeline for commercialization. These breakthroughs often take decades to reach the market.",
        date: "May 16, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
    ],
  },
  {
    id: 2,
    title: "Global Summit on Climate Change Reaches Historic Agreement",
    summary:
      "World leaders have committed to ambitious new targets for reducing carbon emissions by 2030, marking a significant step forward in international climate cooperation.",
    content: `<p class="mb-4">In a landmark decision, representatives from 195 countries have agreed to a new framework for tackling climate change at the Global Climate Summit in Geneva.</p>
                  <p class="mb-4">The agreement, which builds on the Paris Climate Accord, sets more ambitious targets for reducing greenhouse gas emissions and provides financial mechanisms to support developing nations in their transition to cleaner energy sources.</p>
                  <p class="mb-4">"This represents a turning point in our collective effort to address the climate crisis," said UN Secretary-General António Guterres. "For the first time, we have concrete commitments from all major economies that align with what the science tells us is necessary."</p>
                  <p class="mb-4">Key provisions of the agreement include:</p>
                  <ul class="list-disc pl-5 mb-4">
                    <li class="mb-2">A 50% reduction in global carbon emissions by 2030 compared to 2005 levels</li>
                    <li class="mb-2">Establishment of a $100 billion annual fund to help vulnerable nations adapt to climate impacts</li>
                    <li class="mb-2">Phasing out of coal power in developed nations by 2030 and globally by 2040</li>
                    <li class="mb-2">Commitment to protect 30% of land and ocean ecosystems by 2030</li>
                  </ul>
                  <p class="mb-4">The agreement came after intense negotiations that extended nearly 48 hours beyond the scheduled conclusion of the summit. Several key sticking points had threatened to derail the talks, including disagreements over financing mechanisms and the timeline for emissions reductions.</p>
                  <p class="mb-4">Climate activists have cautiously welcomed the agreement while emphasizing the need for immediate action. "These commitments are a step in the right direction, but the real test will be implementation," said Greta Thunberg, who led protests outside the summit. "We need to see concrete policies and actions, not just promises."</p>
                  <p class="mb-4">The agreement is legally binding, with provisions for regular reporting and verification of progress. Countries that fail to meet their commitments could face trade penalties and exclusion from certain international financial mechanisms.</p>
                  <p class="mb-4">Market reaction to the announcement has been positive, with renewable energy stocks surging and fossil fuel companies seeing modest declines. Analysts suggest this reflects growing investor confidence in the global energy transition.</p>
                  <p class="mb-4">The next steps will involve each country developing detailed implementation plans, which must be submitted to the UN within six months. A follow-up summit is scheduled for next year to assess progress and address any challenges in implementation.</p>`,
    image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
    date: "June 2, 2023",
    readTime: 6,
    author: "Emma Wilson",
    authorTitle: "Political Correspondent",
    authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
    categoryId: "world",
    tags: [
      "climate change",
      "global summit",
      "carbon emissions",
      "international relations",
    ],
    comments: [
      {
        name: "Thomas Lee",
        text: "It's about time! Now we need to make sure countries actually follow through on these commitments.",
        date: "June 2, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
      {
        name: "Sarah Johnson",
        text: "I'm concerned about the enforcement mechanisms. Without real consequences, these agreements don't mean much.",
        date: "June 3, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
      {
        name: "Michael Chen",
        text: "This is a significant step forward. The inclusion of financial support for developing nations is particularly important.",
        date: "June 3, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
    ],
  },
  {
    id: 3,
    title: "Artificial Intelligence Makes Breakthrough in Medical Diagnostics",
    summary:
      "A new AI system can detect early signs of cancer with greater accuracy than human doctors, potentially revolutionizing early disease detection.",
    content: `<p class="mb-4">Researchers at Stanford Medical Center have developed an artificial intelligence system that can detect early signs of several types of cancer with significantly higher accuracy than experienced oncologists.</p>
                  <p class="mb-4">The system, named MediScan, was trained on millions of medical images and can identify subtle patterns that might be missed by human observers. In clinical trials, it demonstrated a 94% accuracy rate in detecting early-stage pancreatic cancer, compared to 65% for specialist physicians.</p>
                  <p class="mb-4">"Early detection is crucial for successful treatment of many cancers," explained Dr. Robert Kim, who led the research team. "MediScan could potentially save thousands of lives by identifying cancers at a stage when they're much more treatable."</p>
                  <p class="mb-4">The technology is now undergoing FDA review and could be deployed in hospitals within the next two years.</p>`,
    image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
    date: "June 10, 2023",
    readTime: 4,
    author: "David Chen",
    authorTitle: "Health & Science Editor",
    authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
    categoryId: "health",
    tags: [
      "artificial intelligence",
      "healthcare",
      "cancer research",
      "medical technology",
    ],
    comments: [],
  },
  {
    id: 4,
    title: "Major Economic Reform Bill Passes in Senate",
    summary:
      "After months of negotiation, the Senate has passed a comprehensive economic reform package aimed at reducing inflation and boosting growth.",
    content: `<p class="mb-4">The U.S. Senate has passed a sweeping economic reform bill that aims to address inflation, create jobs, and strengthen the middle class. The legislation, which passed with bipartisan support, now moves to the House of Representatives.</p>
                  <p class="mb-4">Key provisions of the bill include tax incentives for businesses that create domestic manufacturing jobs, expanded child tax credits for families, and measures to reduce prescription drug prices.</p>
                  <p class="mb-4">"This represents the most significant economic legislation in a generation," said Senate Majority Leader in a press conference following the vote. "We're taking concrete steps to build an economy that works for everyone, not just those at the top."</p>
                  <p class="mb-4">Economists have generally responded positively to the package, with many predicting it could help reduce inflation while stimulating economic growth. However, some have expressed concerns about its impact on the national debt.</p>`,
    image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
    date: "June 15, 2023",
    readTime: 7,
    author: "Jennifer Adams",
    authorTitle: "Economics Correspondent",
    authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
    categoryId: "politics",
    tags: ["economics", "legislation", "inflation", "politics"],
    comments: [
      {
        name: "Robert Johnson",
        text: "It's about time we saw some real action on economic reform. The expanded child tax credit will make a huge difference for families.",
        date: "June 15, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
    ],
  },
  {
    id: 5,
    title: "Tech Giant Unveils Revolutionary New Smartphone",
    summary:
      "The latest flagship device features groundbreaking battery technology and advanced AI capabilities that could set new industry standards.",
    content: `<p class="mb-4">Tech industry leader Quantum Technologies has unveiled its latest flagship smartphone, the Quantum X, featuring several innovations that could reshape the mobile device market.</p>
                  <p class="mb-4">The most notable advancement is the phone's new solid-state battery technology, which the company claims can fully charge in just 10 minutes and last up to 72 hours on normal usage. If these claims hold up in real-world testing, it would represent a major leap forward in addressing one of the most common consumer complaints about smartphones.</p>
                  <p class="mb-4">"We've been working on this technology for over five years," said Quantum's CEO during the launch event. "This isn't just an incremental improvement—it's a fundamental rethinking of how we power mobile devices."</p>
                  <p class="mb-4">The Quantum X also features an advanced AI system that runs entirely on-device, rather than relying on cloud processing. This approach offers both improved privacy and faster performance for AI-driven features like photography, translation, and voice assistance.</p>`,
    image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
    date: "June 20, 2023",
    readTime: 5,
    author: "Michael Zhang",
    authorTitle: "Technology Reporter",
    authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
    categoryId: "technology",
    tags: [
      "technology",
      "smartphones",
      "battery technology",
      "artificial intelligence",
    ],
    comments: [
      {
        name: "Lisa Chen",
        text: "I'm most excited about the battery technology. If it lives up to the hype, this could be a game-changer.",
        date: "June 20, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
      {
        name: "James Wilson",
        text: "The on-device AI processing is a huge step forward for privacy. I'm glad to see companies finally taking this seriously.",
        date: "June 21, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
    ],
  },
  {
    id: 6,
    title: "Historic Sports Upset Shocks Fans Worldwide",
    summary:
      "Underdog team defeats reigning champions in what analysts are calling one of the biggest upsets in sports history.",
    content: `<p class="mb-4">In a stunning turn of events that has shocked the sports world, underdog team FC United has defeated the heavily favored Atletico Stars in the Champions Cup final.</p>
                  <p class="mb-4">FC United, ranked 15th in the league and given less than a 5% chance of winning by oddsmakers, managed to secure a 2-1 victory with a dramatic goal in the final minutes of extra time.</p>
                  <p class="mb-4">"This is what sports is all about," said FC United's captain after the match. "We believed in ourselves even when no one else did. This victory is for all the underdogs out there."</p>
                  <p class="mb-4">The upset has already been compared to some of the greatest in sports history, with social media exploding with reactions from fans and celebrities alike.</p>
                  <p class="mb-4">Atletico Stars, who had dominated the season with an almost perfect record, were visibly stunned by the defeat. "We didn't underestimate them, but sometimes in football, the best team doesn't win," said their manager in the post-match press conference.</p>`,
    image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
    date: "June 25, 2023",
    readTime: 4,
    author: "Carlos Rodriguez",
    authorTitle: "Sports Editor",
    authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
    categoryId: "sports",
    tags: ["sports", "football", "champions cup", "upsets"],
    comments: [
      {
        name: "Diego Fernandez",
        text: "I was there! The atmosphere was electric when that final goal went in. A moment I'll never forget.",
        date: "June 25, 2023",
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      },
    ],
  },
]);

// Latest article (most recent by date)
const latestArticle = computed(() => {
  return [...articles.value].sort((a, b) => {
    return new Date(b.date) - new Date(a.date);
  })[0];
});

// Filter articles based on active category and exclude latest article
const filteredArticles = computed(() => {
  let filtered = articles.value.filter(
    (article) => article.id !== latestArticle.value.id
  );

  if (activeCategory.value === "all") {
    return filtered;
  } else {
    return filtered.filter(
      (article) => article.categoryId === activeCategory.value
    );
  }
});

// Related articles (for article detail view)
const relatedArticles = computed(() => {
  if (!selectedArticle.value) return [];

  return articles.value
    .filter(
      (article) =>
        article.id !== selectedArticle.value.id &&
        article.categoryId === selectedArticle.value.categoryId
    )
    .slice(0, 3);
});

// Article view state
const selectedArticle = ref(null);

const selectArticle = (article) => {
  selectedArticle.value = article;
  window.scrollTo(0, 0);
  // Clear search when selecting an article
  searchQuery.value = "";
  searchResults.value = [];
};

const readArticle = (article) => {
  selectArticle(article);
};

// Load more articles (simulated)
const loadMoreArticles = () => {
  // In a real app, this would fetch more articles from an API
  alert(
    "In a real application, this would load more articles from the server."
  );
};

// New comment form data
const newComment = reactive({
  text: "",
});

// Function to add a new comment
const addComment = () => {
  if (newComment.text) {
    selectedArticle.value.comments.unshift({
      name: "Guest User",
      text: newComment.text,
      date: new Date().toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      }),
      userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
    });

    // Reset form
    newComment.text = "";
  }
};

// Initialize on mount
onMounted(() => {
  // Start breaking news ticker
  startTicker();

  // Set up window resize listener for responsive carousel
  window.addEventListener("resize", () => {
    // Reset carousel index when screen size changes to avoid empty slides
    trendingIndex.value = 0;
  });
});
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
</style>
