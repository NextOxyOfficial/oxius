<template>
  <div
    id="sale-category"
    class="for-sale-section py-4 bg-white rounded-lg mt-3"
  >
    <div class="container mx-auto px-1">
      <!-- Updated section header with linked buttons -->
      <div class="relative mb-4 sm:mb-6">
        <!-- Enhanced Background with Gradient and Dotted Effects -->
        <div class="relative">
          <!-- Background gradient layers -->
          <div
            class="absolute inset-0 bg-gradient-to-br from-emerald-50 via-green-50 to-teal-50 dark:from-emerald-900/20 dark:via-green-900/20 dark:to-teal-900/20 rounded-2xl sm:rounded-3xl"
          ></div>
          <div
            class="absolute inset-0 bg-gradient-to-tr from-blue-50/50 via-transparent to-purple-50/50 dark:from-blue-900/10 dark:via-transparent dark:to-purple-900/10 rounded-2xl sm:rounded-3xl"
          ></div>

          <!-- Dotted gradient patterns -->
          <div
            class="absolute inset-0 opacity-60 dark:opacity-40 rounded-2xl sm:rounded-3xl overflow-hidden"
          >
            <!-- Large dotted pattern -->
            <div
              class="absolute inset-0 bg-[radial-gradient(circle_at_1px_1px,rgba(34,197,94,0.15)_1px,transparent_0)] bg-[size:24px_24px] dark:bg-[radial-gradient(circle_at_1px_1px,rgba(134,239,172,0.1)_1px,transparent_0)]"
            ></div>
            <!-- Medium dotted pattern -->
            <div
              class="absolute inset-0 bg-[radial-gradient(circle_at_1px_1px,rgba(59,130,246,0.1)_1px,transparent_0)] bg-[size:16px_16px] dark:bg-[radial-gradient(circle_at_1px_1px,rgba(147,197,253,0.08)_1px,transparent_0)]"
            ></div>
            <!-- Small dotted pattern -->
            <div
              class="absolute inset-0 bg-[radial-gradient(circle_at_1px_1px,rgba(168,85,247,0.08)_1px,transparent_0)] bg-[size:8px_8px] dark:bg-[radial-gradient(circle_at_1px_1px,rgba(196,181,253,0.06)_1px,transparent_0)]"
            ></div>
          </div>
          <!-- Animated gradient overlay -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent dark:via-white/10 animate-pulse rounded-2xl sm:rounded-3xl"
          ></div>
          <!-- Main content container -->
          <div
            class="relative px-4 sm:p-6 rounded-2xl sm:rounded-3xl bg-white/80 dark:bg-slate-900/80 backdrop-blur-md overflow-hidden"
          >
            <!-- Dynamic Background Pattern -->
            <div class="absolute inset-0 opacity-40 dark:opacity-20">
              <!-- Subtle grid pattern -->
              <div
                class="absolute inset-0 bg-[linear-gradient(90deg,rgba(0,0,0,0.02)_1px,transparent_1px)] bg-[size:20px_20px] dark:bg-[linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)]"
              ></div>
              <div
                class="absolute inset-0 bg-[linear-gradient(0deg,rgba(0,0,0,0.02)_1px,transparent_1px)] bg-[size:20px_20px] dark:bg-[linear-gradient(0deg,rgba(255,255,255,0.03)_1px,transparent_1px)]"
              ></div>

              <!-- Floating elements for visual interest -->
              <div
                class="absolute top-2 right-4 w-2 h-2 rounded-full bg-emerald-400/20 animate-pulse"
              ></div>
              <div
                class="absolute bottom-3 left-6 w-1 h-1 rounded-full bg-blue-400/30 animate-ping"
              ></div>
              <div
                class="absolute top-1/2 right-1/4 w-1.5 h-1.5 rounded-full bg-green-400/20"
              ></div>
            </div>

            <!-- Header Content -->
            <div
              class="section-header max-sm:flex max-sm:flex-col max-sm:gap-4 sm:mb-0 mb-0 flex justify-between items-center relative z-10"
            >
              <div class="flex items-center gap-4">
                <!-- App-style Icon -->
                <div class="relative">
                  <!-- Icon background with modern design -->
                  <div
                    class="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center"
                  >
                    <Icon
                      name="heroicons:tag"
                      class="w-5 h-5 sm:w-6 sm:h-6 text-white"
                    />
                    <!-- Subtle shine effect -->
                    <div
                      class="absolute inset-0 rounded-2xl bg-gradient-to-br from-white/20 to-transparent"
                    ></div>
                  </div>
                  <!-- Active indicator dot -->
                  <div
                    class="absolute -top-1 -right-1 w-3 h-3 bg-green-400 rounded-full border-2 border-white dark:border-slate-800 animate-pulse"
                  ></div>
                </div>

                <!-- Title with enhanced styling -->
                <div class="flex-1 min-w-0">
                  <h2
                    class="text-lg sm:text-xl font-medium text-slate-900 dark:text-white truncate"
                  >
                    {{ $t("sale_listing") }}
                  </h2>
                  <p
                    class="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium"
                  >
                    Buy & sell amazing products
                  </p>
                </div>
              </div>
              <!-- Always show buttons, handle auth at page level -->
              <div class="flex gap-2 sm:gap-3">
                <!-- Marketplace Button - Enhanced (Outlined) -->
                <NuxtLink
                  to="/sale"
                  class="flex-shrink-0 group relative inline-flex items-center gap-1.5 px-3 py-2 sm:px-4 sm:py-2.5 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-medium text-xs sm:text-sm hover:bg-slate-50 dark:hover:bg-slate-700 transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98] overflow-hidden"
                  @click="handleButtonClick('marketplace')"
                >
                  <!-- Button hover effect -->
                  <div
                    class="absolute inset-0 bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-700 dark:to-slate-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  ></div>
                  <div
                    v-if="loadingButtons.has('marketplace')"
                    class="dotted-spinner slate mr-1"
                  ></div>
                  <Icon
                    v-else
                    name="heroicons:shopping-bag"
                    class="w-3 h-3 sm:w-4 sm:h-4 relative z-10 flex-shrink-0"
                  />
                  <span
                    v-if="!loadingButtons.has('marketplace')"
                    class="relative z-10 truncate"
                    >{{ $t("marketplace") }}</span
                  >
                </NuxtLink>
                <!-- My Posts Button - Enhanced (Navigate to page) - Only show for logged in users -->
                <NuxtLink
                  v-if="user?.user"
                  to="/sale/my-posts"
                  class="flex-shrink-0 group relative inline-flex items-center gap-1.5 px-3 py-2 sm:px-4 sm:py-2.5 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-medium text-xs sm:text-sm hover:bg-slate-50 dark:hover:bg-slate-700 transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98] overflow-hidden"
                  @click="handleButtonClick('my-posts')"
                >
                  <!-- Button hover effect -->
                  <div
                    class="absolute inset-0 bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-700 dark:to-slate-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  ></div>

                  <div
                    v-if="loadingButtons.has('my-posts')"
                    class="dotted-spinner slate mr-1"
                  ></div>
                  <Icon
                    v-else
                    name="heroicons:document-text"
                    class="w-3 h-3 sm:w-4 sm:h-4 relative z-10 flex-shrink-0"
                  />
                  <span
                    v-if="!loadingButtons.has('my-posts')"
                    class="relative z-10 truncate"
                    >{{ $t("my_post") }}</span
                  >
                </NuxtLink>
                <!-- Post Sale Button - Enhanced (Outlined) - Always visible -->
                <NuxtLink
                  to="/sale/my-posts?tab=post-sale"
                  class="flex-shrink-0 group relative inline-flex items-center gap-1.5 px-3 py-2 sm:px-4 sm:py-2.5 rounded-xl bg-white dark:bg-slate-800 border border-emerald-200 dark:border-emerald-700 text-emerald-700 dark:text-emerald-300 font-medium text-xs sm:text-sm hover:bg-emerald-50 dark:hover:bg-emerald-900/20 transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98] overflow-hidden"
                  @click="handleButtonClick('post-a-sale')"
                >
                  <!-- Button hover effect -->
                  <div
                    class="absolute inset-0 bg-gradient-to-r from-emerald-50 to-emerald-100 dark:from-emerald-900/20 dark:to-emerald-800/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  ></div>

                  <div
                    v-if="loadingButtons.has('post-a-sale')"
                    class="dotted-spinner emerald mr-1"
                  ></div>
                  <Icon
                    v-else
                    name="heroicons:plus-circle"
                    class="w-3 h-3 sm:w-4 sm:h-4 relative z-10 flex-shrink-0"
                  />
                  <span
                    v-if="!loadingButtons.has('post-a-sale')"
                    class="relative z-10 truncate"
                    >{{ $t("post_a_sale") }}</span
                  >
                </NuxtLink>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Dynamic banner ads with responsive layout -->
      <div class="banner-container mb-4 sm:mb-8">
        <div class="flex flex-col md:flex-row gap-2">
          <!-- Show loading placeholder when banners are loading -->
          <template v-if="isLoadingBanners && !bannersFetched">
            <div class="main-banner rounded-lg overflow-hidden md:w-1/2">
              <div
                class="w-full h-16 sm:h-20 md:h-32 bg-gray-200 animate-pulse"
              ></div>
            </div>
            <div class="secondary-banner rounded-lg overflow-hidden md:w-1/2">
              <div
                class="w-full h-16 sm:h-20 md:h-32 bg-gray-200 animate-pulse"
              ></div>
            </div>
          </template>

          <!-- Display banners when loaded -->
          <template v-else>
            <!-- Main banner -->
            <div
              v-if="banners.length > 0"
              class="main-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <NuxtLink
                :to="
                  `/sale/?category=${banners[0]?.category_details?.id}` || '#'
                "
                class="block"
              >
                <img
                  :src="getImageUrl(banners[0]?.image)"
                  :alt="banners[0]?.title || 'Promotion'"
                  class="w-full h-24 sm:h-20 md:h-32 object-contain"
                />
              </NuxtLink>
            </div>

            <!-- Secondary banner -->
            <div
              v-if="banners.length > 1"
              class="secondary-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <NuxtLink
                :to="
                  `/sale/?category=${banners[1]?.category_details?.id}` || '#'
                "
                class="block"
              >
                <img
                  :src="getImageUrl(banners[1]?.image)"
                  :alt="banners[1]?.title || 'Offer'"
                  class="w-full h-24 sm:h-20 md:h-32 object-contain"
                />
              </NuxtLink>
            </div>

            <!-- Fallback banners if API returns empty data -->
            <div
              v-if="banners.length === 0"
              class="main-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <img
                src="https://via.placeholder.com/1200x80/3B82F6/FFFFFF?text=Special+Promotion"
                alt="Promotion"
                class="w-full h-16 sm:h-20 md:h-32 object-cover"
              />
            </div>

            <div
              v-if="banners.length <= 1"
              class="secondary-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <img
                src="https://via.placeholder.com/1200x80/4F46E5/FFFFFF?text=Limited+Time+Offer"
                alt="Offer"
                class="w-full h-16 sm:h-20 md:h-32 object-cover"
              />
            </div>
          </template>
        </div>
      </div>
      <div class="category-tabs relative mb-6">
        <!-- Categories slider with touch events -->
        <div
          class="overflow-hidden overflow-x-auto scroll-smooth"
          ref="sliderContainer"
          @scroll="handleScroll"
          style="scrollbar-width: none; -ms-overflow-style: none"
        >
          <div class="categories-wrapper flex mt-3" ref="categoriesWrapper">
            <!-- Show category loading placeholders when categories are loading -->
            <template v-if="isLoadingCategories && !categoriesFetched">
              <div
                v-for="index in 6"
                :key="`placeholder-${index}`"
                class="category-item flex-shrink-0"
                :class="[isMobile ? 'w-1/4' : 'w-1/6']"
              >
                <div
                  class="category-card transition-all duration-200 cursor-pointer h-full mx-1"
                >
                  <div class="flex items-center justify-center h-full">
                    <div class="text-center py-2">
                      <div
                        class="icon-container mx-auto mb-1 flex items-center justify-center bg-gray-200 rounded-full animate-pulse"
                      >
                        <div class="h-8 w-8"></div>
                      </div>
                      <div
                        class="h-4 bg-gray-200 rounded w-16 mx-auto animate-pulse"
                      ></div>
                    </div>
                  </div>
                </div>
              </div>
            </template>

            <!-- Show loaded categories -->
            <template v-else-if="categories.length > 0">
              <div
                v-for="category in categories"
                :key="category.id"
                class="category-item flex-shrink-0"
                :class="[isMobile ? 'w-1/4' : 'w-1/6']"
                @click="selectCategory(category)"
              >
                <div
                  class="category-card transition-all duration-200 cursor-pointer h-full mx-1"
                  :class="{
                    'category-active': selectedCategory === category.id,
                    'category-inactive': selectedCategory !== category.id,
                  }"
                >
                  <div class="flex items-center justify-center h-full">
                    <div class="text-center py-2">
                      <div
                        class="icon-container mx-auto mb-1 flex items-center justify-center"
                      >
                        <img
                          v-if="category.icon"
                          :src="getImageUrl(category.icon)"
                          :alt="category.name"
                          class="size-8 object-cover"
                        />
                        <Icon
                          v-else
                          :name="getCategoryIcon(category.name)"
                          size="22px"
                        />
                      </div>
                      <span class="category-name font-medium text-sm">{{
                        category.name
                      }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>

      <!-- Display section for selected category items with lazy loading -->
      <div class="selected-category-items mt-4" v-if="selectedCategory">
        <div class="flex justify-between items-center my-6 px-2 sm:px-6">
          <div>
            <h3 class="text-lg font-semibold">
              {{ getSelectedCategoryName() }}
            </h3>
          </div>
          <NuxtLink
            :to="`/sale`"
            class="my-post-btn hover:bg-gray-50 rounded-md px-2 py-1 sm:px-3 sm:py-1.5 text-emerald-600 text-sm sm:text-sm flex items-center"
            @click="handleButtonClick('view-all-sale')"
          >
            <div
              v-if="loadingButtons.has('view-all-sale')"
              class="dotted-spinner emerald mr-1"
            ></div>
            <span v-else>{{ $t("view_all") }}</span>
            <svg
              v-if="!loadingButtons.has('view-all-eshop')"
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="ml-1"
            >
              <path d="m9 18 6-6-6-6" />
            </svg>
          </NuxtLink>
        </div>

        <!-- Lazy loading skeleton when loading -->
        <div v-if="isLoading" class="grid grid-cols-2 md:grid-cols-5 gap-2">
          <div
            v-for="i in isMobile ? 4 : 5"
            :key="i"
            class="item-card bg-white rounded-lg overflow-hidden border border-gray-100 animate-pulse"
          >
            <div class="h-32 bg-gray-200"></div>
            <div class="p-3">
              <div class="h-4 bg-gray-200 rounded mb-2"></div>
              <div class="h-3 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div class="flex justify-between items-center">
                <div class="h-5 bg-gray-200 rounded-full w-1/4"></div>
                <div class="h-6 w-6 rounded-full bg-gray-200"></div>
              </div>
            </div>
          </div>
        </div>
        <!-- Display actual posts from the database -->
        <div v-else-if="categoryPosts.length > 0">
          <!-- Mobile: Horizontal scrollable row showing 5 random posts -->
          <div class="block md:hidden">
            <div
              class="flex gap-3 overflow-x-auto pb-4"
              style="scrollbar-width: none; -ms-overflow-style: none"
              ref="mobilePostsContainer"
            >
              <NuxtLink
                v-for="post in randomMobilePosts"
                :key="post.id"
                :to="`/sale/${post.slug}`"
                class="item-card bg-white rounded-lg transition-all overflow-hidden border border-gray-100 flex flex-col h-full transform flex-shrink-0"
                style="width: 45vw; min-width: 160px"
              >
                <div class="relative">
                  <!-- Price overlay in top right -->
                  <div class="absolute top-0 right-0 m-2 z-10">
                    <div
                      class="px-2 py-1 bg-primary text-white text-xs font-semibold rounded"
                    >
                      ৳{{
                        post.price ? post.price.toLocaleString() : "Negotiable"
                      }}
                    </div>
                  </div>

                  <!-- Status badges in top left -->
                  <div class="absolute top-0 left-0 m-2 z-10">
                    <span
                      v-if="post.featured"
                      class="bg-yellow-500 text-white text-xs px-2 py-0.5 rounded"
                      >Featured</span
                    >
                    <span
                      v-else-if="post.status === 'sold'"
                      class="bg-blue-500 text-white text-xs px-2 py-0.5 rounded"
                      >Sold</span
                    >
                  </div>

                  <!-- Image with gradient overlay -->
                  <div class="h-32 overflow-hidden relative">
                    <div
                      class="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent z-0"
                    ></div>
                    <img
                      :src="post.main_image"
                      :alt="post.title"
                      class="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
                      loading="lazy"
                    />
                  </div>
                </div>

                <div class="p-2 flex-grow flex flex-col">
                  <!-- Title with truncation -->
                  <h4 class="font-medium text-gray-800 line-clamp-1 text-xs">
                    {{ capitalizeTitle(post.title) }}
                  </h4>
                  <!-- Address with location icon -->
                  <div class="flex items-start mt-1 mb-2 text-xs text-gray-600">
                    <Icon
                      name="heroicons:map-pin"
                      class="h-3 w-3 mr-1 mt-0.5 flex-shrink-0 text-gray-600"
                    />
                    <span class="line-clamp-1">
                      {{
                        post?.division && post?.district && post?.area
                          ? `${post?.division}, ${post?.district}, ${post?.area}`
                          : `All Over Bangladesh`
                      }}
                    </span>
                  </div>

                  <div class="mt-auto flex justify-between items-center pt-1">
                    <!-- Condition tag -->
                    <div
                      class="text-xs text-gray-600 bg-gray-100 px-1.5 py-0.5 rounded-full"
                    >
                      {{ post.condition }}
                    </div>

                    <!-- Date or other secondary info -->
                    <div class="text-xs text-gray-600 flex items-center">
                      <Icon
                        name="heroicons:clock"
                        class="h-3 w-3 mr-1 text-gray-600"
                      />
                      {{ formatDate(post.created_at) }}
                    </div>
                  </div>
                </div>
              </NuxtLink>
            </div>
          </div>
          <!-- Desktop: Grid layout -->
          <div class="hidden md:block">
            <div class="grid grid-cols-5 gap-2">
              <NuxtLink
                v-for="post in categoryPosts"
                :key="post.id"
                :to="`/sale/${post.slug}`"
                class="item-card bg-white rounded-lg transition-all overflow-hidden border border-gray-100 flex flex-col h-full transform"
              >
                <div class="relative">
                  <!-- Price overlay in top right -->
                  <div class="absolute top-0 right-0 m-2 z-10">
                    <div
                      class="px-2 py-1 bg-primary text-white text-sm font-semibold rounded"
                    >
                      ৳{{
                        post.price ? post.price.toLocaleString() : "Negotiable"
                      }}
                    </div>
                  </div>

                  <!-- Status badges in top left -->
                  <div class="absolute top-0 left-0 m-2 z-10">
                    <span
                      v-if="post.featured"
                      class="bg-yellow-500 text-white text-xs px-2 py-0.5 rounded"
                      >Featured</span
                    >
                    <span
                      v-else-if="post.status === 'sold'"
                      class="bg-blue-500 text-white text-xs px-2 py-0.5 rounded"
                      >Sold</span
                    >
                  </div>

                  <!-- Image with gradient overlay -->
                  <div class="h-36 overflow-hidden relative">
                    <div
                      class="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent z-0"
                    ></div>
                    <img
                      :src="post.main_image"
                      :alt="post.title"
                      class="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
                      loading="lazy"
                    />
                  </div>
                </div>

                <div class="p-3 flex-grow flex flex-col">
                  <!-- Title with truncation -->
                  <h4 class="font-medium text-gray-800 line-clamp-1 text-sm">
                    {{ capitalizeTitle(post.title) }}
                  </h4>
                  <!-- Address with location icon -->
                  <div class="flex items-start mt-1 mb-2 text-xs text-gray-600">
                    <Icon
                      name="heroicons:map-pin"
                      class="h-3 w-3 mr-1 mt-0.5 flex-shrink-0 text-gray-600"
                    />
                    {{
                      post?.division && post?.district && post?.area
                        ? `${post?.division}, ${post?.district}, ${post?.area}`
                        : `All Over Bangladesh`
                    }}
                  </div>

                  <div class="mt-auto flex justify-between items-center pt-1">
                    <!-- Condition tag -->
                    <div
                      class="text-xs text-gray-600 bg-gray-100 px-2 py-0.5 rounded-full"
                    >
                      {{ post.condition }}
                    </div>

                    <!-- Date or other secondary info -->
                    <div class="text-xs text-gray-600 flex items-center">
                      <Icon
                        name="heroicons:clock"
                        class="h-3 w-3 mr-1 text-gray-600"
                      />
                      {{ formatDate(post.created_at) }}
                    </div>
                  </div>
                </div>
              </NuxtLink>
            </div>
          </div>
        </div>

        <!-- No posts found message -->
        <div
          v-else
          class="flex flex-col items-center justify-center py-8 px-4 bg-gray-50 rounded-lg"
        >
          <Icon
            name="heroicons:document-magnifying-glass"
            size="40px"
            class="text-gray-600 mb-2"
          />
          <h3 class="text-base font-medium text-gray-800 mb-1">
            {{ $t("no_listings_found") }}
          </h3>
          <p class="text-gray-600 text-sm text-center">
            {{ $t("no_items_currently_listed") }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { user } = useAuth();
const { get } = useApi();

// Loading state for buttons
const loadingButtons = ref(new Set());

// Function to handle button click and show loading
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  // Remove loading state after navigation (cleanup happens in route change)
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000); // Fallback timeout
};

// Watch for route changes to clear loading states
const route = useRoute();
watch(
  () => route.path,
  () => {
    loadingButtons.value.clear();
  }
);

// State for categories and banners now from API
const categories = ref([]);
const banners = ref([]);
const selectedCategory = ref(null);
const sliderContainer = ref(null);
const categoriesWrapper = ref(null);
const isLoading = ref(false);
const isMobile = ref(false);

// Add loading states for initial data fetching
const isLoadingCategories = ref(true);
const isLoadingBanners = ref(true);

// Add flags to prevent duplicate API calls
const categoriesFetched = ref(false);
const bannersFetched = ref(false);

// Scroll state for navigation buttons
const isAtStart = ref(true);
const isAtEnd = ref(false);

// Helper function to construct full image URL
const getImageUrl = (path) => {
  if (!path) return "";
  const { staticURL } = useApi();

  // If path already starts with http(s) or //, it's a full URL
  if (path.match(/^(https?:)?\/\//)) {
    return path;
  }

  // Otherwise prepend static URL
  return `${staticURL}${path}`;
};

// Get appropriate icon for a category based on its name
const getCategoryIcon = (categoryName) => {
  const iconMap = {
    Properties: "heroicons:home-modern",
    Vehicles: "heroicons:truck",
    Electronics: "heroicons:device-phone-mobile",
    Sports: "heroicons:trophy",
    B2B: "heroicons:building-office",
    Fashion: "heroicons:shopping-bag",
    Services: "heroicons:wrench",
    Jobs: "heroicons:briefcase",
    Pets: "heroicons:heart",
    Books: "heroicons:book-open",
    Furniture: "heroicons:table",
  };

  return iconMap[categoryName] || "heroicons:squares-plus"; // Default to 'squares-plus' for unknown categories
};

// Select a category with lazy loading simulation
const selectCategory = (category) => {
  if (selectedCategory.value === category.id) return;

  isLoading.value = true;
  selectedCategory.value = category.id;

  // Simulate API request delay - in a real app, you would fetch actual items for this category
  setTimeout(() => {
    isLoading.value = false;
  }, 800);
};

// Get the name of the selected category
const getSelectedCategoryName = () => {
  const found = categories.value.find(
    (cat) => cat.id === selectedCategory.value
  );
  return found ? found.name : "";
};

// Handle scroll events to update navigation button states
const handleScroll = () => {
  if (!sliderContainer.value) return;

  const scrollLeft = sliderContainer.value.scrollLeft;
  const maxScroll =
    sliderContainer.value.scrollWidth - sliderContainer.value.clientWidth;

  isAtStart.value = scrollLeft <= 5; // Small tolerance for precision
  isAtEnd.value = scrollLeft >= maxScroll - 5; // Small tolerance for precision
};

// Touch event handlers
// Handle screen resize
const checkIfMobile = () => {
  isMobile.value = window.innerWidth < 768;

  // Update scroll states when switching between mobile and desktop
  nextTick(() => {
    handleScroll();
  });
};

// Fetch categories from the backend
const fetchCategories = async () => {
  // Prevent duplicate API calls
  if (categoriesFetched.value || categories.value.length > 0) {
    isLoadingCategories.value = false;
    return;
  }

  try {
    isLoadingCategories.value = true;

    // Update to the correct API endpoint
    const response = await get("/sale/categories/");

    if (
      response.data &&
      Array.isArray(response.data) &&
      response.data.length > 0
    ) {
      // This will place the most recently added categories at the end
      const sortedCategories = [...response.data].sort((a, b) => a.id - b.id);
      categories.value = sortedCategories;

      // Set initial category if available
      if (categories.value.length > 0) {
        selectedCategory.value = categories.value[0].id;
      }

      categoriesFetched.value = true;
    } else {
      console.warn("No categories received from API or invalid format");
      categoriesFetched.value = true; // Mark as fetched to prevent retries
    }
  } catch (error) {
    console.error("Error fetching sale categories:", error);
    categoriesFetched.value = true; // Mark as fetched to prevent infinite retries
  } finally {
    isLoadingCategories.value = false;
  }
};

// Fetch banners from the backend
const fetchBanners = async () => {
  // Prevent duplicate API calls
  if (bannersFetched.value || banners.value.length > 0) {
    isLoadingBanners.value = false;
    return;
  }

  try {
    isLoadingBanners.value = true;

    // Update to the correct API endpoint
    const response = await get("/sale/banners/");

    if (response.data && Array.isArray(response.data)) {
      banners.value = response.data;
      bannersFetched.value = true;
    } else {
      console.warn("No banners received from API or invalid format");
      bannersFetched.value = true; // Mark as fetched to prevent retries
    }
  } catch (error) {
    console.error("Error fetching sale banners:", error);
    bannersFetched.value = true; // Mark as fetched to prevent infinite retries
  } finally {
    isLoadingBanners.value = false;
  }
};

// Fetch posts for the selected category
const categoryPosts = ref([]);
const categoryPostsPage = ref(1);
const categoryPostsLimit = ref(6); // Show only 6 posts initially
const showAllCategoryPosts = ref(false);
const mobilePostsContainer = ref(null);

// Computed property to get 5 random posts for mobile display
const randomMobilePosts = computed(() => {
  if (categoryPosts.value.length === 0) return [];

  // Create a copy of the array to avoid mutating the original
  const shuffled = [...categoryPosts.value];

  // Fisher-Yates shuffle algorithm
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }

  // Return only 5 posts
  return shuffled.slice(0, 5);
});

const fetchCategoryPosts = async () => {
  if (!selectedCategory.value) return;

  try {
    isLoading.value = true;

    // Use pagination for category posts
    const limit = showAllCategoryPosts.value ? 50 : categoryPostsLimit.value;
    const response = await get(
      `/sale/posts/?category=${selectedCategory.value}&limit=${limit}`
    );

    if (response.error) {
      console.error("Error response from API:", response.error);
      categoryPosts.value = [];
      return;
    }

    // Handle different API response formats
    if (response.data) {
      if (Array.isArray(response.data)) {
        // Direct array of posts
        categoryPosts.value = response.data;
      } else if (
        response.data.results &&
        Array.isArray(response.data.results)
      ) {
        // Paginated response
        categoryPosts.value = response.data.results;
      } else if (typeof response.data === "object") {
        // Single post object (unlikely but handling just in case)
        categoryPosts.value = [response.data];
      } else {
        console.warn("Unexpected API response format:", response.data);
        categoryPosts.value = [];
      }
    } else {
      categoryPosts.value = [];
    }
  } catch (error) {
    console.error("Error fetching posts for category:", error);
    categoryPosts.value = [];
  } finally {
    isLoading.value = false;
  }
};

watch(selectedCategory, fetchCategoryPosts);

// Initialize on mount
onMounted(async () => {
  // Check if categories and banners are already loaded to prevent duplicates
  if (!categoriesFetched.value) {
    await fetchCategories();
  }

  if (!bannersFetched.value) {
    await fetchBanners();
  }
  // Check device type initially
  checkIfMobile();

  // Initialize scroll state
  nextTick(() => {
    handleScroll();
  });

  // Add resize event listener
  window.addEventListener("resize", checkIfMobile);
});

// Clean up event listeners
onUnmounted(() => {
  window.removeEventListener("resize", checkIfMobile);
});

// Helper function for formatting dates
const formatDate = (dateString) => {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString("en-US", { day: "numeric", month: "short" });
};

// Helper function for capitalizing the first letter of each word in titles
const capitalizeTitle = (title) => {
  if (!title) return "";

  return title
    .toLowerCase()
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
};
</script>

<style scoped>
.category-tabs {
  position: relative;
  width: calc(100% - 4px);
  margin: 0 auto;
}

.category-card {
  border-bottom: 2px solid transparent;
  border-radius: 0;
  background-color: white;
}

.category-active {
  border-color: #3b82f6;
  background-color: rgb(249 250 251);
}

.category-inactive:hover {
  background-color: rgb(249 250 251);
}

.icon-container {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.categories-wrapper {
  display: flex;
}

/* Hide scrollbar for webkit browsers */
.overflow-x-auto::-webkit-scrollbar {
  display: none;
}

/* Hide scrollbar for IE, Edge and Firefox */
.overflow-x-auto {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

/* Mobile posts container specific scrollbar hiding */
[ref="mobilePostsContainer"]::-webkit-scrollbar {
  display: none;
}

/* Ensure smooth scrolling on mobile */
@media (max-width: 767px) {
  .overflow-x-auto {
    scroll-behavior: smooth;
    -webkit-overflow-scrolling: touch;
  }
}

/* Line clamp utility */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Animation for loading skeleton */
@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Responsive settings */
@media (min-width: 768px) {
  /* Desktop: show all 6 categories */
  .category-item {
    width: 16.666667%; /* 1/6 */
  }
}

@media (max-width: 767px) {
  /* Mobile: show 4 categories at once */
  .category-item {
    width: 25%; /* 1/4 */
  }
}

/* Add extra small breakpoint for button labels */
@media (min-width: 480px) {
  .xs\:inline {
    display: inline;
  }
}

/* Banner styles */
.banner-container {
  width: 100%;
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.slate {
  border-color: #64748b;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
