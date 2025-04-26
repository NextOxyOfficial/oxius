<template>
  <div class="fixed top-0 left-0 right-0 z-50 w-full mx-auto">
    <header class="backdrop-blur-sm bg-white/95 dark:bg-gray-900/95 shadow-sm">
      <div class="max-w-5xl mx-auto px-3 sm:px-4">
        <div class="flex items-center justify-between h-16 sm:h-18">
          <!-- Left Section: Sidebar Toggle (mobile only) + Logo -->
          <div class="flex items-center sm:gap-5">
            <!-- Sidebar Toggle Button - MOBILE ONLY -->
            <button
              @click="cart.toggleBurgerMenu()"
              class="flex sm:hidden group relative h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 transition-all"
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
          <div class="flex items-center gap-1 sm:gap-3 relative">
            <!-- Search Button with Animated Dropdown -->
            <div class="relative search-button-container">
              <button
                class="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors group"
                @click="toggleSearchDropdown"
                aria-label="Search"
              >
                <SearchIcon
                  class="h-[18px] w-[18px] text-gray-600 dark:text-gray-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
                />
              </button>

              <!-- Search Dropdown with Enhanced Animation -->
              <Transition
                enter-active-class="transition-all duration-300 ease-out"
                enter-from-class="opacity-0 scale-95 -translate-y-2"
                enter-to-class="opacity-100 scale-100 translate-y-0"
                leave-active-class="transition-all duration-200 ease-in"
                leave-from-class="opacity-100 scale-100 translate-y-0"
                leave-to-class="opacity-0 scale-95 -translate-y-2"
              >
                <div
                  v-if="showSearchDropdown"
                  class="absolute top-full right-0 mt-2 w-72 sm:w-80 bg-white dark:bg-gray-800 rounded-xl shadow-xl border border-gray-200 dark:border-gray-700 overflow-hidden z-50 search-dropdown-container"
                >
                  <!-- Search Input with Focus Animation -->
                  <div
                    class="p-3 border-b border-gray-200 dark:border-gray-700"
                  >
                    <div class="relative">
                      <input
                        type="text"
                        placeholder="Search topics..."
                        v-model="searchQuery"
                        class="w-full pl-9 pr-8 py-2.5 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-500/70 border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-200 transition-all duration-300 search-input"
                        ref="searchInput"
                      />
                      <SearchIcon
                        class="absolute left-3 top-2.5 h-4 w-4 text-gray-500 dark:text-gray-400"
                      />
                      <button
                        v-if="searchQuery"
                        @click="clearSearch"
                        class="absolute right-2.5 top-2.5 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 p-1 transition-colors"
                      >
                        <XIcon
                          class="h-3.5 w-3.5 text-gray-500 dark:text-gray-400"
                        />
                      </button>
                    </div>
                  </div>

                  <!-- Search Results with Optimized Rendering -->
                  <div
                    v-if="searchQuery && searchResults.length > 0"
                    class="divide-y divide-gray-100 dark:divide-gray-800 max-h-80 overflow-y-auto"
                  >
                    <div
                      v-for="result in limitedSearchResults"
                      :key="result.id"
                      class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer transition-colors duration-150"
                      @click="selectArticle(result)"
                    >
                      <p
                        class="text-sm font-medium text-gray-900 dark:text-gray-100"
                      >
                        {{ result.title }}
                      </p>
                      <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        <span
                          class="bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 px-2 py-0.5 rounded-full text-xs"
                        >
                          {{ getCategoryName(result.categoryId) }}
                        </span>
                      </p>
                    </div>
                  </div>

                  <!-- No Results Message -->
                  <div
                    v-if="searchQuery && searchResults.length === 0"
                    class="p-4 text-center text-gray-500 dark:text-gray-400"
                  >
                    No results found for "{{ searchQuery }}"
                  </div>

                  <!-- Empty State -->
                  <div v-if="!searchQuery" class="p-4 text-center">
                    <div class="text-gray-400 dark:text-gray-500 mb-2">
                      <SearchIcon class="h-5 w-5 mx-auto mb-2" />
                      Type to start searching...
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-500">
                      Press ESC to close
                    </div>
                  </div>
                </div>
              </Transition>
            </div>

            <!-- Navigation Buttons - DESKTOP ONLY (AdsyClub & AdsyNews) -->
            <div class="hidden sm:flex items-center gap-2">
              <!-- AdsyClub Button -->
              <NuxtLink
                to="/"
                class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all group"
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
                class="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-all group"
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
                <template #trailing>
                  <UIcon
                    name="i-heroicons-arrow-right-20-solid"
                    class="w-5 h-5"
                  />
                </template>
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
                class="text-xs px-0.5 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm"
              >
                <div class="flex items-center gap-1">
                  <UIcon
                    name="i-heroicons-shield-check"
                    class="size-4 text-white"
                  />
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
                          class="text-xs px-2 py-0.5 bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-full font-medium"
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
                          class="text-xs px-1 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm"
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
const showSearchDropdown = ref(false);
const searchQuery = ref("");
const searchResults = ref([]);

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
  Newspaper, // Added for AdsyNews
  BarChartBig, // Added for AdsyClub (closest to chart-no-axes-column)
} from "lucide-vue-next";

// Navigation state
const mobileMenuOpen = ref(false);

// Toggle search dropdown
const toggleSearchDropdown = () => {
  showSearchDropdown.value = !showSearchDropdown.value;
  if (showSearchDropdown.value) {
    nextTick(() => {
      const searchInput = document.querySelector(".search-input");
      if (searchInput) {
        searchInput.focus();
      }
    });
  }
};

// Handle clicks outside of search dropdown to close it
const handleClickOutside = (event) => {
  const searchDropdown = document.querySelector(".search-dropdown-container");
  const searchButton = document.querySelector(".search-button-container");

  if (
    searchDropdown &&
    !searchDropdown.contains(event.target) &&
    searchButton &&
    !searchButton.contains(event.target)
  ) {
    showSearchDropdown.value = false;
  }
};

// Add event listener when component is mounted
onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

// Remove event listener when component is unmounted
onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
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
