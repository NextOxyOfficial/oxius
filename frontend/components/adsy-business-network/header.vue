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
          
          <!-- Desktop: Search icon positioned 3px left of AdsyClub button -->
          <div class="hidden sm:flex gap-2 items-center ml-auto">
            <div class="relative mr-3 search-button-container">
              <!-- Search Icon - Clickable to toggle dropdown -->
              <button 
                class="flex items-center justify-center p-2 rounded-full hover:bg-gray-100 transition-colors"
                @click="toggleSearchDropdown"
              >
                <SearchIcon class="h-5 w-5 text-gray-500" />
              </button>
              
              <!-- Search Dropdown (only visible when toggleSearchDropdown is clicked) -->
              <div 
                v-if="showSearchDropdown"
                class="absolute top-full right-0 mt-2 bg-white rounded-md shadow-lg z-50 w-72 overflow-hidden border border-gray-200 search-dropdown-container"
              >
                <!-- Search Input Area -->
                <div class="p-3 border-b border-gray-200">
                  <div class="relative">
                    <input
                      type="text"
                      placeholder="Search topics..."
                      v-model="searchQuery"
                      class="w-full pl-8 pr-8 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-100 text-gray-900 search-input"
                      ref="searchInput"
                    />
                    <SearchIcon class="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
                    <button
                      v-if="searchQuery"
                      @click="clearSearch"
                      class="absolute right-2.5 top-2.5"
                    >
                      <XIcon class="h-4 w-4 text-gray-500" />
                    </button>
                  </div>
                </div>
                
                <!-- Search Results -->
                <div v-if="searchQuery && searchResults.length > 0" class="divide-y divide-gray-100 max-h-80 overflow-y-auto">
                  <div
                    v-for="result in limitedSearchResults"
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
                
                <!-- No Results Message -->
                <div
                  v-if="searchQuery && searchResults.length === 0"
                  class="p-4 text-center text-gray-500"
                >
                  No results found for "{{ searchQuery }}"
                </div>
                
                <!-- Empty State (when dropdown is first opened) -->
                <div
                  v-if="!searchQuery"
                  class="p-4 text-center text-gray-500"
                >
                  Type to start searching...
                </div>
              </div>
            </div>
            
            <UButton to="/" class="bg-slate-700/80">AdsyClub</UButton>
            <UButton to="/adsy-news" class="bg-slate-700/80">AdsyNews</UButton>
          </div>
          
          <div v-if="!user" class="flex relative menu-container">
            <!-- Mobile: Search icon positioned 2px left of Login/Register button -->
            <div class="sm:hidden relative mr-2 search-button-container">
              <button 
                class="flex items-center justify-center p-2 rounded-full hover:bg-gray-100 transition-colors"
                @click="toggleSearchDropdown"
              >
                <SearchIcon class="h-5 w-5 text-gray-500" />
              </button>
              
              <!-- Mobile Search Dropdown with Fixed Positioning -->
              <div 
                v-if="showSearchDropdown"
                class="fixed left-0 right-0 top-16 mx-4 bg-white rounded-lg shadow-xl z-[99999] border border-gray-200 search-dropdown-container"
              >
                <!-- Search Input Area -->
                <div class="p-3 border-b border-gray-200">
                  <div class="relative">
                    <input
                      type="text"
                      placeholder="Search topics..."
                      v-model="searchQuery"
                      class="w-full pl-8 pr-8 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-100 text-gray-900 search-input"
                      ref="mobileSearchInput"
                    />
                    <SearchIcon class="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
                    <button
                      v-if="searchQuery"
                      @click="clearSearch"
                      class="absolute right-2.5 top-2.5"
                    >
                      <XIcon class="h-4 w-4 text-gray-500" />
                    </button>
                  </div>
                </div>
                
                <!-- Search Results -->
                <div v-if="searchQuery && searchResults.length > 0" class="divide-y divide-gray-100 max-h-64 overflow-y-auto">
                  <div
                    v-for="result in limitedSearchResults"
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
                
                <!-- No Results Message -->
                <div
                  v-if="searchQuery && searchResults.length === 0"
                  class="p-4 text-center text-gray-500"
                >
                  No results found for "{{ searchQuery }}"
                </div>
                
                <!-- Empty State (when dropdown is first opened) -->
                <div
                  v-if="!searchQuery"
                  class="p-4 text-center text-gray-500"
                >
                  Type to start searching...
                </div>
              </div>
            </div>
            
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
            <!-- Mobile: Search icon for logged-in users -->
            <div class="sm:hidden relative mr-2 search-button-container">
              <button 
                class="flex items-center justify-center p-2 rounded-full hover:bg-gray-100 transition-colors"
                @click="toggleSearchDropdown"
              >
                <SearchIcon class="h-5 w-5 text-gray-500" />
              </button>
              
              <!-- Mobile Search Dropdown (same as above) -->
              <div 
                v-if="showSearchDropdown"
                class="absolute top-full right-0 mt-2 bg-white rounded-md shadow-lg z-50 w-72 overflow-hidden border border-gray-200 search-dropdown-container"
              >
                <!-- Same dropdown content as above -->
                <!-- ... -->
              </div>
            </div>
            
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
</style>
