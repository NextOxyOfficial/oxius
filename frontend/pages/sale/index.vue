<template>
  <div class="bg-gray-50/80 min-h-screen">
    <!-- Top Navigation Bar with Search and Post Button -->
    <div class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
      <CommonGeoSelector />
      <UContainer class="py-3">
        <div class="location-breadcrumb relative mb-3 overflow-hidden">
          <!-- Subtle background effect -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-gray-50 to-primary-50 opacity-70 rounded-lg"
          ></div>

          <!-- Decorative map pin -->
          <div
            class="absolute -left-3 top-1/2 -translate-y-1/2 text-primary-400"
          >
            <UIcon name="i-heroicons-map-pin" class="w-16 h-16" />
          </div>

          <div
            class="relative z-10 flex items-center justify-between px-3 pl-12 rounded-lg border border-primary-100"
          >
            <!-- Location path with icons -->
            <div class="location-breadcrumb relative my-3 overflow-hidden">
              <!-- Subtle background effect -->
              <div
                class="relative z-10 flex items-center justify-between p-1 rounded-lg border border-primary-100"
              >
                <!-- Location path with icons -->
                <div class="flex items-center flex-wrap location-path">
                  <!-- Show country if allOverBangladesh is true or only country is set -->
                  <div
                    v-if="
                      location?.allOverBangladesh ||
                      (location?.country && !location?.state)
                    "
                    class="location-segment flex items-center"
                    data-location="country"
                  >
                    <UIcon
                      name="i-heroicons-globe-asia-australia"
                      class="text-primary-600 mr-1.5 animate-pulse-slow"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.country || "Bangladesh"
                    }}</span>
                    <span
                      v-if="location?.allOverBangladesh"
                      class="ml-2 text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full"
                    >
                      All over {{ location?.country || "Bangladesh" }}
                    </span>
                  </div>

                  <!-- Show state, city, upazila only if not allOverBangladesh -->
                  <template v-if="!location?.allOverBangladesh">
                    <div
                      v-if="location?.state"
                      class="location-segment flex items-center"
                      data-location="state"
                    >
                      <UIcon
                        name="i-heroicons-map"
                        class="text-primary-600 mr-1.5 animate-pulse-slow"
                      />
                      <span class="font-medium text-gray-800">{{
                        location?.state
                      }}</span>
                      <UIcon
                        v-if="location?.city"
                        name="i-heroicons-chevron-right"
                        class="mx-1.5 text-gray-600"
                      />
                    </div>

                    <div
                      v-if="location?.city"
                      class="location-segment flex items-center"
                      data-location="city"
                    >
                      <UIcon
                        name="i-heroicons-building-office-2"
                        class="text-primary-600 mr-1.5 location-icon"
                      />
                      <span class="font-medium text-gray-800">{{
                        location?.city
                      }}</span>
                      <UIcon
                        v-if="location?.upazila"
                        name="i-heroicons-chevron-right"
                        class="mx-1.5 text-gray-600"
                      />
                    </div>

                    <div
                      v-if="location?.upazila"
                      class="location-segment flex items-center"
                      data-location="upazila"
                    >
                      <UIcon
                        name="i-heroicons-home-modern"
                        class="text-primary-600 mr-1.5 location-icon"
                      />
                      <span class="font-medium text-gray-800">{{
                        location?.upazila
                      }}</span>
                    </div>
                  </template>
                </div>
              </div>
            </div>
            <UTooltip text="Change Location" class="me-auto">
              <UButton
                icon="i-heroicons-map-pin"
                size="md"
                color="primary"
                variant="ghost"
                trailing-icon="i-heroicons-pencil-square"
                class="edit-location-btn ml-2 relative overflow-hidden"
                @click="handleClearLocation"
              >
                <span class="sr-only">Edit Location</span>
              </UButton>
            </UTooltip>
            <UButtonGroup size="md" class="flex-1 hidden md:flex md:w-2/4">
              <UInput
                icon="i-heroicons-magnifying-glass-20-solid"
                size="md"
                color="white"
                :trailing="false"
                placeholder="Search..."
                v-model="form.title"
                @keyup.enter="filterSearch"
                class="w-full"
                :ui="{
                  padding: {
                    md: 'sm:py-2.5',
                  },
                }"
              />

              <UButton
                size="md"
                :loading="isLoading"
                color="primary"
                variant="solid"
                :label="t('search')"
                @click="filterSearch"
                class="sm:h-10 max-sm:!text-base w-24 justify-center"
                :ui="{
                  padding: {
                    md: 'sm:py-2.5',
                  },
                }"
              />
            </UButtonGroup>
          </div>
        </div>
        <UButtonGroup
          size="md"
          class="flex-1 flex md:hidden md:w-2/4 px-2 pb-2"
        >
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="md"
            color="white"
            :trailing="false"
            placeholder="Search..."
            v-model="form.title"
            @keyup.enter="filterSearch"
            class="w-full"
            :ui="{
              padding: {
                md: 'sm:py-2.5',
              },
            }"
          />

          <UButton
            size="md"
            :loading="isLoading"
            color="primary"
            variant="solid"
            icon="i-heroicons-magnifying-glass-20-solid"
            @click="filterSearch"
            class="sm:h-10 max-sm:!text-base w-12 justify-center"
            :ui="{
              padding: {
                md: 'sm:py-2.5',
              },
            }"
          />
        </UButtonGroup>
      </UContainer>
    </div>
    <UContainer class="sm:py-6">
      <!-- Overlay for mobile -->
      <div
        v-if="isMobileFilterOpen"
        class="fixed inset-0 bg-black bg-opacity-60 z-40 lg:hidden"
        @click="toggleMobileSidebar"
      ></div>
      <div class="flex flex-col lg:flex-row gap-6">
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
          <!-- Sorting & View Options -->
          <div
            class="bg-white p-2 rounded-lg shadow-sm mb-4 flex flex-wrap justify-between items-center gap-4"
          >
            <!-- Mobile Layout: Ads found + Post Sale Ad button on same row -->
            <div
              class="flex items-center justify-between w-full lg:w-auto lg:justify-start gap-3"
            >
              <div class="flex items-center gap-3">
                <p class="text-gray-600 text-sm">
                  <span class="font-medium text-gray-800">{{
                    selectedCategory
                      ? getCateogryPostCount(selectedCategory)
                      : totalListings
                  }}</span>
                  ads found
                  <span v-if="selectedCategory">
                    in
                    <span class="font-medium text-gray-800">{{
                      getCategoryName(selectedCategory)
                    }}</span>
                  </span>
                </p>
              </div>
              <!-- Post Sale Ad Button - Mobile position (right side of ads found row) -->
              <div class="lg:hidden">
                <div v-if="isAuthenticated" class="flex items-center gap-2">
                  <NuxtLink
                    to="/sale/my-posts"
                    class="whitespace-nowrap flex items-center gap-1 px-2 py-1.5 h-8 border border-primary-500 text-primary-600 rounded-md hover:bg-primary-50 transition-colors text-xs"
                  >
                    <UIcon name="i-heroicons-list-bullet" class="h-3 w-3" />
                    My Posts
                  </NuxtLink>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1 px-2 py-1.5 h-8 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors text-xs"
                  >
                    <UIcon name="i-heroicons-plus-circle" class="h-3 w-3" />
                    Post Ad
                  </NuxtLink>
                </div>
                <div v-else>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1 px-2 py-1.5 h-8 border border-primary-500 text-primary-600 rounded-md hover:bg-primary-50 transition-colors text-xs"
                  >
                    <UIcon name="i-heroicons-plus-circle" class="h-3 w-3" />
                    Post Ad
                  </NuxtLink>
                </div>
              </div>
            </div>

            <!-- Desktop Layout: Sorting and Post Sale Ad button -->
            <div class="hidden lg:flex gap-6 items-center">
              <div class="flex items-center gap-2">
                <span class="text-sm text-gray-600">Sort by:</span>
                <USelect
                  v-model="sortOption"
                  :options="sortOptions"
                  option-attribute="label"
                  value-attribute="value"
                  size="sm"
                  class="w-40 h-10 flex"
                  :ui="{
                    padding: {
                      sm: 'px-3 py-2',
                    },
                  }"
                  @update:modelValue="applyFilters"
                />
              </div>
              <div
                class="flex items-center border-l border-gray-200 pl-4 gap-2"
              >
                <div v-if="isAuthenticated" class="flex items-center gap-2">
                  <NuxtLink
                    to="/sale/my-posts"
                    class="whitespace-nowrap flex items-center gap-1 px-3 py-2 h-10 border border-primary-500 text-primary-600 rounded-md hover:bg-primary-50 transition-colors text-sm"
                  >
                    <UIcon name="i-heroicons-list-bullet" class="h-4 w-4" />
                    My Posts
                  </NuxtLink>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1 px-3 py-2 h-10 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors text-sm"
                  >
                    <UIcon name="i-heroicons-plus-circle" class="h-4 w-4" />
                    Post Sale Ad
                  </NuxtLink>
                </div>
                <div v-else>
                  <NuxtLink
                    to="/sale/my-posts?tab=post-sale"
                    class="whitespace-nowrap flex items-center gap-1 px-3 py-2 h-10 border border-primary-500 text-primary-600 rounded-md hover:bg-primary-50 transition-colors text-sm"
                  >
                    <UIcon name="i-heroicons-plus-circle" class="h-4 w-4" />
                    Post Sale Ad
                  </NuxtLink>
                </div>
              </div>
            </div>
            <!-- Mobile Sort Options - Separate row -->
            <div class="lg:hidden w-full">
              <div class="flex items-center gap-2">
                <!-- Mobile Filter Button -->
                <UButton
                  icon="i-heroicons-bars-3"
                  size="sm"
                  color="primary"
                  variant="soft"
                  class="flex items-center gap-1.5"
                  @click="toggleMobileSidebar"
                  aria-label="Open Filters Menu"
                >
                  <span class="text-xs font-medium">Menu</span>
                </UButton>
                <span class="text-sm text-gray-600">Sort by:</span>
                <USelect
                  v-model="sortOption"
                  :options="sortOptions"
                  option-attribute="label"
                  value-attribute="value"
                  size="sm"
                  class="w-36 h-8 flex compact-select"
                  :ui="{
                    padding: {
                      sm: 'px-2 py-1',
                    },
                    gap: {
                      sm: 'gap-1',
                    },
                    trailing: {
                      padding: {
                        sm: 'ps-1',
                      },
                    },
                  }"
                  @update:modelValue="applyFilters"
                />
              </div>
            </div>
          </div>

          <!-- Active Filters Display -->
          <div
            v-if="hasActiveFilters"
            class="bg-white p-3 rounded-lg shadow-sm mb-4"
          >
            <div class="flex flex-wrap items-center gap-2">
              <span class="text-sm text-gray-600">Filters:</span>

              <UBadge
                v-if="selectedCategory"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Category: {{ getCategoryName(selectedCategory) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearCategory"
                />
              </UBadge>

              <UBadge
                v-if="selectedSubcategory"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                {{ subcategoryTitle }}:
                {{ getSubcategoryName(selectedSubcategory) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearSubcategory"
                />
              </UBadge>

              <UBadge
                v-if="selectedDivision"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Division: {{ selectedDivision }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="handleClearLocation"
                />
              </UBadge>

              <UBadge
                v-if="priceRange.min || priceRange.max"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Price: {{ priceRange.min || "Any" }} -
                {{ priceRange.max || "Any" }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearPriceRange"
                />
              </UBadge>

              <UBadge
                v-if="selectedCondition"
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Condition: {{ getConditionLabel(selectedCondition) }}
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="selectedCondition = ''"
                />
              </UBadge>
              <UBadge
                v-if="searchQuery"
                color="emerald"
                variant="subtle"
                class="flex items-center gap-2"
              >
                <UIcon name="i-heroicons-magnifying-glass" class="h-3 w-3" />
                <span
                  >Search: "<strong>{{ searchQuery }}</strong
                  >"</span
                >
                <span v-if="listings?.length" class="text-xs opacity-75">
                  ({{ listings.length }}
                  {{ listings.length === 1 ? "result" : "results" }})
                </span>
                <UButton
                  color="emerald"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="clearSearch"
                />
              </UBadge>
            </div>
          </div>

          <!-- Category Tabs Listings Section -->
          <div
            class="bg-blue-50/50 rounded-lg border border-blue-100/50 p-1 mb-6"
          >
            <div
              class="flex flex-col sm:flex-row items-center justify-between my-4 gap-2"
            >
              <h2 class="text-lg font-medium text-gray-800">
                {{ categoryBrowserHeading }}
              </h2>
            </div>

            <!-- Category Posts Grid -->
            <div v-if="loading" class="py-8 text-center">
              <UIcon
                name="i-heroicons-arrow-path"
                class="animate-spin h-6 w-6 mx-auto text-blue-500"
              />
              <p class="mt-2 text-gray-600 text-sm">Loading listings...</p>
            </div>
            <div v-else-if="!listings?.length" class="py-8 text-center">
              <div class="flex flex-col items-center">
                <UIcon
                  :name="
                    searchQuery
                      ? 'i-heroicons-magnifying-glass'
                      : 'i-heroicons-square-3-stack-3d'
                  "
                  class="h-12 w-12 text-gray-400 mb-3"
                />
                <h3 class="text-lg font-medium text-gray-800 mb-2">
                  {{
                    searchQuery
                      ? "No search results found"
                      : "No listings found"
                  }}
                </h3>
                <p class="text-gray-600 text-sm max-w-md">
                  <span v-if="searchQuery">
                    No posts found matching "<strong>{{ searchQuery }}</strong
                    >". Try using different keywords or check the spelling.
                  </span>
                  <span v-else>
                    No listings found in this category. Try selecting a
                    different category or adjusting your filters.
                  </span>
                </p>
                <div v-if="searchQuery" class="mt-4">
                  <UButton
                    color="primary"
                    variant="soft"
                    @click="clearSearch"
                    size="sm"
                  >
                    Clear search and browse all listings
                  </UButton>
                </div>
              </div>
            </div>
            <div
              v-else
              class="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 xl:grid-cols-3 gap-2 w-full"
            >
              <NuxtLink
                v-for="(post, i) in listings"
                :key="`post-${i}`"
                :to="`/sale/${post.slug}`"
                class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-all duration-200 group w-full max-w-full"
                ><!-- Image -->
                <div
                  class="relative aspect-square w-full overflow-hidden bg-gray-100"
                >
                  <div
                    v-if="
                      !getListingImage(post) ||
                      getListingImage(post).includes('placeholder')
                    "
                    class="absolute inset-0 bg-gradient-to-br from-gray-100 to-gray-200 flex flex-col items-center justify-center p-2"
                  >
                    <div class="bg-white/90 rounded-full p-2 mb-1">
                      <UIcon
                        name="i-heroicons-photo"
                        class="h-4 w-4 sm:h-5 sm:w-5 text-gray-400"
                      />
                    </div>
                    <p class="text-gray-500 text-xs text-center">No Photo</p>
                  </div>
                  <img
                    v-else
                    :src="getListingImage(post)"
                    :alt="post?.title || `Image`"
                    class="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                </div>
                <!-- Price -->
                <div class="pt-2 border-t border-gray-100">
                  <div class="flex items-center justify-between px-2">
                    <p class="text-green-700 font-medium">
                      <span v-if="post.negotiable && !post.price"
                        >Negotiable</span
                      >
                      <span v-else-if="post.price"
                        >৳{{ formatPrice(post.price) }}</span
                      >
                      <span v-else>Contact for Price</span>
                    </p>
                    <p class="text-xs text-gray-600">
                      {{ formatDate(post.created_at) }}
                    </p>
                  </div>
                </div>
                <!-- Title and Location -->
                <div class="p-2">
                  <div
                    class="text-gray-600 text-sm font-semibold line-clamp-2"
                    v-html="
                      highlightSearchTerm(
                        capitalizeTitle(post?.title) || 'Post title',
                        searchQuery
                      )
                    "
                  ></div>
                  <div class="flex items-start mt-1 text-xs text-gray-600">
                    <UIcon
                      name="i-heroicons-map-pin"
                      class="h-3 w-3 mr-1 mt-0.5 flex-shrink-0 text-gray-600"
                    />
                    {{
                      post?.division && post?.district && post?.area
                        ? `${post?.division}, ${post?.district}, ${post?.area}`
                        : `All Over Bangladesh`
                    }}
                  </div>
                </div>
              </NuxtLink>
            </div>
            <!-- Load More Button -->
            <div
              v-if="hasMoreListings && !loading"
              class="flex justify-center mt-8"
            >
              <button
                @click="loadMorePosts"
                :disabled="isLoadingMore"
                class="text-emerald-600 hover:text-emerald-700 disabled:text-gray-400 font-medium transition-colors duration-200 flex items-center gap-2 hover:underline"
              >
                <UIcon
                  v-if="isLoadingMore"
                  name="i-heroicons-arrow-path"
                  class="animate-spin h-4 w-4"
                />
                <span v-if="isLoadingMore">Loading more...</span>
                <span v-else>See More</span>
              </button>
            </div>

            <!-- All Posts Loaded Message -->
            <div
              v-if="!hasMoreListings && listings.length > 0 && !loading"
              class="text-center py-8"
            >
              <div class="flex flex-col items-center justify-center">
                <div
                  class="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mb-4"
                >
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="h-8 w-8 text-green-600"
                  />
                </div>
                <h3 class="text-lg font-medium text-gray-800 mb-1">
                  All posts loaded!
                </h3>
                <p class="text-gray-600 text-sm">
                  You've seen all {{ totalListingsCount }} available listings
                </p>
              </div>
            </div>
          </div>

          <!-- Recent Listings Section -->
          <div
            class="bg-amber-50/40 rounded-lg border border-dashed border-amber-200 p-3 mb-6"
          >
            <div class="mb-4">
              <h2 class="text-lg font-medium text-amber-700 flex items-center">
                <UIcon name="i-heroicons-clock" class="mr-2 h-5 w-5" />
                Recent Listings
              </h2>
            </div>
            <!-- Recent Listings Horizontal Scroll -->
            <div class="overflow-x-auto scrollbar-hide pb-4 -mx-1 px-1">
              <div class="flex gap-4 min-w-max">
                <NuxtLink
                  v-for="(listing, i) in recentListings.slice(0, 5)"
                  :key="`listing-${i}+${i}`"
                  :to="`/sale/${listing.slug}`"
                  class="flex-shrink-0 w-64 bg-white rounded-lg shadow-sm border border-amber-100 overflow-hidden hover:shadow-sm transition-shadow group"
                >
                  <div class="relative h-36 overflow-hidden">
                    <img
                      :src="getListingImage(listing)"
                      :alt="listing?.title || `Image`"
                      class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                    <div class="absolute top-2 right-2">
                      <span
                        class="bg-white/90 text-amber-700 text-xs px-2 py-0.5 rounded-full shadow-sm font-medium"
                      >
                        {{ getCategoryName(listing.category) }}
                      </span>
                    </div>
                  </div>
                  <div class="p-3">
                    <h3
                      class="font-medium text-gray-800 line-clamp-1 group-hover:text-amber-700"
                    >
                      {{ capitalizeTitle(listing?.title) || `Title` }}
                    </h3>

                    <div
                      class="flex items-start mt-1 mb-2 text-xs text-gray-600"
                    >
                      <UIcon
                        name="i-heroicons-map-pin"
                        class="h-3 w-3 mr-1 mt-0.5 flex-shrink-0 text-gray-600"
                      />
                      {{
                        post?.division && post?.district && post?.area
                          ? `${post?.division}, ${post?.district}, ${post?.area}`
                          : `All Over Bangladesh`
                      }}
                    </div>

                    <div class="flex items-center justify-between mt-1.5">
                      <p class="text-amber-700 font-medium text-sm">
                        <span v-if="listing.price"
                          >৳{{ formatPrice(listing.price) }}</span
                        >
                        <span v-else>Negotiable</span>
                      </p>
                      <p class="text-xs text-gray-600">
                        {{ formatDate(listing.created_at) }}
                      </p>
                    </div>
                  </div>
                </NuxtLink>
              </div>
            </div>
          </div>
          <div
            v-if="recentListingsLoading"
            class="py-12 text-center bg-white rounded-lg shadow-sm"
          >
            <UIcon
              name="i-heroicons-arrow-path"
              class="animate-spin h-8 w-8 mx-auto text-amber-500"
            />
            <p class="mt-2 text-gray-600 text-sm">Loading recent listings...</p>
          </div>
          <!-- Enhanced Empty State with Professional Design --><!-- Enhanced Tips & Safety Guide -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-12">
            <!-- Smart Buying Tips -->
            <div
              class="group relative overflow-hidden bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl border border-blue-200/50 shadow-sm hover:shadow-sm transition-all duration-300"
            >
              <!-- Background Pattern -->
              <div
                class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-blue-400/10 to-indigo-400/10 rounded-full -translate-y-16 translate-x-16"
              ></div>

              <div class="relative z-10 p-8">
                <div class="flex items-start mb-6">
                  <div
                    class="bg-gradient-to-br from-blue-500 to-indigo-600 p-3 rounded-xl shadow-sm mr-4 group-hover:scale-110 transition-transform duration-300"
                  >
                    <UIcon
                      name="i-heroicons-light-bulb"
                      class="h-8 w-8 text-white"
                    />
                  </div>
                  <div>
                    <h3 class="text-xl font-bold text-blue-900 mb-2">
                      Smart Buying Tips
                    </h3>
                    <p class="text-blue-700/80 text-sm">
                      Make informed purchases with confidence
                    </p>
                  </div>
                </div>

                <div class="space-y-4">
                  <div class="flex items-start group/item">
                    <div
                      class="bg-blue-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-eye"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Inspect Before You Buy
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Always examine items thoroughly in person before making
                        payment
                      </p>
                    </div>
                  </div>

                  <div class="flex items-start group/item">
                    <div
                      class="bg-blue-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-map-pin"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Meet in Public Places
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Choose safe, well-lit locations for transactions
                      </p>
                    </div>
                  </div>

                  <div class="flex items-start group/item">
                    <div
                      class="bg-blue-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-document-check"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Verify Authenticity
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Check documentation and authenticity before purchase
                      </p>
                    </div>
                  </div>

                  <div class="flex items-start group/item">
                    <div
                      class="bg-blue-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-scale"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Compare Market Prices
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Research similar listings to ensure fair pricing
                      </p>
                    </div>
                  </div>
                </div>

                <div class="mt-6 pt-4 border-t border-blue-200/50">
                  <NuxtLink
                    to="/contact-us"
                    class="inline-flex items-center text-blue-600 hover:text-blue-700 font-medium text-sm group/link"
                  >
                    Complete Buyer's Guide
                    <UIcon
                      name="i-heroicons-arrow-right"
                      class="ml-2 h-4 w-4 group-hover/link:translate-x-1 transition-transform duration-200"
                    />
                  </NuxtLink>
                </div>
              </div>
            </div>

            <!-- Security & Safety -->
            <div
              class="group relative overflow-hidden bg-gradient-to-br from-emerald-50 to-green-50 rounded-2xl border border-emerald-200/50 shadow-sm hover:shadow-sm transition-all duration-300"
            >
              <!-- Background Pattern -->
              <div
                class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-emerald-400/10 to-green-400/10 rounded-full -translate-y-16 translate-x-16"
              ></div>

              <div class="relative z-10 p-8">
                <div class="flex items-start mb-6">
                  <div
                    class="bg-gradient-to-br from-emerald-500 to-green-600 p-3 rounded-xl shadow-sm mr-4 group-hover:scale-110 transition-transform duration-300"
                  >
                    <UIcon
                      name="i-heroicons-shield-check"
                      class="h-8 w-8 text-white"
                    />
                  </div>
                  <div>
                    <h3 class="text-xl font-bold text-emerald-900 mb-2">
                      Security & Safety
                    </h3>
                    <p class="text-emerald-700/80 text-sm">
                      Stay protected while shopping online
                    </p>
                  </div>
                </div>

                <div class="space-y-4">
                  <div class="flex items-start group/item">
                    <div
                      class="bg-emerald-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-lock-closed"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Protect Personal Info
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Never share banking details or personal financial
                        information
                      </p>
                    </div>
                  </div>

                  <div class="flex items-start group/item">
                    <div
                      class="bg-emerald-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-exclamation-triangle"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Spot Red Flags
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Be cautious of deals that seem unrealistically good
                      </p>
                    </div>
                  </div>

                  <div class="flex items-start group/item">
                    <div
                      class="bg-emerald-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-chat-bubble-left-ellipsis"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Use Platform Messaging
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        Keep communications on our platform for better security
                      </p>
                    </div>
                  </div>

                  <div class="flex items-start group/item">
                    <div
                      class="bg-emerald-500 rounded-full p-2 flex mr-3 mt-0.5 group-hover/item:scale-110 transition-transform duration-200"
                    >
                      <UIcon
                        name="i-heroicons-user-group"
                        class="h-3 w-3 text-white"
                      />
                    </div>
                    <div>
                      <p class="text-gray-800 font-medium text-sm">
                        Trust Your Instincts
                      </p>
                      <p class="text-gray-600 text-xs mt-1">
                        If something feels wrong, don't hesitate to walk away
                      </p>
                    </div>
                  </div>
                </div>

                <div class="mt-6 pt-4 border-t border-emerald-200/50">
                  <NuxtLink
                    to="/contact-us"
                    class="inline-flex items-center text-emerald-600 hover:text-emerald-700 font-medium text-sm group/link"
                  >
                    Complete Safety Guide
                    <UIcon
                      name="i-heroicons-arrow-right"
                      class="ml-2 h-4 w-4 group-hover/link:translate-x-1 transition-transform duration-200"
                    />
                  </NuxtLink>
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

const { user, isAuthenticated } = useAuth();
const { query } = useRoute();

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
    if (selectedDivision.value)
      params.append("division", selectedDivision.value);
    if (selectedDistrict.value)
      params.append("district", selectedDistrict.value);
    if (selectedArea.value) params.append("area", selectedArea.value);

    // Sort
    const sortMapping = {
      newest: "-created_at",
      oldest: "created_at",
      price_low: "price",
      price_high: "-price",
      most_viewed: "-views",
    };
    params.append("sort", sortMapping[sortOption.value] || "-created_at"); // Get data from API
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
</style>
