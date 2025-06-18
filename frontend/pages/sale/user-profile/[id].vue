<template>
  <div class="max-w-6xl mx-auto px-1 py-3">
    <!-- Seller Profile Header -->
    <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
      <div
        class="relative h-40 bg-gradient-to-r from-emerald-600 to-emerald-800 overflow-hidden"
        :style="
          seller.image
            ? `background-image: linear-gradient(rgba(0, 0, 0, 0.4), rgba(0, 0, 0, 0.6)), url('${seller.image}'); background-size: cover; background-position: center;`
            : ''
        "
      >
        <!-- Profile Actions -->
        <div class="absolute top-4 right-4 flex space-x-2 z-10">
          <button
            class="bg-white/90 hover:bg-white text-gray-800 px-3 py-1.5 rounded-md text-sm transition-colors duration-200 flex items-center"
            @click="handleShare"
          >
            <Share2 class="h-4 w-4 mr-1.5" />
            Share
          </button>
          <button
            class="bg-white/90 hover:bg-white text-gray-800 px-3 py-1.5 rounded-md text-sm transition-colors duration-200 flex items-center"
            @click="toggleReportDialog"
          >
            <Flag class="h-4 w-4 mr-1.5" />
            Report
          </button>
        </div>
      </div>
      <div class="p-2 relative">
        <!-- Profile Avatar -->
        <div
          class="relative -top-8 left-6 h-24 w-24 rounded-full border-4 border-white bg-white overflow-hidden cursor-pointer"
          @click="openProfilePhotoModal"
        >
          <img
            :src="seller.image || '/static/frontend/images/placeholder.jpg'"
            :alt="seller.name"
            class="h-full w-full object-cover"
          />
        </div>

        <!-- Profile Info -->
        <div
          class="flex flex-col md:flex-row md:items-end justify-between -mt-4"
        >
          <div>
            <div class="flex items-center">
              <h1 class="text-2xl font-bold text-gray-800">
                {{ seller.name }}
              </h1>
              <div class="flex items-center space-x-2 ml-3">
                <UIcon
                  v-if="seller.kyc"
                  name="mdi:check-decagram"
                  class="w-5 h-5 text-blue-600"
                  title="Verified"
                />
                <div class="inline-flex" v-if="seller.is_pro">
                  <span
                    class="px-2 py-1 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-sm font-medium shadow-sm"
                    title="Pro Member"
                  >
                    <div class="flex items-center gap-1">
                      <UIcon name="i-heroicons-shield-check" class="size-4" />
                      <span class="text-xs">Pro</span>
                    </div>
                  </span>
                </div>
              </div>
            </div>
            <p class="text-gray-600 text-sm mt-1">
              Member since {{ formatDate(seller.date_joined) }}
            </p>

            <div class="flex items-center mt-3 space-x-4">
              <div class="flex items-center">
                <Tag class="h-4 w-4 text-emerald-600 mr-1.5" />
                <span class="text-sm text-gray-600"
                  >{{ seller.sale_post_count }} Listings</span
                >
              </div>
              <div class="flex items-center">
                <MapPin class="h-4 w-4 text-emerald-600 mr-1.5" />
                <span class="text-sm text-gray-600">{{ seller.address }}</span>
              </div>
            </div>
          </div>
          <div class="mt-4 md:mt-0">
            <button
              class="border border-gray-200 hover:bg-gray-50 text-gray-800 px-4 py-2 rounded-md text-sm transition-colors duration-200 flex items-center"
              @click="contactSeller"
            >
              <Phone class="h-4 w-4 mr-2 text-emerald-600" />
              Contact Seller
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Seller Details Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-3">
      <!-- About & Contact - 1 column on large screens -->
      <div class="lg:col-span-1 space-y-3">
        <!-- About Section -->
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div class="p-5">
            <h2 class="text-lg font-bold text-gray-800 flex items-center mb-4">
              <User class="h-5 w-5 mr-2 text-emerald-600" />
              About
            </h2>
            <p class="text-gray-600 text-sm">
              {{ seller?.about }}
            </p>
          </div>
        </div>

        <!-- Contact Information -->
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div class="p-5">
            <h2 class="text-lg font-bold text-gray-800 flex items-center mb-4">
              <Phone class="h-5 w-5 mr-2 text-emerald-600" />
              Contact Information
            </h2>

            <div class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Phone</span>
                <div class="flex items-center">
                  <span class="font-medium text-sm text-gray-800 mr-2">
                    {{
                      showPhone ? seller.phone : maskPhoneNumber(seller.phone)
                    }}
                  </span>
                  <button
                    class="text-emerald-600 hover:text-emerald-700"
                    @click="toggleShowPhone"
                  >
                    <component :is="showPhone ? EyeOff : Eye" class="h-4 w-4" />
                  </button>
                </div>
              </div>

              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Email</span>
                <span class="font-medium text-sm text-gray-800">{{
                  seller.email
                }}</span>
              </div>

              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Location</span>
                <span class="font-medium text-sm text-gray-800">{{
                  seller.address
                }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Seller Products - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div class="py-5 px-1 sm:px-4">
            <div
              class="max-sm:flex-block items-center justify-between max-sm:mb-4"
            >
              <h2
                class="text-lg mb-4 font-bold text-gray-800 flex items-center"
              >
                <ShoppingBag class="h-5 w-5 mr-2 text-emerald-600" />
                {{ seller.name }}'s Listings ({{ seller.sale_post_count }})
              </h2>

              <div
                class="flex items-center sm:mb-2 max-sm:justify-center space-x-2"
              >
                <select
                  v-model="sortOption"
                  class="text-sm border border-gray-200 rounded-md px-2 py-1.5 text-gray-600 bg-white"
                >
                  <option value="recent">Most Recent</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="popular">Most Popular</option>
                </select>

                <div
                  class="flex border border-gray-200 rounded-md overflow-hidden"
                >                  <button
                    :class="`px-3 py-3 ${
                      viewMode === 'grid'
                        ? 'bg-emerald-50 text-emerald-600'
                        : 'bg-white text-gray-600 hover:bg-gray-50'
                    } border-r border-gray-200`"
                    @click="viewMode = 'grid'"
                  >
                    <LayoutGrid class="h-4 w-4" />
                  </button>                  <button
                    :class="`px-3 py-3 ${
                      viewMode === 'list'
                        ? 'bg-emerald-50 text-emerald-600'
                        : 'bg-white text-gray-600 hover:bg-gray-50'
                    }`"
                    @click="viewMode = 'list'"
                  >
                    <List class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
            <!-- Filter Bar -->
            <div
              class="flex flex-wrap items-center justify-center gap-2 mb-4 pb-4 border-b border-gray-100"
            >
              <span class="text-sm text-gray-600">Filter by:</span>

              <select
                v-model="categoryFilter"
                class="text-sm border border-gray-200 rounded-md px-2 py-1 text-gray-600 bg-white"
                @change="applyFilters"
              >
                <option value="">All Categories</option>
                <option
                  v-for="category in categories"
                  :key="category.id"
                  :value="category?.name"
                >
                  {{ category?.name }}
                </option>
              </select>

              <select
                v-model="conditionFilter"
                class="text-sm border border-gray-200 rounded-md px-2 py-1 text-gray-600 bg-white"
                @change="applyFilters"
              >
                <option value="">All Conditions</option>
                <option
                  v-for="condition in conditions"
                  :value="condition.value"
                  :key="condition.id"
                >
                  {{ condition.name }}
                </option>
              </select>

              <button
                class="ml-1 text-sm text-emerald-600 hover:text-emerald-700"
                @click="clearFilters"
                v-if="categoryFilter || conditionFilter"
              >
                Clear All Filters
              </button>
            </div>

            <!-- Active Filters Display -->
            <div
              v-if="categoryFilter || conditionFilter"
              class="flex flex-wrap items-center gap-2 mb-4"
            >
              <span class="text-xs text-gray-500">Active filters:</span>
              <span
                v-if="categoryFilter"
                class="inline-flex items-center px-2 py-1 text-xs bg-emerald-100 text-emerald-800 rounded-full"
              >
                Category: {{ categoryFilter }}
                <button
                  @click="clearCategoryFilter"
                  class="ml-1 text-emerald-600 hover:text-emerald-800"
                >
                  <X class="h-3 w-3" />
                </button>
              </span>
              <span
                v-if="conditionFilter"
                class="inline-flex items-center px-2 py-1 text-xs bg-emerald-100 text-emerald-800 rounded-full"
              >
                Condition: {{ getConditionName(conditionFilter) }}
                <button
                  @click="clearConditionFilter"
                  class="ml-1 text-emerald-600 hover:text-emerald-800"
                >
                  <X class="h-3 w-3" />
                </button>
              </span>
            </div>
            <!-- Grid View -->
            <div v-if="viewMode === 'grid'" class="grid grid-cols-2 gap-2">
              <div
                v-for="product in products"
                :key="product.id"
                class="bg-white rounded-lg overflow-hidden border border-gray-200"
              >
                <div
                  class="relative aspect-video cursor-pointer"
                  @click="navigateToPost(product.slug)"
                >
                  <div
                    v-if="!product.main_image"
                    class="absolute inset-0 w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex flex-col items-center justify-center group hover:from-gray-200 hover:to-gray-300 transition-all duration-300"
                  >
                    <div
                      class="bg-white/80 backdrop-blur-sm rounded-full p-3 mb-2 shadow-sm group-hover:shadow-md transition-all duration-300"
                    >
                      <ImageOff
                        class="h-8 w-8 text-gray-400 group-hover:text-gray-500 transition-colors duration-300"
                      />
                    </div>
                    <p
                      class="text-gray-500 text-xs font-medium group-hover:text-gray-600 transition-colors duration-300"
                    >
                      No Photo Uploaded
                    </p>
                  </div>
                  <img
                    v-else
                    :src="product.main_image"
                    :alt="product.title"
                    class="absolute inset-0 w-full h-full object-contain hover:scale-105 transition-transform duration-300"
                  />
                </div>
                <div class="p-2">
                  <h3 class="font-semibold text-gray-800 mb-1 line-clamp-2">
                    <NuxtLink
                      :to="`/sale/${product.slug}`"
                      class="hover:text-emerald-600 transition-colors"
                    >
                      {{ capitalizeTitle(product.title) }}
                    </NuxtLink>
                  </h3>
                  <div class="flex items-center justify-between mt-2">
                    <span class="font-bold text-emerald-700"
                      >৳{{
                        product.price
                          ? product.price.toLocaleString()
                          : "Contact for Price"
                      }}</span
                    >
                    <span class="text-sm text-gray-600">{{
                      formatDate(product.created_at)
                    }}</span>
                  </div>

                  <div class="flex items-center mt-3 text-sm text-gray-600">
                    <Tag class="h-3 w-3 mr-1" />
                    <span>{{ product.category_name }}</span>
                    <span class="mx-1">•</span>
                    <MapPin class="h-3 w-3 mr-1" />
                    <span>{{
                      product?.division && product?.district && product?.area
                        ? `${product?.division}, ${product?.district}, ${product?.area}`
                        : `All Over Bagnladesh`
                    }}</span>
                  </div>                  <div
                    class="flex justify-between items-center mt-3 pt-3 border-t border-gray-100"
                  >
                    <NuxtLink
                      :to="`/sale/${product.slug}`"
                      class="text-emerald-600 hover:text-emerald-700 text-sm flex items-center"
                      @click="handleButtonClick(`view_details_grid_${product.id}`)"
                    >
                      View Details
                      <div v-if="loadingButtons.has(`view_details_grid_${product.id}`)" class="dotted-spinner emerald ml-1"></div>
                      <ChevronRight v-else class="h-3 w-3 ml-1" />
                    </NuxtLink>
                  </div>
                </div>
              </div>
            </div>

            <!-- List View -->
            <div v-else class="space-y-4">
              <div
                v-for="product in products"
                :key="product.id"
                class="flex flex-col sm:flex-row bg-white rounded-lg overflow-hidden"
              >
                <div
                  class="relative sm:w-1/3 aspect-video sm:aspect-none cursor-pointer"
                  @click="navigateToPost(product.slug)"
                >
                  <div
                    v-if="!product.main_image"
                    class="absolute inset-0 w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex flex-col items-center justify-center group hover:from-gray-200 hover:to-gray-300 transition-all duration-300"
                  >
                    <div
                      class="bg-white/80 backdrop-blur-sm rounded-full p-4 mb-3 shadow-sm group-hover:shadow-md transition-all duration-300"
                    >
                      <ImageOff
                        class="h-10 w-10 text-gray-400 group-hover:text-gray-500 transition-colors duration-300"
                      />
                    </div>
                    <p
                      class="text-gray-500 text-sm font-medium group-hover:text-gray-600 transition-colors duration-300"
                    >
                      No Photo Uploaded
                    </p>
                  </div>
                  <img
                    v-else
                    :src="product.main_image"
                    :alt="product.title"
                    class="absolute inset-0 w-full h-full object-contain hover:scale-105 transition-transform duration-300"
                  />
                </div>

                <div class="p-2 sm:w-2/3 flex flex-col">
                  <h3 class="font-semibold text-gray-800 mb-1">
                    <NuxtLink
                      :to="`/sale/${product.slug}`"
                      class="hover:text-emerald-600 transition-colors"
                    >
                      {{ capitalizeTitle(product.title) }}
                    </NuxtLink>
                  </h3>
                  <div class="flex items-center justify-between mt-2">
                    <span class="font-bold text-emerald-700"
                      >৳{{
                        product.price
                          ? product.price.toLocaleString()
                          : "Contact for Price"
                      }}</span
                    >
                    <span class="text-sm text-gray-600">{{
                      formatDate(product.created_at)
                    }}</span>
                  </div>

                  <div class="flex items-center mt-3 text-sm text-gray-600">
                    <Tag class="h-3 w-3 mr-1" />
                    <span>{{ product.category }}</span>
                    <span class="mx-1">•</span>
                    <MapPin class="h-3 w-3 mr-1" />
                    <span>{{
                      product?.division && product?.district && product?.area
                        ? `${product?.division}, ${product?.district}, ${product?.area}`
                        : `All Over Bagnladesh`
                    }}</span>
                  </div>                  <div
                    class="text-sm text-gray-600 mt-2 line-clamp-2"
                    v-html="product.description || 'No description available.'"
                  ></div>
                  <div
                    class="flex justify-between items-center mt-auto pt-3 border-t border-gray-100"
                  >
                    <NuxtLink
                      :to="`/sale/${product.slug}`"
                      class="text-emerald-600 hover:text-emerald-700 text-sm flex items-center"
                      @click="handleButtonClick(`view_details_list_${product.id}`)"
                    >
                      View Details
                      <div v-if="loadingButtons.has(`view_details_list_${product.id}`)" class="dotted-spinner emerald ml-1"></div>
                      <ChevronRight v-else class="h-3 w-3 ml-1" />
                    </NuxtLink>
                  </div>
                </div>
              </div>
            </div>

            <!-- Loading State -->
            <div v-if="isLoading" class="py-8 text-center">
              <div
                class="mx-auto w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4 animate-pulse"
              >
                <div
                  class="w-8 h-8 border-2 border-emerald-600 border-t-transparent rounded-full animate-spin"
                ></div>
              </div>
              <p class="text-gray-600 text-sm">Loading products...</p>
            </div>

            <!-- Empty State -->
            <div v-else-if="products?.length === 0" class="py-8 text-center">
              <div
                class="mx-auto w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4"
              >
                <SearchX class="h-8 w-8 text-gray-400" />
              </div>
              <h3 class="text-gray-800 font-medium mb-1">No listings found</h3>
              <p class="text-gray-600 text-sm">
                Try adjusting your filters or check back later
              </p>
              <button
                class="mt-4 text-emerald-600 hover:text-emerald-700 text-sm"
                @click="clearFilters"
              >
                Clear all filters
              </button>
            </div>
            <!-- Pagination -->
            <div
              v-if="!isLoading && products?.length > 0"
              class="flex items-center justify-between mt-6 pt-4 border-t border-gray-100"
            >
              <button
                class="flex items-center text-sm text-gray-600 hover:text-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed"
                :disabled="currentPage === 1"
                @click="prevPage"
              >
                <ChevronLeft class="h-4 w-4 mr-1" />
                Previous
              </button>

              <div class="flex items-center space-x-1">
                <button
                  v-for="page in pages"
                  :key="page"
                  :class="`h-8 w-8 rounded-md flex items-center justify-center text-sm ${
                    currentPage === page
                      ? 'bg-emerald-600 text-white'
                      : 'hover:bg-gray-100 text-gray-600'
                  }`"
                  @click="goToPage(page)"
                >
                  {{ page }}
                </button>
              </div>

              <button
                class="flex items-center text-sm text-gray-600 hover:text-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed"
                :disabled="
                  pages?.length === 0 ? true : currentPage === pages?.length
                "
                @click="nextPage"
              >
                Next
                <ChevronRight class="h-4 w-4 ml-1" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Report Dialog -->
    <div
      v-if="showReportDialog"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeReportDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Report Seller</h3>
          <button
            @click="closeReportDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5">
          <p class="text-sm text-gray-600 mb-4">
            Please select a reason for reporting this seller:
          </p>

          <div class="space-y-2">
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="fake"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800"
                >Fake or misleading listings</span
              >
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="prohibited"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800"
                >Selling prohibited items</span
              >
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="offensive"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Offensive content</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="scam"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Scam or fraud</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="other"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-800">Other</span>
            </label>
          </div>

          <textarea
            v-if="reportReason === 'other'"
            v-model="reportDetails"
            placeholder="Please provide details about your report..."
            class="mt-4 w-full border border-gray-200 rounded-md p-2 text-sm text-gray-800 h-24 resize-none focus:outline-none focus:ring-1 focus:ring-emerald-500"
          ></textarea>

          <div class="mt-6 flex justify-end space-x-3">
            <button
              class="px-4 py-2 border border-gray-200 rounded-md text-sm text-gray-600 hover:bg-gray-50"
              @click="closeReportDialog"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="submitReport"
            >
              Submit Report
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Share Dialog -->
    <div
      v-if="showShareDialog"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeShareDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Share this profile</h3>
          <button
            @click="closeShareDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5" style="word-break: break-word">
          <div
            class="flex items-center space-x-2 overflow-hidden"
            style="word-break: break-word"
          >
            <div class="flex-1 overflow-hidden" style="word-break: break-word">
              <div
                class="flex items-center justify-between rounded-md border border-gray-200 px-3 py-2 overflow-hidden"
                style="word-break: break-word"
              >
                <span class="text-sm text-gray-600">{{ shareUrl }}</span>
              </div>
            </div>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="copyToClipboard"
            >
              <span class="flex items-center">
                <UIcon name="i-heroicons-clipboard" class="w-4 h-4 mr-1" />
                Copy
              </span>
            </button>
          </div>

          <div class="mt-5">
            <h4 class="text-sm font-medium mb-3 text-gray-800">Share via</h4>
            <div class="grid grid-cols-2 gap-3">
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('facebook')"
              >
                <span
                  class="w-5 h-5 bg-blue-600 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >f</span
                >
                Facebook
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('twitter')"
              >
                <span
                  class="w-5 h-5 bg-sky-500 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >t</span
                >
                Twitter
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('whatsapp')"
              >
                <span
                  class="w-5 h-5 bg-emerald-500 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >w</span
                >
                WhatsApp
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-800"
                @click="shareViaMedia('email')"
              >
                <span
                  class="w-5 h-5 bg-gray-700 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >@</span
                >
                Email
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Profile Photo Modal -->
    <MediaViewer
      v-if="showProfilePhotoModal"
      :activeMedia="profilePhotoMedia"
      :user="user"
      :profileMode="true"
      :profileUser="seller"
      @close-media="showProfilePhotoModal = false"
    />
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from "vue";
import MediaViewer from "~/components/business-network/MediaViewer.vue";
import {
  User,
  MapPin,
  Tag,
  Phone,
  Share2,
  Flag,
  CheckCircle,
  ChevronRight,
  ChevronLeft,
  Clock,
  ShoppingBag,
  Eye,
  EyeOff,
  LayoutGrid,
  List,
  X,
  SearchX,
  ImageOff,
} from "lucide-vue-next";

const { get } = useApi();
const { params } = useRoute();

// Import toast functionality for notifications
const toast = useToast();

// State variables
const showPhone = ref(false);
const viewMode = ref("list"); // Changed from 'grid' to 'list' to show list view by default
const sortOption = ref("recent");
const categoryFilter = ref("");
const conditionFilter = ref("");
const currentPage = ref(1);
const itemsPerPage = ref(10); // Display maximum of 10 posts per page
const showReportDialog = ref(false);
const showShareDialog = ref(false);
const reportReason = ref("");
const reportDetails = ref("");
const shareUrl = ref("");
const showProfilePhotoModal = ref(false);
const profilePhotoMedia = ref(null); // For MediaViewer
const totalPages = ref(0);

// Loading states for pagination
const isLoading = ref(false);
const pagination = ref(null);

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

// Watch route changes to clear loading states
watch(() => useRoute().fullPath, () => {
  loadingButtons.value.clear();
});

const seller = ref({});

async function getSellerDetails() {
  try {
    const response = await get(`/user/${params.id}/`);
    if (response.data) {
      seller.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching seller details:", error);
  }
}
await getSellerDetails();
// Sample products data with more items for pagination

const products = ref([]);

async function getProducts(page = 1) {
  try {
    // Set loading state
    isLoading.value = true;

    // Build query parameters
    const queryParams = new URLSearchParams();
    queryParams.append("page", page.toString());
    queryParams.append("page_size", itemsPerPage.value.toString());
    queryParams.append("seller", params.id);

    // Add filters if they exist
    if (categoryFilter.value) {
      // Find category by name and use its ID
      const category = categories.value.find(
        (cat) => cat.name === categoryFilter.value
      );
      if (category) {
        queryParams.append("category", category.id.toString());
      }
    }
    if (conditionFilter.value) {
      // Use the condition value directly
      queryParams.append("condition", conditionFilter.value);
    }

    // Add sorting
    const sortMapping = {
      recent: "-created_at",
      "price-low": "price",
      "price-high": "-price",
      popular: "-views",
    };
    queryParams.append(
      "ordering",
      sortMapping[sortOption.value] || "-created_at"
    );

    const response = await get(`/sale/posts/?${queryParams.toString()}`);

    if (response.data) {
      if ("results" in response.data) {
        // Paginated response
        pagination.value = {
          count: response.data.count,
          next: response.data.next,
          previous: response.data.previous,
        };

        // Replace products with current page results
        products.value = response.data.results;

        // Update pagination info
        totalPages.value = Math.ceil(response.data.count / itemsPerPage.value);
      } else if (Array.isArray(response.data)) {
        // Non-paginated response (fallback)
        products.value = response.data;
        totalPages.value = 1;
      }
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error",
      description: "Failed to load products. Please try again.",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoading.value = false;
  }
}

await getProducts();

const categories = ref([]);

async function getCategories() {
  try {
    const response = await get("/sale/categories/");

    if (response.data) {
      categories.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}

await getCategories();

const conditions = ref([]);

async function getConditions() {
  try {
    const response = await get("/sale/conditions/");

    if (response.data) {
      conditions.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching conditions:", error);
  }
}
await getConditions();

const pages = computed(() => {
  const pages = [];
  for (let i = 1; i <= totalPages.value; i++) {
    pages.push(i);
  }
  return pages;
});

// Contact seller function
const contactSeller = () => {
  if (seller.value?.phone) {
    window.open(`tel:${seller.value.phone}`, "_self");
  }
};

// Format date
const formatDate = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays <= 1) {
    return "Today";
  } else if (diffDays <= 2) {
    return "Yesterday";
  } else if (diffDays <= 7) {
    return `${diffDays} days ago`;
  } else {
    return new Intl.DateTimeFormat("en-US", {
      month: "short",
      day: "numeric",
    }).format(date);
  }
};

// Mask phone number
const maskPhoneNumber = (phone) => {
  return "XXXXXXX" + phone.slice(-3);
};

// Toggle phone visibility
const toggleShowPhone = () => {
  showPhone.value = !showPhone.value;
};

// Pagination methods
const prevPage = async () => {
  if (currentPage.value > 1) {
    currentPage.value--;
    await getProducts(currentPage.value);
  }
};

const nextPage = async () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++;
    await getProducts(currentPage.value);
  }
};

const goToPage = async (page) => {
  currentPage.value = page;
  await getProducts(currentPage.value);
};

// Clear filters and reload
const clearFilters = () => {
  categoryFilter.value = "";
  conditionFilter.value = "";
  currentPage.value = 1;
  getProducts(1);
};

// Individual filter clear functions
const clearCategoryFilter = () => {
  categoryFilter.value = "";
  applyFilters();
};

const clearConditionFilter = () => {
  conditionFilter.value = "";
  applyFilters();
};

// Apply filters function
const applyFilters = () => {
  currentPage.value = 1;
  getProducts(1);
};

// Get condition name by value
const getConditionName = (value) => {
  const condition = conditions.value.find((c) => c.value === value);
  return condition ? condition.name : value;
};

// Watch filters and sort option to reload data
watch([categoryFilter, conditionFilter, sortOption], () => {
  applyFilters();
});

// Report dialog methods
const toggleReportDialog = () => {
  showReportDialog.value = !showReportDialog.value;
  if (showReportDialog.value) {
    reportReason.value = "";
    reportDetails.value = "";
  }
};

const closeReportDialog = () => {
  showReportDialog.value = false;
};

const submitReport = () => {
  // In a real app, this would send the report to the server
  alert(
    `Report submitted. Reason: ${reportReason.value}${
      reportReason.value === "other" ? ", Details: " + reportDetails.value : ""
    }`
  );
  closeReportDialog();
};

// Share dialog methods
const handleShare = () => {
  showShareDialog.value = true;
  // Use the production domain for sharing
  const productionDomain = "https://adsyclub.com";
  const pathname = window.location.pathname;
  shareUrl.value = productionDomain + pathname;
};

const closeShareDialog = () => {
  showShareDialog.value = false;
};

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareUrl.value);
  // Show a toast message
  toast.add({
    title: "Link Copied!",
    description: "Profile link has been copied to clipboard",
    color: "green",
    icon: "i-heroicons-check-circle",
  });
};

const shareViaMedia = (platform) => {
  let url = "";
  const currentUrl = encodeURIComponent(shareUrl.value);
  const title = encodeURIComponent(`Check out ${seller.value?.name}'s profile`);

  switch (platform) {
    case "facebook":
      url = `https://www.facebook.com/sharer/sharer.php?u=${currentUrl}`;
      break;
    case "twitter":
      url = `https://twitter.com/intent/tweet?text=${title}&url=${currentUrl}`;
      break;
    case "whatsapp":
      url = `https://api.whatsapp.com/send?text=${title} ${currentUrl}`;
      break;
    case "email":
      url = `mailto:?subject=${title}&body=${currentUrl}`;
      break;
  }

  if (url) {
    window.open(url, "_blank");
  }

  closeShareDialog();
};

// Profile photo modal methods
const openProfilePhotoModal = () => {
  // Create a media object for the profile photo
  profilePhotoMedia.value = {
    image: seller.value?.image || "/placeholder.svg",
    type: "image",
    id: seller.value?.id || "profile",
  };

  showProfilePhotoModal.value = true;
};

// Function to capitalize first letter of title
const capitalizeTitle = (title) => {
  if (!title) return "";
  return title.charAt(0).toUpperCase() + title.slice(1);
};

// Navigate to post when image is clicked
const navigateToPost = (slug) => {
  if (slug) {
    navigateTo(`/sale/${slug}`);
  }
};
</script>

<style scoped>
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

.dotted-spinner.blue {
  border-color: #3b82f6;
}

.dotted-spinner.violet {
  border-color: #8b5cf6;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

.dotted-spinner.primary {
  border-color: #059669;
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

<style scoped>
/* Additional custom styles */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  line-clamp: 2;
  overflow: hidden;
}
</style>
