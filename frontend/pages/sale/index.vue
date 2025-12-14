<template>
  <div class="bg-gradient-to-b from-gray-50 to-gray-100/80 min-h-screen">
    <!-- Top Navigation Bar with Search and Post Button -->
    <SaleSearchBar
      :initial-search-term="form.title"
      :is-searching="isLoading"
      :show-search-results="true"
      @search="handleSearch"
      @clear-location="handleClearLocation"
    />
    <UContainer class="py-3 sm:py-4">
      <!-- Overlay for mobile -->
      <div
        v-if="isMobileFilterOpen"
        class="fixed inset-0 bg-black bg-opacity-60 z-40 lg:hidden"
        @click="toggleMobileSidebar"
      ></div>
      <div class="flex flex-col lg:flex-row gap-4">
        <!-- Sale Sidebar Component -->
        <SaleSidebar
          :is-mobile-filter-open="isMobileFilterOpen"
          :categories="categories"
          :total-listings="totalListings"
          :selected-category="selectedCategory"
          :selected-subcategory="selectedSubcategory"
          :expanded-categories="expandedCategories"
          @toggle-mobile-sidebar="toggleMobileSidebar"
          @select-category="selectCategory"
          @select-subcategory="selectSubcategory"
          @toggle-subcategories="toggleSubcategories"
        />
        <!-- Main Content Area -->
        <div class="flex-1 order-1 lg:order-2 min-w-0 overflow-hidden">
          <!-- Sorting & View Options - Compact Commercial -->
          <div
            class="bg-white px-3 py-2 rounded-xl shadow-sm mb-3 flex flex-wrap justify-between items-center gap-2 border border-gray-100"
          >
            <!-- Mobile Layout: Ads found + Post Sale Ad button on same row -->
            <div
              class="flex items-center justify-between w-full lg:w-auto lg:justify-start gap-2"
            >
              <div class="flex items-center gap-2">
                <div class="flex items-center gap-1.5">
                  <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                  <p class="text-gray-700 text-xs font-medium">
                    <span class="text-emerald-600 font-bold">{{
                      selectedCategory
                        ? getCateogryPostCount(selectedCategory)
                        : totalListings
                    }}</span>
                    ads
                    <span v-if="selectedCategory" class="text-gray-500">
                      in <span class="text-gray-700">{{ getCategoryName(selectedCategory) }}</span>
                    </span>
                  </p>
                </div>
              </div>
              <!-- Post Sale Ad Button - Mobile position -->
              <div class="lg:hidden">
                <div v-if="isAuthenticated" class="flex items-center gap-1.5">
                  <NuxtLink
                    to="/sale/my-posts"
                    class="whitespace-nowrap flex items-center gap-1 px-2 py-1 h-7 border border-emerald-400 text-emerald-600 rounded-lg hover:bg-emerald-50 transition-colors text-[11px] font-semibold"
                    @click="handleButtonClick('my-posts-mobile')"
                  >
                    <UIcon name="i-heroicons-list-bullet" class="h-3 w-3" />
                    <span>My Ads</span>
                  </NuxtLink>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1 px-2 py-1 h-7 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-lg hover:from-emerald-600 hover:to-teal-600 transition-all text-[11px] font-bold shadow-sm"
                    @click="handleButtonClick('post-ad-mobile')"
                  >
                    <UIcon name="i-heroicons-plus" class="h-3 w-3" />
                    <span>Post</span>
                  </NuxtLink>
                </div>
                <div v-else>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1 px-2 py-1 h-7 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-lg text-[11px] font-bold shadow-sm"
                  >
                    <UIcon name="i-heroicons-plus" class="h-3 w-3" />
                    Post Ad
                  </NuxtLink>
                </div>
              </div>
            </div>

            <!-- Desktop Layout: Sorting and Post Sale Ad button - Compact -->
            <div class="hidden lg:flex gap-3 items-center">
              <div class="flex items-center gap-2">
                <span class="text-sm text-gray-500">Sort:</span>
                <USelect
                  v-model="sortOption"
                  :options="sortOptions"
                  option-attribute="label"
                  value-attribute="value"
                  size="sm"
                  class="w-40 h-9"
                  :ui="{
                    padding: { sm: 'px-3 py-2' },
                    size: { sm: 'text-sm' },
                  }"
                  @update:modelValue="applyFilters"
                />
              </div>
              <div class="flex items-center border-l border-gray-200 pl-3 gap-2">
                <div v-if="isAuthenticated" class="flex items-center gap-2">
                  <NuxtLink
                    to="/sale/my-posts"
                    class="whitespace-nowrap flex items-center gap-1.5 px-3 py-2 h-9 border border-emerald-400 text-emerald-600 rounded-lg hover:bg-emerald-50 transition-colors text-sm font-semibold"
                  >
                    <UIcon name="i-heroicons-list-bullet" class="h-4 w-4" />
                    <span>My Ads</span>
                  </NuxtLink>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1.5 px-4 py-2 h-9 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-lg hover:from-emerald-600 hover:to-teal-600 transition-all text-sm font-bold shadow-sm"
                  >
                    <UIcon name="i-heroicons-plus" class="h-4 w-4" />
                    <span>Post Free Ad</span>
                  </NuxtLink>
                </div>
                <div v-else>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1.5 px-4 py-2 h-9 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-lg text-sm font-bold shadow-sm"
                  >
                    <UIcon name="i-heroicons-plus" class="h-4 w-4" />
                    <span>Post Free Ad</span>
                  </NuxtLink>
                </div>
              </div>
            </div>
            <!-- Mobile Sort Options - Compact -->
            <div class="lg:hidden w-full">
              <div class="flex items-center gap-1.5">
                <!-- Mobile Filter Button -->
                <button
                  @click="toggleMobileSidebar"
                  class="flex items-center gap-1 px-2 py-1 h-7 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors text-[11px] font-medium"
                >
                  <UIcon name="i-heroicons-squares-2x2" class="h-3 w-3" />
                  <span>Categories</span>
                </button>
                <span class="text-[11px] text-gray-500">Sort:</span>
                <USelect
                  v-model="sortOption"
                  :options="sortOptions"
                  option-attribute="label"
                  value-attribute="value"
                  size="xs"
                  class="w-28 h-7 flex-1"
                  :ui="{
                    padding: { xs: 'px-2 py-0.5' },
                    size: { xs: 'text-[11px]' },
                  }"
                  @update:modelValue="applyFilters"
                />
              </div>
            </div>
          </div>

          <!-- Active Filters Display - Compact -->
          <div
            v-if="hasActiveFilters"
            class="bg-white/80 backdrop-blur-sm px-2.5 py-2 rounded-lg shadow-sm mb-3 border border-gray-100"
          >
            <div class="flex flex-wrap items-center gap-1.5">
              <span class="text-[10px] text-gray-500 font-medium">Active:</span>

              <span
                v-if="selectedCategory"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-50 text-emerald-700 rounded-full text-[10px] font-medium border border-emerald-200"
              >
                {{ getCategoryName(selectedCategory) }}
                <button @click="clearCategory" class="hover:text-emerald-900">
                  <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
                </button>
              </span>

              <span
                v-if="selectedSubcategory"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-50 text-blue-700 rounded-full text-[10px] font-medium border border-blue-200"
              >
                {{ getSubcategoryName(selectedSubcategory) }}
                <button @click="clearSubcategory" class="hover:text-blue-900">
                  <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
                </button>
              </span>

              <span
                v-if="selectedDivision"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-purple-50 text-purple-700 rounded-full text-[10px] font-medium border border-purple-200"
              >
                <UIcon name="i-heroicons-map-pin" class="h-2.5 w-2.5" />
                {{ selectedDivision }}
                <button @click="handleClearLocation" class="hover:text-purple-900">
                  <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
                </button>
              </span>

              <span
                v-if="priceRange.min || priceRange.max"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-50 text-amber-700 rounded-full text-[10px] font-medium border border-amber-200"
              >
                ৳{{ priceRange.min || "0" }} - ৳{{ priceRange.max || "Any" }}
                <button @click="clearPriceRange" class="hover:text-amber-900">
                  <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
                </button>
              </span>

              <span
                v-if="selectedCondition"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-700 rounded-full text-[10px] font-medium border border-gray-200"
              >
                {{ getConditionLabel(selectedCondition) }}
                <button @click="selectedCondition = ''" class="hover:text-gray-900">
                  <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
                </button>
              </span>

              <span
                v-if="searchQuery"
                class="inline-flex items-center gap-1 px-2 py-0.5 bg-yellow-50 text-yellow-700 rounded-full text-[10px] font-medium border border-yellow-200"
              >
                <UIcon name="i-heroicons-magnifying-glass" class="h-2.5 w-2.5" />
                "{{ searchQuery }}"
                <span v-if="listings?.length" class="opacity-75">({{ listings.length }})</span>
                <button @click="clearSearch" class="hover:text-yellow-900">
                  <UIcon name="i-heroicons-x-mark" class="h-2.5 w-2.5" />
                </button>
              </span>
            </div>
          </div>

          <!-- Category Tabs Listings Section - Compact Commercial -->
          <div
            class="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden mb-4"
          >
            <!-- Section Header -->
            <div class="px-3 py-2 bg-gradient-to-r from-gray-50 to-white border-b border-gray-100">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <div class="w-6 h-6 rounded-lg bg-gradient-to-br from-emerald-500 to-teal-500 flex items-center justify-center">
                    <UIcon name="i-heroicons-shopping-bag" class="w-3.5 h-3.5 text-white" />
                  </div>
                  <h2 class="text-sm font-bold text-gray-800">{{ categoryBrowserHeading }}</h2>
                </div>
                <span class="text-[10px] text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">{{ listings?.length || 0 }} items</span>
              </div>
            </div>

            <!-- Category Posts Grid -->
            <div class="p-2">
              <div v-if="loading" class="py-12 text-center">
                <div class="w-10 h-10 mx-auto mb-3 rounded-full bg-emerald-100 flex items-center justify-center">
                  <UIcon name="i-heroicons-arrow-path" class="animate-spin h-5 w-5 text-emerald-600" />
                </div>
                <p class="text-gray-500 text-xs">Loading listings...</p>
              </div>
              <div v-else-if="!listings?.length" class="py-12 text-center">
                <div class="flex flex-col items-center">
                  <div class="w-14 h-14 rounded-full bg-gray-100 flex items-center justify-center mb-3">
                    <UIcon
                      :name="searchQuery ? 'i-heroicons-magnifying-glass' : 'i-heroicons-inbox'"
                      class="h-7 w-7 text-gray-400"
                    />
                  </div>
                  <h3 class="text-sm font-semibold text-gray-700 mb-1">
                    {{ searchQuery ? "No results found" : "No listings yet" }}
                  </h3>
                  <p class="text-gray-500 text-xs max-w-xs">
                    <span v-if="searchQuery">Try different keywords</span>
                    <span v-else>Be the first to post in this category!</span>
                  </p>
                  <button
                    v-if="searchQuery"
                    @click="clearSearch"
                    class="mt-3 px-3 py-1.5 bg-emerald-100 text-emerald-700 rounded-lg text-xs font-medium hover:bg-emerald-200 transition-colors"
                  >
                    Clear search
                  </button>
                </div>
              </div>
              <!-- List Type Design - Compact -->
              <div v-else class="space-y-2">
                <NuxtLink
                  v-for="(post, i) in listings"
                  :key="`post-${i}`"
                  :to="`/sale/${post.slug}`"
                  class="flex bg-white rounded-lg border border-gray-200 overflow-hidden hover:shadow-md hover:border-emerald-200 transition-all duration-200 group"
                >
                  <!-- Image - Left Side (Compact) -->
                  <div class="relative w-24 h-24 sm:w-28 sm:h-28 flex-shrink-0 overflow-hidden bg-gray-100">
                    <div
                      v-if="!getListingImage(post) || getListingImage(post).includes('placeholder')"
                      class="absolute inset-0 bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center"
                    >
                      <UIcon name="i-heroicons-photo" class="h-6 w-6 text-gray-300" />
                    </div>
                    <img
                      v-else
                      :src="getListingImage(post)"
                      :alt="post?.title || 'Image'"
                      class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      loading="lazy"
                    />
                    <!-- Condition Badge -->
                    <div v-if="post.condition" class="absolute top-1 left-1">
                      <span class="px-1.5 py-0.5 bg-emerald-600 text-white text-[8px] font-bold rounded uppercase">{{ post.condition }}</span>
                    </div>
                  </div>
                  <!-- Content - Right Side -->
                  <div class="flex-1 p-2 sm:p-2.5 flex flex-col justify-between min-w-0">
                    <!-- Title -->
                    <h3
                      class="text-gray-800 text-sm font-semibold line-clamp-1 leading-tight group-hover:text-emerald-600 transition-colors"
                      v-html="highlightSearchTerm(capitalizeTitle(post?.title) || 'Post title', searchQuery)"
                    ></h3>
                    <!-- Location -->
                    <div class="flex items-center gap-1 text-[11px] text-gray-500 mt-1">
                      <UIcon name="i-heroicons-map-pin" class="h-3 w-3 flex-shrink-0 text-gray-400" />
                      <span class="truncate">{{ post?.district ? `${post.district}, ${post.division}` : post?.division || 'Bangladesh' }}</span>
                    </div>
                    <!-- Price & Date Row -->
                    <div class="flex items-center justify-between mt-1.5">
                      <p class="text-emerald-600 font-bold text-base">
                        <span v-if="post.negotiable && !post.price" class="text-sm text-gray-600">Negotiable</span>
                        <span v-else-if="post.price">৳{{ formatPrice(post.price) }}</span>
                        <span v-else class="text-gray-500 text-xs">Contact</span>
                      </p>
                      <p class="text-[10px] text-gray-400 flex items-center gap-0.5">
                        <UIcon name="i-heroicons-clock" class="h-3 w-3" />
                        {{ formatDate(post.created_at) }}
                      </p>
                    </div>
                  </div>
                </NuxtLink>
              </div>
            </div>
            <!-- Load More Button - Compact -->
            <div v-if="hasMoreListings && !loading" class="flex justify-center py-4">
              <button
                @click="loadMorePosts"
                :disabled="isLoadingMore"
                class="flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-lg text-xs font-bold shadow-sm hover:from-emerald-600 hover:to-teal-600 disabled:opacity-50 transition-all"
              >
                <UIcon v-if="isLoadingMore" name="i-heroicons-arrow-path" class="animate-spin h-3.5 w-3.5" />
                <UIcon v-else name="i-heroicons-arrow-down" class="h-3.5 w-3.5" />
                <span>{{ isLoadingMore ? 'Loading...' : 'Load More' }}</span>
              </button>
            </div>

            <!-- All Posts Loaded Message - Compact -->
            <div v-if="!hasMoreListings && listings.length > 0 && !loading" class="text-center py-4">
              <div class="flex items-center justify-center gap-2">
                <div class="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center">
                  <UIcon name="i-heroicons-check" class="h-3.5 w-3.5 text-emerald-600" />
                </div>
                <p class="text-xs text-gray-500">All <span class="font-semibold text-gray-700">{{ totalListingsCount }}</span> listings loaded</p>
              </div>
            </div>
          </div>

          <!-- Recent Listings Section - Compact Commercial -->
          <div class="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden mb-4">
            <!-- Section Header -->
            <div class="px-3 py-2 bg-gradient-to-r from-amber-50 to-orange-50 border-b border-amber-100">
              <div class="flex items-center gap-2">
                <div class="w-6 h-6 rounded-lg bg-gradient-to-br from-amber-500 to-orange-500 flex items-center justify-center">
                  <UIcon name="i-heroicons-clock" class="w-3.5 h-3.5 text-white" />
                </div>
                <h2 class="text-sm font-bold text-amber-800">Recent Listings</h2>
              </div>
            </div>
            <!-- Recent Listings Horizontal Scroll -->
            <div class="p-2">
              <div class="overflow-x-auto scrollbar-hide -mx-1 px-1">
                <div class="flex gap-2 min-w-max pb-1">
                  <NuxtLink
                    v-for="(listing, i) in recentListings.slice(0, 6)"
                    :key="`listing-${i}`"
                    :to="`/sale/${listing.slug}`"
                    class="flex-shrink-0 w-44 bg-white rounded-lg border border-gray-100 overflow-hidden hover:shadow-md hover:border-amber-200 transition-all group"
                  >
                    <div class="relative h-28 overflow-hidden bg-gray-50">
                      <img
                        :src="getListingImage(listing)"
                        :alt="listing?.title || 'Image'"
                        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        loading="lazy"
                      />
                      <div class="absolute top-1 right-1">
                        <span class="bg-white/90 text-amber-700 text-[9px] px-1.5 py-0.5 rounded-full font-semibold shadow-sm">
                          {{ getCategoryName(listing.category) }}
                        </span>
                      </div>
                    </div>
                    <div class="p-2">
                      <h3 class="font-medium text-gray-700 text-[11px] line-clamp-1 group-hover:text-amber-700 transition-colors">
                        {{ capitalizeTitle(listing?.title) || 'Title' }}
                      </h3>
                      <div class="flex items-center justify-between mt-1">
                        <p class="text-amber-600 font-bold text-xs">
                          <span v-if="listing.price">৳{{ formatPrice(listing.price) }}</span>
                          <span v-else class="text-gray-500">Negotiable</span>
                        </p>
                        <p class="text-[9px] text-gray-400">{{ formatDate(listing.created_at) }}</p>
                      </div>
                    </div>
                  </NuxtLink>
                </div>
              </div>
            </div>
          </div>
          <div v-if="recentListingsLoading" class="py-8 text-center bg-white rounded-xl shadow-sm border border-gray-100">
            <div class="w-8 h-8 mx-auto mb-2 rounded-full bg-amber-100 flex items-center justify-center">
              <UIcon name="i-heroicons-arrow-path" class="animate-spin h-4 w-4 text-amber-600" />
            </div>
            <p class="text-gray-500 text-xs">Loading recent...</p>
          </div>
          <!-- Tips & Safety Guide - Compact Commercial -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-3 mt-4">
            <!-- Smart Buying Tips -->
            <div class="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden">
              <div class="px-3 py-2 bg-gradient-to-r from-blue-50 to-indigo-50 border-b border-blue-100">
                <div class="flex items-center gap-2">
                  <div class="w-6 h-6 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center">
                    <UIcon name="i-heroicons-light-bulb" class="w-3.5 h-3.5 text-white" />
                  </div>
                  <div>
                    <h3 class="text-sm font-bold text-blue-800">Smart Buying Tips</h3>
                    <p class="text-[10px] text-blue-600">Shop with confidence</p>
                  </div>
                </div>
              </div>

              <div class="p-3 space-y-2">
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-eye" class="h-2.5 w-2.5 text-blue-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Inspect Before Buying</p>
                    <p class="text-gray-500 text-[10px]">Examine items in person before payment</p>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-map-pin" class="h-2.5 w-2.5 text-blue-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Meet in Public Places</p>
                    <p class="text-gray-500 text-[10px]">Choose safe, well-lit locations</p>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-document-check" class="h-2.5 w-2.5 text-blue-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Verify Authenticity</p>
                    <p class="text-gray-500 text-[10px]">Check documentation before purchase</p>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-scale" class="h-2.5 w-2.5 text-blue-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Compare Prices</p>
                    <p class="text-gray-500 text-[10px]">Research similar listings for fair pricing</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Security & Safety -->
            <div class="bg-white rounded-xl border border-gray-200/80 shadow-sm overflow-hidden">
              <div class="px-3 py-2 bg-gradient-to-r from-emerald-50 to-green-50 border-b border-emerald-100">
                <div class="flex items-center gap-2">
                  <div class="w-6 h-6 rounded-lg bg-gradient-to-br from-emerald-500 to-green-500 flex items-center justify-center">
                    <UIcon name="i-heroicons-shield-check" class="w-3.5 h-3.5 text-white" />
                  </div>
                  <div>
                    <h3 class="text-sm font-bold text-emerald-800">Security & Safety</h3>
                    <p class="text-[10px] text-emerald-600">Stay protected online</p>
                  </div>
                </div>
              </div>
              <div class="p-3 space-y-2">
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-lock-closed" class="h-2.5 w-2.5 text-emerald-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Protect Personal Info</p>
                    <p class="text-gray-500 text-[10px]">Never share banking details</p>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-exclamation-triangle" class="h-2.5 w-2.5 text-emerald-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Spot Red Flags</p>
                    <p class="text-gray-500 text-[10px]">Be cautious of unrealistic deals</p>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-chat-bubble-left-ellipsis" class="h-2.5 w-2.5 text-emerald-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Use Platform Messaging</p>
                    <p class="text-gray-500 text-[10px]">Keep communications secure</p>
                  </div>
                </div>
                <div class="flex items-start gap-2">
                  <div class="w-5 h-5 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <UIcon name="i-heroicons-user-group" class="h-2.5 w-2.5 text-emerald-600" />
                  </div>
                  <div>
                    <p class="text-gray-700 font-medium text-[11px]">Trust Your Instincts</p>
                    <p class="text-gray-500 text-[10px]">Walk away if something feels wrong</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, defineAsyncComponent } from "vue";

import { useApi } from "~/composables/useApi";
import SaleSidebar from "~/components/sale/SaleSidebar.vue";
import SaleSearchBar from "~/components/sale/SaleSearchBar.vue";

const { user, isAuthenticated } = useAuth();
const { query } = useRoute();

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

// API endpoints
const API_ENDPOINTS = {
  CATEGORIES: "/sale/categories/",
  SUBCATEGORIES: "/sale/subcategories/",
  LISTINGS: "/sale/posts/",
  DIVISIONS: "/geo/divisions/",
  DISTRICTS: "/geo/districts/",
  AREAS: "/geo/areas/",
  POSTS: "/sale/posts/",
};

const currentPage = ref(1);
const totalPages = ref(0);

const { location, clearLocation } = useLocation(); // Use enhanced location composable
const { t } = useI18n();

const { get } = useApi();

const form = ref({
  country: "Bangladesh",
  state: location.value?.state || "",
  city: location.value?.city || "",
  upazila: location.value?.upazila || "",
  title: "",
  category: "",
});

// State variables
const isLoading = ref(false);
const loading = ref(true);
const listings = ref([]); // Renamed from posts to match template usage
const viewMode = ref("grid");
const isMobileFilterOpen = ref(false);

// Pagination state
const isLoadingMore = ref(false);
const hasMoreListings = ref(false);
const totalListingsCount = ref(0);

// Function to toggle mobile sidebar visibility
function toggleMobileSidebar() {
  isMobileFilterOpen.value = !isMobileFilterOpen.value;
}

// Function to clear location and reload page
const handleClearLocation = () => {
  clearLocation();
  window.location.reload();
};

// Function to handle search from the search bar component
const handleSearch = (searchTerm) => {
  form.value.title = searchTerm;
  filterSearch();
};

// Function to clear search and reload listings
async function clearSearch() {
  searchQuery.value = "";
  form.value.title = "";
  currentPage.value = 1;
  await loadPosts(1, false);
}

// Function to highlight search terms in text
function highlightSearchTerm(text, searchTerm) {
  if (!searchTerm || !text) return text;

  const regex = new RegExp(
    `(${searchTerm.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`,
    "gi"
  );
  return text.replace(
    regex,
    '<mark class="bg-yellow-200 px-1 rounded">$1</mark>'
  );
}

// Function to handle search form submission
async function filterSearch() {
  try {
    isLoading.value = true;
    searchQuery.value = form.value.title?.trim() || "";
    currentPage.value = 1;

    // Clear other filters when searching to avoid conflicts (only if there's a search query)
    if (searchQuery.value) {
      selectedCategory.value = null;
      selectedSubcategory.value = null;
      selectedDivision.value = null;
      selectedDistrict.value = null;
      selectedArea.value = null;
      selectedCondition.value = null;
      priceRange.value = { min: null, max: null };
    }

    // Apply the search query filter
    await loadPosts(1, false);
  } catch (error) {
    console.error("Search error:", error);
  } finally {
    isLoading.value = false;
  }
}

const searchQuery = ref("");
const totalListings = ref(0); // Added to match template usage
const categories = ref([]);
const selectedCategory = ref(query.category || null); // Added to match template usage
const selectedSubcategory = ref(null); // Added to match template usage
const selectedDivision = ref(""); // Added to match template usage
const selectedDistrict = ref(""); // Added for location selection
const selectedArea = ref(""); // Added for location selection
const selectedCondition = ref(""); // Added to match template usage
const sortOption = ref("newest"); // Added to match template usage
// Pagination variables removed
const categoryCountsMap = ref({});
const expandedCategories = ref([]);

// Define priceRange object
const priceRange = ref({
  min: "",
  max: "",
});

// Define subcategoryTitle computed prop
const subcategoryTitle = computed(() => {
  switch (parseInt(selectedCategory.value)) {
    case 1:
      return "Property Type";
    case 2:
      return "Vehicle Type";
    case 3:
      return "Electronics Type";
    default:
      return "Type";
  }
});

// Sort options
const sortOptions = [
  { label: "Newest First", value: "newest" },
  { label: "Oldest First", value: "oldest" },
  { label: "Price: Low to High", value: "price_low" },
  { label: "Price: High to Low", value: "price_high" },
];

// Computed property for checking active filters
const hasActiveFilters = computed(() => {
  return (
    selectedCategory.value ||
    selectedSubcategory.value ||
    selectedDivision.value ||
    selectedDistrict.value ||
    selectedArea.value ||
    priceRange.value.min ||
    priceRange.value.max ||
    selectedCondition.value ||
    searchQuery.value
  );
});

// Pagination computed properties removed

// Location variables - to be loaded from API
const divisions = ref([]);
const districtsByDivision = ref({});
const areasByDistrict = ref({});
const regions = ref([]); // Added to match template reference
const searchLocationOption = ref(true); // Show location selector by default

// Location data for search filters
const cities = ref([]);
const upazilas = ref([]);

// Function to load location data from API
async function loadLocationData() {
  try {
    // Load regions (divisions)
    const divisionsResponse = await get(API_ENDPOINTS.DIVISIONS);
    if (divisionsResponse?.data && Array.isArray(divisionsResponse.data)) {
      divisions.value = divisionsResponse.data;
      regions.value = divisionsResponse.data; // Populate regions with divisions data for backward compatibility
    }

    // If we have a selected division, load its districts
    if (selectedDivision.value) {
      const districtsResponse = await get(
        `${API_ENDPOINTS.DISTRICTS}?division=${selectedDivision.value}`
      );
      if (districtsResponse?.data && Array.isArray(districtsResponse.data)) {
        districtsByDivision.value[selectedDivision.value] =
          districtsResponse.data;
        cities.value = districtsResponse.data; // Set cities for current UI
      }
    }

    // If we have a selected district, load its areas
    if (selectedDistrict.value) {
      const areasResponse = await get(
        `${API_ENDPOINTS.AREAS}?district=${selectedDistrict.value}`
      );
      if (areasResponse?.data && Array.isArray(areasResponse.data)) {
        areasByDistrict.value[selectedDistrict.value] = areasResponse.data;
        upazilas.value = areasResponse.data; // Set upazilas for current UI
      }
    }
  } catch (error) {
    console.error("Error loading location data:", error);
  }
}

// Computed properties for location options
const districtOptions = computed(() => {
  return selectedDivision.value
    ? districtsByDivision[selectedDivision.value] || []
    : [];
});

const areaOptions = computed(() => {
  return selectedDistrict.value
    ? areasByDistrict[selectedDistrict.value] || []
    : [];
});

// Fetch categories from the API
async function fetchCategories() {
  try {
    const response = await get(API_ENDPOINTS.CATEGORIES);

    if (response && Array.isArray(response.data)) {
      categories.value = response.data;
      totalListings.value = categories.value.reduce(
        (acc, item) => acc + item.post_count,
        0
      );
    } else {
      categories.value = [];
    }
  } catch (error) {
    console.error("Error fetching categories:", error);
    categories.value = [];
  }
}

// Function to handle empty or failed category responses
function handleEmptyCategories() {
  return [];
}

// Load posts based on current filters with proper pagination
async function loadPosts(page = 1, isLoadMore = false) {
  if (isLoadMore) {
    isLoadingMore.value = true;
  } else {
    loading.value = true;
  }

  try {
    // Build query parameters
    const params = new URLSearchParams();

    // Add pagination with page size of 10
    params.append("page", page.toString());
    params.append("page_size", "10"); // Add filters
    if (selectedCategory.value)
      params.append("category", selectedCategory.value.toString());
    if (selectedSubcategory.value)
      params.append("subcategory", selectedSubcategory.value.toString());
    if (searchQuery.value) {
      // Use comprehensive search that looks in title and description
      params.append("search", searchQuery.value);
    }
    if (priceRange.value.min)
      params.append("min_price", priceRange.value.min.toString());
    if (priceRange.value.max)
      params.append("max_price", priceRange.value.max.toString());
    if (selectedCondition.value)
      params.append("condition", selectedCondition.value);

    // Apply location filtering
    // Priority: Manual sidebar filters > User saved location > No location filter

    // Check if manual location filters are set (from sidebar filters)
    const hasManualLocationFilters =
      selectedDivision.value || selectedDistrict.value || selectedArea.value;

    if (hasManualLocationFilters) {
      // Use manual filters if they're set (user has specifically filtered on the page)
      if (selectedDivision.value)
        params.append("division", selectedDivision.value);
      if (selectedDistrict.value)
        params.append("district", selectedDistrict.value);
      if (selectedArea.value) params.append("area", selectedArea.value);
    } else {
      // Use saved location from CommonGeoSelector if no manual filters are set
      const userLocation = location.value;
      if (userLocation && !userLocation.allOverBangladesh) {
        // User has selected a specific location, filter posts accordingly
        if (userLocation.state) {
          params.append("division", userLocation.state);
        }
        if (userLocation.city) {
          params.append("district", userLocation.city);
        }
        if (userLocation.upazila) {
          params.append("area", userLocation.upazila);
        }
      }
      // If user selected "All Over Bangladesh" or no location is set, don't add location filters
      // This will show posts from all locations
    }

    // Sort
    const sortMapping = {
      newest: "-created_at",
      oldest: "created_at",
      price_low: "price",
      price_high: "-price",
      most_viewed: "-views",
    };
    params.append("sort", sortMapping[sortOption.value] || "-created_at");

    // Get data from API
    const apiUrl = `${API_ENDPOINTS.LISTINGS}?${params.toString()}`;

    const response = await get(apiUrl);

    if (response && response.data) {
      if (response.data.results) {
        // Paginated response
        const newListings = mapListingsData(response.data.results);

        if (isLoadMore) {
          // Append new listings to existing ones
          listings.value = [...listings.value, ...newListings];
        } else {
          // Replace listings for fresh load
          listings.value = newListings;
        }

        // Update pagination info
        totalPages.value = Math.ceil(response.data.count / 10);
        hasMoreListings.value = !!response.data.next;
        totalListingsCount.value = response.data.count;
      } else if (Array.isArray(response.data)) {
        // Array response
        const newListings = mapListingsData(response.data);
        if (isLoadMore) {
          listings.value = [...listings.value, ...newListings];
        } else {
          listings.value = newListings;
        }
        hasMoreListings.value = false;
      }
    } else {
      if (!isLoadMore) {
        listings.value = [];
      }
      hasMoreListings.value = false;
    }
  } catch (error) {
    console.error("Error loading listings:", error);
    if (!isLoadMore) {
      listings.value = [];
    }
    hasMoreListings.value = false;
  } finally {
    loading.value = false;
    isLoadingMore.value = false;
  }
}

// Map listing data to a consistent format
function mapListingsData(data) {
  return data.map((item) => ({
    id: item.id,
    title: item?.title || "",
    slug: item.slug || `listing-${item.id}`,
    price: item.price,
    negotiable: item.negotiable,
    description: item.description,
    category: item.category_id || item.category,
    condition: item.condition,
    status: item.status,
    featured: item.featured,
    created_at: item.created_at || new Date().toISOString(),

    // Images
    main_image: item.main_image,
    images: item.images || [],

    // Location
    division: item.division,
    district: item.district,
    area: item.area,

    // Category-specific fields
    property_type: item.property_type,
    bedrooms: item.bedrooms,
    size: item.size,
    unit: item.unit,
    make: item.make,
    model: item.model,
    year: item.year,
    brand: item.brand,
  }));
}

// Helper functions
function getCategoryName(categoryId) {
  if (!categoryId) return "";
  const category = categories.value.find((c) => c.id === parseInt(categoryId));
  return category ? category.name : "";
}

function getCateogryPostCount(categoryId) {
  if (!categoryId) return 0;
  const category = categories.value.find((c) => c.id === parseInt(categoryId));
  return category ? category.post_count : 0;
}

// Function to capitalize first letter of title
function capitalizeTitle(title) {
  if (!title) return "";
  return title.charAt(0).toUpperCase() + title.slice(1);
}

function getConditionLabel(condition) {
  const conditions = {
    new: "Brand New",
    "like-new": "Like New",
    good: "Good",
    fair: "Fair",
    poor: "Poor",
  };
  return conditions[condition] || condition;
}

function getSubcategoryName(subcategoryId) {
  // Find the subcategory name based on the ID
  if (!subcategoryId) return "";

  // Convert subcategoryId to string to ensure consistent comparison
  const subIdStr = String(subcategoryId);

  // Loop through all categories and their subcategories to find the matching one
  for (const categoryId in getSubcategories()) {
    const subCategory = getSubcategories(parseInt(categoryId)).find(
      (sub) => String(sub.id) === subIdStr
    );
    if (subCategory) return subCategory.name;
  }

  return subcategoryId; // Fallback to ID if name not found
}

function getListingImage(listing) {
  if (listing.main_image) {
    return listing.main_image;
  }

  if (listing.images && listing.images?.length > 0) {
    return listing.images[0];
  }

  return null; // Return null instead of placeholder URL
}

function formatPrice(price) {
  return new Intl.NumberFormat("en-IN").format(price);
}

function formatDate(dateStr) {
  if (!dateStr) return "";

  const date = new Date(dateStr);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays} days ago`;

  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
}

async function getSubcategories(categoryId) {
  // This should be replaced with an API call
  try {
    const response = await get(`${API_ENDPOINTS.SUBCATEGORIES}/${categoryId}`);
    if (response && response.data && Array.isArray(response.data)) {
      return response.data;
    }
  } catch (error) {
    console.error(
      `Error fetching subcategories for category ${categoryId}:`,
      error
    );
  }

  return [];
}

function toggleSubcategories(category) {
  expandedCategories.value = category;
}

function selectSubcategory(subcategoryId) {
  selectedSubcategory.value = subcategoryId;
  loadPosts(1);
}

// Action handlers
async function selectCategory(catId) {
  selectedCategory.value = catId;
  selectedSubcategory.value = null;
  currentPage.value = 1;
  await loadPosts(1, false);
}

async function clearCategory() {
  selectedCategory.value = null;
  selectedSubcategory.value = null;
  currentPage.value = 1;
  await loadPosts(1, false);
}

async function clearSubcategory() {
  selectedSubcategory.value = null;
  currentPage.value = 1;
  await loadPosts(1, false);
}

async function clearPriceRange() {
  priceRange.value.min = "";
  priceRange.value.max = "";
  currentPage.value = 1;
  await loadPosts(1, false);
}

function applyFilters() {
  currentPage.value = 1;
  loadPosts(1, false);
}

function onPageChange(page) {
  loadPosts(page);
}

// Load more posts function for pagination
async function loadMorePosts() {
  if (!hasMoreListings.value || isLoadingMore.value) return;

  currentPage.value++;
  await loadPosts(currentPage.value, true);
}

// Location selection handlers
function handleDivisionChange() {
  selectedDistrict.value = "";
  selectedArea.value = "";
  applyFilters();
}

function handleDistrictChange() {
  selectedArea.value = "";
  applyFilters();
}

// Category browsing pagination - 3 rows of 4 items on large screens (12 items)
const categoryItemsPerPage = 12;
const categoryCurrentPage = ref(1);
const categoryPageCount = computed(() => {
  return Math.ceil(categoryPosts.value?.length / categoryItemsPerPage);
});
const paginatedCategoryPosts = computed(() => {
  const start = (categoryCurrentPage.value - 1) * categoryItemsPerPage;
  const end = start + categoryItemsPerPage;
  return categoryPosts.value.slice(start, end);
});

// Watch category tab changes to reset pagination
// Dynamic heading for category browser section
const categoryBrowserHeading = computed(() => {
  if (selectedSubcategory.value) {
    return getSubcategoryName(selectedSubcategory.value);
  } else if (selectedCategory.value) {
    return getCategoryName(selectedCategory.value);
  } else {
    return "All category listings";
  }
});

const categoryPosts = ref([]);
const categoryTabLoading = ref(false);

// Load category posts function
async function loadCategoryPosts() {
  categoryTabLoading.value = true;

  try {
    const params = new URLSearchParams();
    params.append("page", "1");
    params.append("page_size", "24");
    params.append("sort", "-created_at");

    const response = await get(API_ENDPOINTS.POSTS);

    if (response && response.data) {
      if (response.data.results) {
        categoryPosts.value = mapListingsData(response.data.results);
      } else if (Array.isArray(response.data)) {
        categoryPosts.value = mapListingsData(response.data);
      } else {
        categoryPosts.value = [];
      }
    } else {
      categoryPosts.value = [];
    }
  } catch (error) {
    console.error("Error loading category posts:", error);
    categoryPosts.value = [];
  } finally {
    categoryTabLoading.value = false;
  }
}

// Recent Listings section variables
const recentListings = ref([]);
const recentListingsLoading = ref(false);

// Load recent listings
async function loadRecentListings() {
  recentListingsLoading.value = true;

  try {
    const params = new URLSearchParams();
    params.append("page", "1");
    params.append("page_size", "5"); // Limit to 5 items for single row display
    params.append("sort", "-created_at"); // Always sort by newest

    const response = await get(API_ENDPOINTS.POSTS);

    if (response && response.data) {
      if (response.data.results) {
        recentListings.value = mapListingsData(response.data.results);
      } else if (Array.isArray(response.data)) {
        recentListings.value = mapListingsData(response.data);
      } else {
        recentListings.value = [];
      }
    } else {
      recentListings.value = [];
    }
  } catch (error) {
    console.error("Error loading recent listings:", error);
    recentListings.value = [];
  } finally {
    recentListingsLoading.value = false;
  }
}

// Modified onMounted to also load recent listings
onMounted(() => {
  // Load categories first
  fetchCategories().then(() => {
    // Then load all list types in parallel
    Promise.all([
      loadPosts(),
      loadCategoryPosts(),
      loadRecentListings(),
      loadLocationData(),
    ]).catch((error) => {
      console.error("Error during initial data loading:", error);
    });
  });
});

// Add recent listings to the categories watcher
watch(categories, () => {
  if (categories.value?.length > 0) {
    if (categoryPosts.value?.length === 0) loadCategoryPosts();
    if (recentListings.value?.length === 0) loadRecentListings();
  }
});

// Watch for location changes from CommonGeoSelector to refresh posts
watch(
  () => location.value,
  (newLocation, oldLocation) => {
    // Only reload if location actually changed and we have categories loaded
    if (
      categories.value?.length > 0 &&
      JSON.stringify(newLocation) !== JSON.stringify(oldLocation)
    ) {
      // Reset to first page and reload posts with new location filter
      currentPage.value = 1;
      loadPosts(1, false);
    }
  },
  { deep: true }
);

// Watch for changes in form.state (division) to load corresponding districts/cities
watch(
  () => form.value.state,
  async (newDivision) => {
    if (newDivision) {
      selectedDivision.value = newDivision;

      // Load districts for this division if not already loaded
      try {
        const districtsResponse = await get(
          `${API_ENDPOINTS.DISTRICTS}?division=${newDivision}`
        );
        if (districtsResponse?.data && Array.isArray(districtsResponse.data)) {
          districtsByDivision.value[newDivision] = districtsResponse.data;
          cities.value = districtsResponse.data;
        }
      } catch (error) {
        console.error(`Error loading districts for ${newDivision}:`, error);
      }
    } else {
      cities.value = [];
    }
  }
);

// Watch for changes in form.city (district) to load corresponding areas/upazilas
watch(
  () => form.value.city,
  async (newDistrict) => {
    if (newDistrict) {
      selectedDistrict.value = newDistrict;

      // Load areas for this district if not already loaded
      try {
        const areasResponse = await get(
          `${API_ENDPOINTS.AREAS}?district=${newDistrict}`
        );
        if (areasResponse?.data && Array.isArray(areasResponse.data)) {
          areasByDistrict.value[newDistrict] = areasResponse.data;
          upazilas.value = areasResponse.data;
        }
      } catch (error) {
        console.error(`Error loading areas for ${newDistrict}:`, error);
      }
    } else {
      upazilas.value = [];
    }
  }
);
</script>

<style>
/* Small utility classes to support the design */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Small utility classes for the main content */

/* Custom animations */
@keyframes bounce-slow {
  0%,
  100% {
    transform: translateY(-5%);
    animation-timing-function: cubic-bezier(0.8, 0, 1, 1);
  }
  50% {
    transform: translateY(0);
    animation-timing-function: cubic-bezier(0, 0, 0.2, 1);
  }
}

.animate-bounce-slow {
  animation: bounce-slow 3s infinite;
}

/* Hide scrollbar for recent listings */
.scrollbar-hide {
  -ms-overflow-style: none; /* Internet Explorer 10+ */
  scrollbar-width: none; /* Firefox */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Safari and Chrome */
}

/* Compact select styling for mobile */
.compact-select button {
  justify-content: space-between !important;
  padding-left: 8px !important;
  padding-right: 4px !important;
}

.compact-select button span {
  margin-right: 2px !important;
}

.compact-select svg {
  margin-left: 2px !important;
}

/* Dotted Spinner Styles */
.dotted-spinner {
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.primary {
  border-color: #3b82f6;
}

.dotted-spinner.white {
  border-color: #ffffff;
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
