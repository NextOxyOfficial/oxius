<template>
  <div class="bg-gray-100 min-h-screen">
    <!-- Top Navigation Bar with Search and Post Button -->
    <div class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
      <CommonGeoSelector />
      <UContainer class="py-3">
        <div class="location-breadcrumb relative my-3 overflow-hidden">
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
                class="relative z-10 flex items-center justify-between p-3 rounded-lg border border-primary-100"
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
                @click="clearLocation"
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
        <UButtonGroup size="md" class="flex-1 flex md:hidden md:w-2/4">
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="md"
            color="white"
            :trailing="false"
            placeholder="Search..."
            v-model="form.title"
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
            label="Search"
            @click="filterSearch"
            class="sm:h-10 max-sm:!text-base w-24 justify-center"
            :ui="{
              padding: {
                md: 'sm:py-2.5',
              },
            }"
          />
        </UButtonGroup>
      </UContainer>
    </div>
    <UContainer class="py-6">
      <!-- Overlay for mobile -->
      <div
        v-if="isMobileFilterOpen"
        class="fixed inset-0 bg-black bg-opacity-60 z-40 lg:hidden"
        @click="toggleMobileSidebar"
      ></div>

      <div class="flex flex-col lg:flex-row gap-6">
        <!-- Sale Sidebar Component -->
        <SaleSidebar
          @open-add-post-modal="openPostSaleModal"
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
        <div class="flex-1 order-1 lg:order-2">
          <!-- Sorting & View Options -->
          <div
            class="bg-white p-4 rounded-lg shadow-sm mb-4 flex flex-wrap justify-between items-center gap-4"
          >
            <div class="flex items-center gap-3">
              <!-- Mobile Filter Button -->
              <UButton
                icon="i-heroicons-bars-3"
                size="sm"
                color="primary"
                variant="soft"
                class="lg:hidden flex items-center gap-1.5"
                @click="toggleMobileSidebar"
                aria-label="Open Filters Menu"
              >
                <span class="text-xs font-medium">Menu</span>
              </UButton>
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
            <div class="flex gap-6 items-center">
              <div class="flex items-center gap-2">
                <span class="text-sm text-gray-600">Sort by:</span>
                <USelect
                  v-model="sortOption"
                  :options="sortOptions"
                  option-attribute="label"
                  value-attribute="value"
                  size="sm"
                  class="w-40"
                  @update:modelValue="applyFilters"
                />
              </div>
              <div
                class="flex items-center border-l border-gray-200 pl-4 gap-2"
              >
                <UButton
                  color="primary"
                  variant="outline"
                  @click="openPostSaleModal"
                  class="whitespace-nowrap flex items-center gap-1"
                >
                  <UIcon name="i-heroicons-plus-circle" />
                  Post Ad
                </UButton>
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
                  @click="clearLocation"
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
                color="gray"
                variant="subtle"
                class="flex items-center gap-1"
              >
                Search: "{{ searchQuery }}"
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="-mr-1"
                  @click="searchQuery = ''"
                />
              </UBadge>
            </div>
          </div>

          <!-- Category Tabs Listings Section -->
          <div
            class="bg-blue-50/50 rounded-lg border border-blue-100/50 p-1 mb-6"
          >
            <div
              class="flex flex-col sm:flex-row items-center justify-between my-2 gap-2"
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
              <p class="text-gray-600">No listings found in this category</p>
            </div>
            <div
              v-else
              class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2"
            >
              <NuxtLink
                v-for="(post, i) in listings"
                :key="`post-${i}`"
                :to="`/sale/${post.slug}`"
                class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden hover:shadow transition-shadow group"
              >
                <!-- Image -->
                <div class="relative aspect-square overflow-hidden">
                  <img
                    :src="getListingImage(post)"
                    :alt="post?.title || `Image`"
                    class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                  <div class="absolute bottom-0 left-0 w-full p-2">
                    <div
                      class="text-gray-600 text-sm font-semibold line-clamp-2"
                    >
                      {{ post?.title || `Post title` }}
                    </div>
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
                  </div>
                </div>

                <!-- Price -->
                <div class="p-2 border-t border-gray-100">
                  <div class="flex items-center justify-between">
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
              </NuxtLink>
            </div>
            <!-- Pagination Controls without Upagination component -->
            <div class="flex justify-center mt-6" v-if="totalPages > 1">
              <ul class="inline-flex items-center space-x-1">
                <!-- Previous Button -->
                <li>
                  <button
                    @click="goToPage(currentPage - 1)"
                    :disabled="currentPage === 1"
                    class="px-3 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-50"
                  >
                    ‹
                  </button>
                </li>

                <!-- Visible Page Numbers -->
                <li v-for="page in visiblePages" :key="page">
                  <button
                    @click="goToPage(page)"
                    :class="[
                      'px-3 py-1 rounded-md border',
                      currentPage === page
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'border-gray-300 text-gray-800 hover:bg-gray-100',
                    ]"
                  >
                    {{ page }}
                  </button>
                </li>

                <!-- Dots -->
                <li v-if="shouldShowDots">
                  <span class="px-2">...</span>
                </li>

                <!-- Last Page -->
                <li v-if="totalPages > 5">
                  <button
                    @click="goToPage(totalPages)"
                    :class="[
                      'px-3 py-1 rounded-md border',
                      currentPage === totalPages
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'border-gray-300 text-gray-800 hover:bg-gray-100',
                    ]"
                  >
                    {{ totalPages }}
                  </button>
                </li>

                <!-- Next Button -->
                <li>
                  <button
                    @click="goToPage(currentPage + 1)"
                    :disabled="currentPage === totalPages"
                    class="px-3 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-50"
                  >
                    ›
                  </button>
                </li>
              </ul>
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
            <div class="overflow-x-auto pb-4 -mx-1 px-1">
              <div class="flex gap-4 flex-wrap">
                <NuxtLink
                  v-for="(listing, i) in recentListings"
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
                      {{ listing?.title || `Title` }}
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

          <!-- Empty State -->
          <div
            v-else-if="recentListings?.length === 0"
            class="py-12 flex flex-col items-center justify-center bg-white rounded-lg shadow-sm"
          >
            <UIcon
              name="i-heroicons-face-frown"
              class="h-16 w-16 text-gray-400"
            />
            <h3 class="mt-2 text-lg font-medium text-gray-800">
              No recent listings found
            </h3>
            <p class="mt-1 text-gray-600 max-w-sm text-center">
              Check back soon for new listings.
            </p>
          </div>

          <!-- Buyer Tips & Safety Guide -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
            <!-- Buyer Tips -->
            <div class="bg-blue-50/60 p-6 rounded-lg border border-blue-100">
              <div class="flex items-start">
                <div class="bg-blue-100 p-2 rounded-lg mr-4">
                  <UIcon
                    name="i-heroicons-light-bulb"
                    class="h-7 w-7 text-blue-600"
                  />
                </div>
                <div>
                  <h3 class="text-lg font-medium text-blue-800 mb-2">
                    Buyer Tips
                  </h3>
                  <ul class="space-y-2 text-sm text-gray-800">
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-blue-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Always inspect items in person before purchasing</span
                      >
                    </li>
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-blue-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Meet in a public place for safety when possible</span
                      >
                    </li>
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-blue-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Verify product authenticity with proper
                        documentation</span
                      >
                    </li>
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-blue-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Compare prices across multiple listings before
                        deciding</span
                      >
                    </li>
                  </ul>
                  <UButton
                    color="blue"
                    variant="link"
                    class="mt-3 text-sm font-medium"
                    to="/help/buying-guide"
                  >
                    Read full buying guide
                    <UIcon
                      name="i-heroicons-arrow-right"
                      class="ml-1 w-4 h-4"
                    />
                  </UButton>
                </div>
              </div>
            </div>

            <!-- Safety Guide -->
            <div class="bg-green-50/60 p-6 rounded-lg border border-green-100">
              <div class="flex items-start">
                <div class="bg-green-100 p-2 rounded-lg mr-4">
                  <UIcon
                    name="i-heroicons-shield-check"
                    class="h-7 w-7 text-green-600"
                  />
                </div>
                <div>
                  <h3 class="text-lg font-medium text-green-800 mb-2">
                    Safety Guide
                  </h3>
                  <ul class="space-y-2 text-sm text-gray-800">
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-green-500 mr-2 flex-shrink-0"
                      />
                      <span>Avoid sharing personal financial information</span>
                    </li>
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-green-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Be cautious of deals that seem too good to be
                        true</span
                      >
                    </li>
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-green-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Use secure payment methods, avoid wire transfers</span
                      >
                    </li>
                    <li class="flex items-start">
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-5 w-5 text-green-500 mr-2 flex-shrink-0"
                      />
                      <span
                        >Report suspicious activity to our support team</span
                      >
                    </li>
                  </ul>
                  <UButton
                    color="green"
                    variant="link"
                    class="mt-3 text-sm font-medium"
                    to="/help/safety"
                  >
                    Learn more about safety
                    <UIcon
                      name="i-heroicons-arrow-right"
                      class="ml-1 w-4 h-4"
                    />
                  </UButton>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
    <!-- Post Sale Modal -->
    <div
      v-if="showPostSaleModal"
      class="fixed inset-0 z-50 overflow-y-auto pt-16"
    >
      <!-- Added pt-16 for header spacing -->
      <div
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 transition-opacity"
          @click="closePostSaleModal"
        >
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div
          v-if="user?.user"
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-3xl w-full"
        >
          <div class="bg-white px-2 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <div
                  class="flex justify-between items-center border-b pb-3 mb-4"
                >
                  <h3 class="text-lg leading-6 font-medium text-gray-800">
                    Post a Sale
                  </h3>
                  <button
                    type="button"
                    class="text-gray-600 hover:text-gray-600"
                    @click="closePostSaleModal"
                  >
                    <Icon name="heroicons:x-mark" size="24px" />
                  </button>
                </div>
                <SalePostSale :categories="categories" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, defineAsyncComponent } from "vue";

import { useApi } from "~/composables/useApi";
import SaleSidebar from "~/components/sale/SaleSidebar.vue";

const { user } = useAuth();
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

const showPostSaleModal = ref(false);

const currentPage = ref(1);
const totalPages = ref(0);

const location = useCookie("location");
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

// Function to toggle mobile sidebar visibility
function toggleMobileSidebar() {
  isMobileFilterOpen.value = !isMobileFilterOpen.value;
}

// Function to clear location and reload page
function clearLocation() {
  location.value = null;
  window.location.reload();
}

// Function to handle search form submission
async function filterSearch() {
  isLoading.value = true;
  searchQuery.value = form.value.title || "";

  // Apply the search query filter
  await loadPosts(1);
  isLoading.value = false;
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

// Load posts based on current filters - modify the API path and add fallback data
async function loadPosts(page = 1) {
  loading.value = true;

  try {
    // Build query parameters
    const params = new URLSearchParams();

    // Add filters
    if (selectedCategory.value)
      params.append("category", selectedCategory.value.toString());
    if (selectedSubcategory.value)
      params.append("subcategory", selectedSubcategory.value.toString());
    if (searchQuery.value) params.append("search", searchQuery.value);
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
    if (page) params.append("page", page.toString());

    // Sort
    const sortMapping = {
      newest: "-created_at",
      oldest: "created_at",
      price_low: "price",
      price_high: "-price",
      most_viewed: "-views",
    };
    params.append("sort", sortMapping[sortOption.value] || "-created_at"); // Get data from API
    const response = await get(
      `${API_ENDPOINTS.LISTINGS}?${params.toString()}`
    );

    if (response && response.data) {
      if (response.data.results) {
        // Paginated response
        listings.value = mapListingsData(response.data.results);
        totalPages.value = Math.ceil(
          +response.data.count / +response.data.results.length
        );
      } else if (Array.isArray(response.data)) {
        // Array response
        listings.value = mapListingsData(response.data);
      }
    } else {
      listings.value = [];
    }
  } catch (error) {
    console.error("Error loading listings:", error);
    listings.value = [];
  } finally {
    loading.value = false;
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

  return "https://via.placeholder.com/300x200?text=No+Image";
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
  await loadPosts(1);
}

async function clearCategory() {
  selectedCategory.value = null;
  selectedSubcategory.value = null;
  await loadPosts(1);
}

async function clearSubcategory() {
  selectedSubcategory.value = null;
  await loadPosts(1);
}

async function clearPriceRange() {
  priceRange.value.min = "";
  priceRange.value.max = "";
  await loadPosts(1);
}

function applyFilters() {
  loadPosts(1);
}

function onPageChange(page) {
  loadPosts(page);
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

const visiblePages = computed(() => {
  const pages = [];

  if (totalPages.value <= 6) {
    // Show all if few pages
    for (let i = 1; i <= totalPages.value; i++) pages.push(i);
  } else {
    const maxVisible = 5;

    let start = currentPage.value;
    if (currentPage.value <= 3) start = 1;
    else if (currentPage.value > totalPages.value - 5)
      start = totalPages.value - 5;

    for (let i = start; i < start + maxVisible && i < totalPages; i++) {
      pages.push(i);
    }
  }

  return pages;
});

const shouldShowDots = computed(() => {
  return (
    totalPages.value > 6 && visiblePages.value.at(-1) < totalPages.value - 1
  );
});

async function goToPage(page) {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
    loadPosts(currentPage.value);
  }
}

const openPostSaleModal = () => {
  showPostSaleModal.value = true;
};

const closePostSaleModal = () => {
  showPostSaleModal.value = false;
};
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
</style>
