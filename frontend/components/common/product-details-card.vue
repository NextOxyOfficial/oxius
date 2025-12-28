<template>
  <UCard
    v-if="currentProduct"
    class="p-0 overflow-hidden border-none shadow-sm"
    :ui="{
      divide: '',
      body: {
        padding: 'p-1',
      },
    }"
  >
    <!-- Header section remains the same -->
    <template #header>
      <div class="flex-block">
        <div
          class="relative bg-gradient-to-r from-primary-50 to-white dark:from-slate-900 dark:to-slate-800 py-2"
        >
          <div v-if="modal" class="flex items-start ml-2">
            <UBadge
              v-if="currentProduct.quantity > 0"
              color="blue"
              class="mr-2"
            >
              In Stock
            </UBadge>
            <UBadge v-else color="red"> Out of Stock </UBadge>
          </div>
          <div class="flex gap-3 justify-between items-start">
            <div class="flex-1">
              <h3
                class="text-lg ml-1 md:text-lg font-medium text-primary-700 dark:text-primary-300 text-left"
              >
                {{ capitalizedProductName }}
              </h3>

              <!-- Category, Weight, and Rating under product name -->
              <div class="flex items-center gap-3 mt-2 ml-1 flex-wrap">
                <!-- Category Badge -->
                <UBadge
                  v-if="currentProduct?.category_details?.length > 0"
                  color="gray"
                  variant="subtle"
                  class="uppercase text-xs tracking-wider"
                >
                  {{
                    currentProduct?.category_details[0]?.name || "Uncategorized"
                  }}
                </UBadge>

                <!-- Weight -->
                <div
                  v-if="currentProduct.weight && currentProduct.weight > 0"
                  class="text-xs text-slate-500"
                >
                  Weight: {{ currentProduct.weight }}kg
                </div>

                <!-- Ratings section with dynamic data -->
                <div class="flex items-center gap-2">
                  <div class="rating-stars relative inline-block">
                    <!-- Background stars -->
                    <div class="flex">
                      <UIcon
                        v-for="n in 5"
                        :key="`bg-${n}`"
                        name="i-heroicons-star"
                        class="w-4 h-4 text-slate-200 dark:text-slate-700"
                      />
                    </div>

                    <!-- Foreground stars with animation -->
                    <div
                      class="absolute top-0 left-0 flex overflow-hidden"
                      :style="{
                        width: `${(displayRating / 5) * 100}%`,
                      }"
                    >
                      <UIcon
                        v-for="n in 5"
                        :key="`fg-${n}`"
                        name="i-heroicons-star-solid"
                        class="w-4 h-4 text-yellow-400"
                      />
                    </div>
                  </div>

                  <span
                    class="text-xs font-medium text-slate-700 dark:text-slate-300"
                  >
                    {{ averageRating }} ({{ reviewCount }} reviews)
                  </span>
                </div>
              </div>
            </div>

            <UButton
              v-if="seeDetails"
              icon="i-heroicons-x-mark"
              size="sm"
              color="orange"
              square
              variant="ghost"
              class="hover:bg-white/20"
              @click="closeModal"
            />
          </div>
        </div>
      </div>
    </template>

    <div>
      <!-- Two-column layout remains the same -->
      <div class="grid grid-cols-1 md:grid-cols-2">
        <!-- Left column with images remains the same -->
        <div>
          <!-- Main Image with Glass Effect Border -->
          <div class="flex justify-center mb-3">
            <div
              class="relative w-full aspect-square bg-slate-50 dark:bg-slate-800/40 rounded-xl overflow-hidden backdrop-blur-sm shadow-sm border border-white/20 dark:border-slate-700/50"
            >
              <img
                v-if="
                  currentProduct.image_details &&
                  currentProduct.image_details.length
                "
                :src="
                  currentProduct.image_details[selectedImageIndex || 0].image
                "
                :alt="currentProduct.name"
                class="absolute inset-0 w-full h-full object-contain px-2"
              />
              <div
                v-else
                class="absolute inset-0 flex items-center justify-center text-slate-400"
              >
                <UIcon name="i-heroicons-photo" class="w-20 h-20" />
              </div>
              <!-- Discount Badge with Improved Design -->
              <div
                v-if="currentProduct.discount"
                class="absolute top-2 left-2 bg-red-500 text-white text-sm font-medium px-3 py-1 rounded-full shadow-sm"
              >
                -{{ currentProduct.discount }}% OFF!
              </div>

              <!-- Free Delivery Badge -->
              <div
                v-if="currentProduct.is_free_delivery"
                class="absolute top-2 right-2 bg-purple-500 text-white text-sm font-medium px-3 py-1 rounded-full shadow-sm"
              >
                Free Shipping
              </div>
            </div>
          </div>

          <!-- Thumbnail Gallery remains the same -->
          <div
            class="grid grid-cols-5 gap-2 mt-4"
            v-if="
              currentProduct.image_details &&
              currentProduct.image_details.length > 1
            "
          >
            <div
              v-for="(img, i) in currentProduct.image_details"
              :key="img.id"
              class="relative aspect-square bg-slate-100 dark:bg-slate-800 rounded-md overflow-hidden cursor-pointer hover:opacity-90 transition-all duration-300 shadow-sm"
              :class="
                i === selectedImageIndex
                  ? 'ring-2 ring-primary-500 ring-offset-1'
                  : 'opacity-70 hover:opacity-100'
              "
              @click="selectedImageIndex = i"
            >
              <img
                :src="img.image"
                :alt="currentProduct.name"
                class="absolute inset-0 w-full h-full object-contain"
              />
            </div>
          </div>
        </div>

        <!-- Right column with product info -->
        <div>
          <!-- Price section remains the same -->
          <div class="bg-slate-50 dark:bg-slate-800/30 p-4 rounded-xl mb-4">
            <div class="flex items-end gap-3">
              <span
                class="text-2xl font-medium text-primary-600 dark:text-primary-400"
              >
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </span>
              <span
                v-if="
                  currentProduct.sale_price &&
                  currentProduct.sale_price !== currentProduct.regular_price
                "
                class="text-base text-slate-400 line-through"
              >
                ৳{{ currentProduct.regular_price }}
              </span>

              <!-- Savings Badge with Animation -->
              <span
                v-if="
                  currentProduct.sale_price &&
                  currentProduct.regular_price &&
                  currentProduct.sale_price !== currentProduct.regular_price
                "
                class="savings-badge bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400 text-xs font-medium px-2 py-1 rounded-md ml-auto animate-pulse"
              >
                Save ৳{{
                  calculateSavings(
                    currentProduct.sale_price,
                    currentProduct.regular_price
                  )
                }}
              </span>
            </div>

            <!-- Stock Status -->
            <div class="mt-2 text-sm">
              <span
                :class="
                  currentProduct.quantity > 10
                    ? 'text-blue-600 dark:text-blue-400'
                    : currentProduct.quantity > 0
                    ? 'text-amber-600 dark:text-amber-400'
                    : 'text-red-600 dark:text-red-400'
                "
              >
                <span v-if="currentProduct.quantity > 10">In Stock</span>
                <span v-else-if="currentProduct.quantity > 0"
                  >Only {{ currentProduct.quantity }} left!</span
                >
                <span v-else>Out of Stock</span>
              </span>
            </div>
          </div>

          <!-- Short Description - Updated to use short_description -->
          <div class="mb-6">
            <h4 class="font-medium text-gray-800 dark:text-white mb-2">
              Summary
            </h4>
            <div
              class="text-sm text-gray-600 dark:text-slate-300 leading-relaxed bg-slate-50 dark:bg-slate-800/20 p-3 rounded-lg border border-slate-100 dark:border-slate-700/40"
            >
              {{ currentProduct.short_description || "No summary available." }}
            </div>
          </div>

          <!-- Add to Cart Area remains the same -->
          <div class="flex items-center gap-4 mb-6">
            <!-- Quantity Selector -->
            <div
              class="flex items-center border border-slate-200 dark:border-slate-700 rounded-lg"
            >
              <button
                type="button"
                class="w-10 h-10 flex items-center justify-center text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                @click="quantity > 1 ? quantity-- : null"
              >
                <UIcon name="i-heroicons-minus" class="w-4 h-4" />
              </button>

              <span class="w-10 text-center font-medium">{{ quantity }}</span>

              <button
                type="button"
                class="w-10 h-10 flex items-center justify-center text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                @click="quantity++"
              >
                <UIcon name="i-heroicons-plus" class="w-4 h-4" />
              </button>
            </div>

            <!-- Buy Now Button with Enhanced Design -->
            <button
              type="button"
              class="flex-1 relative overflow-hidden group bg-gradient-to-r from-slate-700 via-slate-600 to-slate-700 hover:from-slate-600 hover:via-slate-500 hover:to-slate-600 rounded-lg py-3 px-6 text-white font-medium shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-[1.02]"
              @click="addToCart(currentProduct, quantity)"
              :disabled="currentProduct.quantity <= 0"
            >
              <!-- Content container -->
              <div class="relative flex items-center justify-center gap-2">
                <!-- Shopping cart icon -->
                <UIcon name="i-heroicons-shopping-cart" class="w-5 h-5" />

                <!-- Button text with animated dot -->
                <span class="text-base font-medium">
                  Buy Now
                  <span
                    class="inline-block w-1.5 h-1.5 bg-white rounded-full ml-0.5 animate-pulse"
                  ></span>
                </span>
              </div>
            </button>
          </div>

          <!-- Shipping Information remains the same -->
          <div class="bg-slate-50 dark:bg-slate-800/40 p-4 rounded-xl">
            <div class="text-sm font-medium mb-3 flex items-center">
              <UIcon
                name="i-heroicons-truck"
                class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
              />
              <span>Shipping Information</span>
            </div>

            <ul class="space-y-2.5 text-gray-600 dark:text-slate-300">
              <li class="flex items-start gap-2 text-sm">
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5"
                />
                <span
                  >Inside Dhaka:
                  <span class="font-medium"
                    >৳{{
                      currentProduct.delivery_fee_inside_dhaka || 100
                    }}</span
                  ></span
                >
              </li>

              <li class="flex items-start gap-2 text-sm">
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5"
                />
                <span
                  >Outside Dhaka:
                  <span class="font-medium"
                    >৳{{
                      currentProduct.delivery_fee_outside_dhaka || 150
                    }}</span
                  ></span
                >
              </li>

              <li class="flex items-start gap-2 text-sm">
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5"
                />
                <span>Delivery within 3-5 business days</span>
              </li>

              <li
                v-if="currentProduct.is_free_delivery"
                class="flex items-start gap-2 text-sm"
              >
                <UIcon
                  name="i-heroicons-gift"
                  class="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5"
                />
                <span class="font-medium text-red-600 dark:text-red-400"
                  >Free Delivery on this product!</span
                >
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Seller Information Section -->
      <div
        class="mt-6 border-t border-slate-200 dark:border-slate-700 pt-6 mb-6"
      >
        <div
          class="bg-slate-50 dark:bg-slate-800/40 rounded-xl overflow-hidden"
        >
          <!-- Seller Profile Header -->
          <div
            class="flex items-center p-4 border-b border-slate-200 dark:border-slate-700/50"
          >
            <div class="flex-shrink-0 relative">
              <div
                class="w-14 h-14 rounded-xl bg-slate-200 dark:bg-slate-700 overflow-hidden"
              >
                <img
                  v-if="currentProduct.owner_details?.image"
                  :src="currentProduct.owner_details?.image"
                  :alt="currentProduct.owner_details?.name || 'Seller'"
                  class="w-full h-full object-contain"
                />
                <div v-else class="flex items-center justify-center h-full">
                  <UIcon
                    name="ic-twotone-add-business"
                    class="w-8 h-8 text-orange-400"
                  />
                </div>
              </div>
              <div
                v-if="currentProduct.owner_details?.kyc"
                class="absolute -right-1 -bottom-1 bg-primary-500 text-white rounded-full px-1.5 border-2 border-white dark:border-slate-800"
              >
                <UIcon name="i-heroicons-check" class="w-3 h-3" />
              </div>
            </div>
            <div class="ml-3 flex-1 min-w-0">
              <div class="flex items-start gap-3">
                <div class="flex-1 min-w-0">
                  <NuxtLink
                    v-if="
                      currentProduct.owner_details?.store_username ||
                      currentProduct.owner_details?.id
                    "
                    :to="`/eshop/${
                      currentProduct.owner_details?.store_username ||
                      currentProduct.owner_details?.id
                    }`"
                    class="hover:text-blue-600 transition-colors"
                  >
                    <h4
                      class="font-medium text-slate-800 dark:text-white line-clamp-2 leading-tight"
                    >
                      {{
                        currentProduct.owner_details?.store_name ||
                        "Anonymous Seller"
                      }}
                    </h4>
                  </NuxtLink>
                  <h4
                    v-else
                    class="font-medium text-gray-800 dark:text-white line-clamp-2 leading-tight"
                  >
                    {{
                      currentProduct.owner_details?.store_name ||
                      "Anonymous Seller"
                    }}
                  </h4>
                </div>

                <!-- Visit Store Button -->
                <UButton
                  v-if="
                    currentProduct.owner_details?.store_username ||
                    currentProduct.owner_details?.id
                  "
                  color="gray"
                  variant="soft"
                  size="sm"
                  :to="`/eshop/${
                    currentProduct.owner_details?.store_username ||
                    currentProduct.owner_details?.id
                  }`"
                  icon="i-heroicons-building-storefront"
                  class="flex-shrink-0"
                >
                  Visit Store
                </UButton>
              </div>

              <!-- Pro and Verified Badges -->
              <div class="flex items-center gap-2 mt-1">
                <!-- Pro Badge -->
                <UBadge
                  v-if="
                    currentProduct.owner_details?.is_pro ||
                    currentProduct.owner_details?.subscription_type === 'pro'
                  "
                  color="amber"
                  variant="solid"
                  size="sm"
                  class="font-semibold"
                >
                  <UIcon name="i-heroicons-star-solid" class="w-3 h-3 mr-1" />
                  Pro
                </UBadge>

                <!-- Verified Badge -->
                <UBadge
                  v-if="
                    currentProduct.owner_details?.kyc ||
                    currentProduct.owner_details?.is_verified
                  "
                  color="blue"
                  variant="solid"
                  size="xs"
                  class="font-semibold"
                >
                  <UIcon
                    name="i-heroicons-check-badge-solid"
                    class="w-3 h-3 mr-1"
                  />
                  Verified
                </UBadge>
              </div>
            </div>

            <div class="hidden sm:block"></div>
          </div>

          <!-- Contact Information -->
          <div class="p-4 space-y-3">
            <div class="flex items-center text-sm">
              <UIcon
                name="i-heroicons-map-pin"
                class="w-5 h-5 text-slate-500 flex-shrink-0 mr-2"
              />
              <span class="text-gray-600 dark:text-slate-300">
                {{
                  `${currentProduct.owner_details?.upazila}, ${currentProduct.owner_details?.city}, ${currentProduct.owner_details?.state}, ${currentProduct.owner_details?.country}`
                }}
              </span>
            </div>

            <div class="flex items-center text-sm">
              <UIcon
                name="i-heroicons-clock"
                class="w-5 h-5 text-slate-500 flex-shrink-0 mr-2"
              />
              <span class="text-gray-600 dark:text-slate-300">
                Member since
                {{
                  formatMemberSince(currentProduct.owner_details?.date_joined)
                }}
              </span>
            </div>
          </div>

          <!-- Contact Actions -->
        </div>

        <!-- More from this store Section -->
        <div
          v-if="
            storeProducts.length > 0 ||
            isLoadingStoreProducts ||
            totalStoreProducts > 0
          "
          class="mt-4 border-t border-slate-200 dark:border-slate-700/50 pt-4"
        >
          <div class="flex items-center justify-between mb-3">
            <h4
              class="font-medium text-gray-800 dark:text-white flex items-center"
            >
              <UIcon
                name="i-heroicons-shopping-bag"
                class="w-5 h-5 mr-2 text-blue-600 dark:text-blue-400"
              />
              More from this store
              <span
                v-if="totalStoreProducts > 0"
                class="ml-2 text-xs text-gray-500"
              >
                ({{ totalStoreProducts }} products)
              </span>
            </h4>
          </div>

          <!-- Loading state for store products -->
          <div v-if="isLoadingStoreProducts" class="flex justify-center py-4">
            <div class="flex items-center gap-2">
              <div class="w-5 h-5 relative">
                <div
                  class="w-full h-full rounded-full border-2 border-slate-300 dark:border-slate-600"
                ></div>
                <div
                  class="w-full h-full rounded-full border-2 border-t-primary-500 animate-spin absolute top-0 left-0"
                ></div>
              </div>
              <span class="text-sm text-gray-600 dark:text-slate-400"
                >Loading store products...</span
              >
            </div>
          </div>

          <!-- Horizontal scrollable products container -->
          <div
            v-else-if="storeProducts.length > 0"
            ref="storeProductsContainer"
            class="horizontal-scroll-container relative overflow-x-auto pb-2"
            @mousedown="handleMouseDown"
            @mouseleave="handleMouseLeave"
            @mouseup="handleMouseUp"
            @mousemove="handleMouseMove"
            @scroll="handleStoreProductsScroll"
          >
            <div class="flex gap-2 w-max">
              <div
                v-for="(product, index) in storeProducts"
                :key="`store-${product.id}`"
                class="flex-shrink-0 w-48 sm:w-52 md:w-56 store-product-fade-in"
                style="animation-delay: calc(var(--i) * 0.1s)"
                :style="{ '--i': index % 6 }"
              >
                <CommonProductCard
                  :product="product"
                  :isInModal="true"
                  @updateModalProduct="handleModalProductChange"
                  class="h-full"
                />
              </div>

              <!-- Enhanced Loading indicator for infinite scroll -->
              <div
                v-if="isLoadingMoreStoreProducts"
                class="flex-shrink-0 w-48 sm:w-52 md:w-56 flex items-center justify-center"
              >
                <div
                  class="flex flex-col items-center justify-center py-12 px-4 h-full"
                >
                  <div class="w-8 h-8 relative mb-3">
                    <div
                      class="w-full h-full rounded-full border-3 border-t-blue-500 dark:border-t-blue-400 border-transparent"
                      style="animation: spinGlow 1.2s linear infinite"
                    ></div>
                  </div>
                  <div class="text-center">
                    <p
                      class="text-sm font-medium text-gray-700 dark:text-slate-300 mb-1"
                    >
                      Loading more
                    </p>
                    <p class="text-xs text-gray-500 dark:text-slate-400">
                      store products...
                    </p>
                  </div>
                  <!-- Animated dots with enhanced timing -->
                  <div class="flex gap-1 mt-2">
                    <div
                      class="w-1.5 h-1.5 bg-blue-500 dark:bg-blue-400 rounded-full"
                      style="
                        animation: dotPulse 1.4s infinite;
                        animation-delay: 0s;
                      "
                    ></div>
                    <div
                      class="w-1.5 h-1.5 bg-blue-500 dark:bg-blue-400 rounded-full"
                      style="
                        animation: dotPulse 1.4s infinite;
                        animation-delay: 0.2s;
                      "
                    ></div>
                    <div
                      class="w-1.5 h-1.5 bg-blue-500 dark:bg-blue-400 rounded-full"
                      style="
                        animation: dotPulse 1.4s infinite;
                        animation-delay: 0.4s;
                      "
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- No store products message -->
          <div v-else class="text-center py-4">
            <div
              class="bg-white dark:bg-slate-700/50 rounded-lg p-4 w-32 h-20 mx-auto flex items-center justify-center shadow-sm"
            >
              <UIcon
                name="i-heroicons-building-storefront"
                class="w-6 h-6 text-gray-400 dark:text-slate-500"
              />
            </div>
            <p class="mt-2 text-sm text-gray-600 dark:text-slate-400">
              No other products from this store
            </p>
          </div>
        </div>
      </div>

      <!-- Product Full Description - Replaced tabs with direct content -->
      <div class="mt-8 border-t border-slate-200 dark:border-slate-700 pt-6">
        <!-- Full Description Section -->
        <div class="">
          <h3
            class="text-base font-Medium my-3 text-gray-800 dark:text-white flex items-center"
          >
            <UIcon
              name="i-heroicons-clipboard-document-list"
              class="w-5 h-5 mr-2 text-emerald-600 dark:text-emerald-400"
            />
            Detailed Description
          </h3>
          <div
            class="prose prose-slate max-w-none dark:prose-invert prose-img:rounded-xl prose-headings:font-medium prose-a:text-primary-600 dark:prose-a:text-primary-400 text-left px-4"
            v-html="
              currentProduct.description || 'No detailed description available.'
            "
          ></div>
        </div>

        <!-- Customer Reviews Section -->
        <div
          class="mt-8 border-t border-slate-200 dark:border-slate-700 pt-6 customer-reviews-section"
        >
          <h3
            class="text-base font-medium mb-6 text-gray-800 dark:text-white flex items-center"
          >
            <UIcon
              name="i-heroicons-star"
              class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
            />
            Customer Reviews
          </h3>

          <!-- Featured Reviews with Pagination -->
          <div class="max-w-6xl mx-auto mb-10">
            <!-- Loading state -->
            <div
              v-if="isLoadingReviews"
              class="grid grid-cols-1 md:grid-cols-3 gap-6"
            >
              <div
                v-for="n in 3"
                :key="n"
                class="bg-white dark:bg-slate-800 rounded-xl shadow-sm p-6 animate-pulse"
              >
                <div class="flex mb-3">
                  <div
                    v-for="i in 5"
                    :key="i"
                    class="w-5 h-5 bg-gray-200 dark:bg-gray-700 rounded mr-1"
                  ></div>
                </div>
                <div
                  class="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"
                ></div>
                <div
                  class="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-4 w-3/4"
                ></div>
                <div class="flex items-center">
                  <div
                    class="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-full mr-3"
                  ></div>
                  <div>
                    <div
                      class="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-1 w-20"
                    ></div>
                    <div
                      class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-16"
                    ></div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Reviews grid -->
            <div
              v-else-if="displayedReviews.length > 0"
              class="grid grid-cols-1 md:grid-cols-3 gap-6"
            >
              <div
                v-for="(review, index) in displayedReviews"
                :key="review.id || index"
                class="bg-white dark:bg-slate-800 rounded-xl shadow-sm p-6 transition-opacity hover:opacity-90"
              >
                <div class="flex text-amber-400 mb-3">
                  <UIcon
                    v-for="star in 5"
                    :key="star"
                    :name="
                      star <= review.rating
                        ? 'i-heroicons-star-solid'
                        : 'i-heroicons-star'
                    "
                    class="w-5 h-5"
                    :class="
                      star <= review.rating ? 'text-amber-400' : 'text-gray-300'
                    "
                  />
                </div>
                <p class="text-gray-600 dark:text-slate-300 mb-4">
                  "{{ review.comment }}"
                </p>
                <div class="flex items-center">
                  <NuxtLink 
                    v-if="review.user?.id"
                    :to="`/business-network/profile/${review.user.id}`"
                    class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-3 text-primary-700 dark:text-primary-300 font-medium cursor-pointer hover:ring-2 hover:ring-primary-300 transition-all"
                  >
                    {{
                      review.user?.display_name?.charAt(0) ||
                      review.reviewer_name?.charAt(0) ||
                      "U"
                    }}
                  </NuxtLink>
                  <div
                    v-else
                    class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-3 text-primary-700 dark:text-primary-300 font-medium"
                  >
                    {{
                      review.user?.display_name?.charAt(0) ||
                      review.reviewer_name?.charAt(0) ||
                      "U"
                    }}
                  </div>
                  <div>
                    <NuxtLink 
                      v-if="review.user?.id"
                      :to="`/business-network/profile/${review.user.id}`"
                      class="font-medium text-gray-800 dark:text-white hover:text-primary-600 dark:hover:text-primary-400 hover:underline transition-colors cursor-pointer"
                    >
                      {{
                        review.user?.display_name ||
                        review.reviewer_name ||
                        "Anonymous"
                      }}
                    </NuxtLink>
                    <div v-else class="font-medium text-gray-800 dark:text-white">
                      {{
                        review.user?.display_name ||
                        review.reviewer_name ||
                        "Anonymous"
                      }}
                    </div>
                    <div class="text-xs text-slate-500 dark:text-slate-400">
                      {{ review.formatted_date || "Verified Purchase" }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Pagination Controls -->
          <div v-if="totalReviewPages > 1" class="flex justify-center">
            <div class="flex items-center gap-2">
              <!-- Previous button -->
              <UButton
                icon="i-heroicons-chevron-left"
                color="gray"
                variant="ghost"
                :disabled="currentReviewPage === 1 || isLoadingReviews"
                @click="previousReviewPage"
                size="sm"
                class="rounded-full"
                :loading="isLoadingReviews"
              />

              <!-- Page numbers -->
              <div class="flex gap-1">
                <UButton
                  v-for="page in paginationRange"
                  :key="page"
                  :variant="currentReviewPage === page ? 'solid' : 'ghost'"
                  :color="currentReviewPage === page ? 'primary' : 'gray'"
                  size="sm"
                  class="w-8 h-8"
                  @click="goToReviewPage(page)"
                  v-if="page !== '...'"
                  :disabled="isLoadingReviews"
                  :loading="isLoadingReviews && currentReviewPage === page"
                >
                  {{ page }}
                </UButton>
                <!-- Ellipsis -->
                <div
                  v-if="paginationRange.includes('...')"
                  class="w-8 h-8 flex items-center justify-center text-slate-500"
                >
                  ...
                </div>
              </div>

              <!-- Next button -->
              <UButton
                icon="i-heroicons-chevron-right"
                color="gray"
                variant="ghost"
                :disabled="
                  currentReviewPage === totalReviewPages || isLoadingReviews
                "
                @click="nextReviewPage"
                size="sm"
                class="rounded-full"
                :loading="isLoadingReviews"
              />
            </div>
          </div>

          <!-- Write a Review Section -->
          <div
            class="bg-slate-50 dark:bg-slate-800/50 rounded-xl p-6 max-w-3xl mx-auto"
          >
            <!-- Loading state for checking user review -->
            <div v-if="isCheckingUserReview" class="text-center p-6">
              <div
                class="animate-spin w-8 h-8 border-2 border-primary-500 border-t-transparent rounded-full mx-auto mb-4"
              ></div>
              <p class="text-gray-600 dark:text-slate-400">
                Checking your review status...
              </p>
            </div>

            <!-- User has already submitted a review -->
            <div
              v-else-if="isLoggedIn && userExistingReview"
              class="text-center p-6"
            >
              <UIcon
                name="i-heroicons-check-circle"
                class="w-12 h-12 text-blue-500 mx-auto mb-4"
              />
              <h4
                class="text-lg font-medium mb-2 text-blue-700 dark:text-blue-400"
              >
                Thank You for Your Review!
              </h4>
              <p class="text-gray-600 dark:text-slate-400 mb-4">
                You have already submitted a review for this product.
              </p>

              <!-- Show the user's existing review -->
              <div
                class="bg-white dark:bg-slate-700 rounded-lg p-4 text-left max-w-md mx-auto"
              >
                <div class="flex text-amber-400 mb-2">
                  <UIcon
                    v-for="star in 5"
                    :key="star"
                    :name="
                      star <= userExistingReview.rating
                        ? 'i-heroicons-star-solid'
                        : 'i-heroicons-star'
                    "
                    class="w-4 h-4"
                    :class="
                      star <= userExistingReview.rating
                        ? 'text-amber-400'
                        : 'text-gray-300'
                    "
                  />
                  <span class="ml-2 text-sm text-gray-600 dark:text-slate-400"
                    >Your Rating</span
                  >
                </div>
                <p class="text-gray-700 dark:text-slate-300 text-sm">
                  "{{ userExistingReview.comment }}"
                </p>
                <p class="text-xs text-gray-500 dark:text-slate-500 mt-2">
                  Submitted
                  {{ userExistingReview.formatted_date || "recently" }}
                </p>
              </div>
            </div>

            <!-- User can submit a review -->
            <div v-else-if="canSubmitReview">
              <div class="space-y-4">
                <div>
                  <label
                    class="block text-sm mb-1 text-gray-600 dark:text-slate-300"
                  >
                    Your Rating
                  </label>
                  <div class="flex gap-1">
                    <UButton
                      v-for="star in 5"
                      :key="star"
                      variant="ghost"
                      color="gray"
                      class="p-1"
                      @click="reviewForm.rating = star"
                    >
                      <UIcon
                        :name="
                          star <= reviewForm.rating
                            ? 'i-heroicons-star-solid'
                            : 'i-heroicons-star'
                        "
                        class="w-6 h-6 transition-colors duration-200"
                        :class="
                          star <= reviewForm.rating
                            ? 'text-amber-400'
                            : 'text-slate-300 dark:text-gray-600'
                        "
                      />
                    </UButton>
                  </div>
                </div>

                <div>
                  <label
                    class="block text-sm mb-1 text-gray-600 dark:text-slate-300"
                  >
                    Your Name
                  </label>
                  <div
                    class="px-3 py-2 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-md text-gray-800 dark:text-white font-medium"
                  >
                    {{ displayName }}
                  </div>
                </div>
                <div>
                  <label
                    class="block text-sm mb-1 text-gray-600 dark:text-slate-300"
                  >
                    Your Review
                  </label>
                  <UTextarea
                    v-model="reviewForm.comment"
                    placeholder="Share your experience with this product..."
                    rows="3"
                  />
                </div>
                <div class="mt-4">
                  <UButton
                    color="primary"
                    @click="submitReview"
                    :disabled="!isReviewValid || isSubmittingReview"
                    :loading="isSubmittingReview"
                    block
                  >
                    {{ isSubmittingReview ? "Submitting..." : "Submit Review" }}
                  </UButton>
                </div>
              </div>
            </div>

            <!-- User needs to log in -->
            <div v-else class="text-center p-6">
              <UIcon
                name="i-heroicons-lock-closed"
                class="w-12 h-12 text-slate-300 dark:text-gray-600 mx-auto mb-4"
              />
              <h4 class="text-lg font-medium mb-2">Please Log In to Review</h4>
              <p class="text-gray-600 dark:text-slate-400 mb-4">
                You need to be logged in to share your experience with this
                product.
              </p>
              <div class="flex justify-center">
                <UButton to="/login" color="primary">
                  Log in to continue
                </UButton>
              </div>
            </div>
          </div>
        </div>
        <!-- You may also like Section -->
        <div class="bg-slate-50 dark:bg-slate-800/30 rounded-xl">
          <h3
            class="text-base font-medium py-3 px-2 text-gray-800 dark:text-white flex items-center"
          >
            <UIcon
              name="i-heroicons-heart"
              class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
            />
            {{ similarProductsTitle }}
          </h3>
          <div
            v-if="isSimilarProductsLoading && similarProducts.length === 0"
            class="flex justify-center py-6"
          >
            <div class="flex flex-col items-center">
              <div class="w-10 h-10 relative">
                <div
                  class="w-full h-full rounded-full border-3 border-white dark:border-slate-700"
                ></div>
                <div
                  class="w-full h-full rounded-full border-3 border-t-primary-500 animate-spin absolute top-0 left-0"
                ></div>
              </div>
              <p class="text-sm text-gray-600 dark:text-slate-400 mt-3">
                {{
                  isLoadingSameCategory
                    ? "Loading same category products..."
                    : "Loading similar products..."
                }}
              </p>
            </div>
          </div>
          <div
            v-else-if="similarProducts.length === 0"
            class="py-4 text-center"
          >
            <div
              class="bg-white dark:bg-slate-700/50 rounded-full p-5 w-20 h-20 mx-auto flex items-center justify-center shadow-sm"
            >
              <UIcon
                name="i-heroicons-shopping-bag"
                class="w-8 h-8 text-gray-400 dark:text-slate-500"
              />
            </div>
            <p class="mt-4 text-sm text-gray-600 dark:text-slate-400">
              No similar products found
            </p>
          </div>
          <div v-else>
            <!-- Infinite Scroll Similar Products Grid -->
            <div
              ref="similarProductsContainer"
              class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 pb-4"
            >
              <div
                v-for="(product, index) in similarProducts"
                :key="`similar-${product.id}`"
                class="similar-product-fade-in"
                style="animation-delay: calc(var(--i) * 0.1s)"
                :style="{ '--i': index % 8 }"
              >
                <CommonProductCard
                  :product="product"
                  :isInModal="true"
                  @updateModalProduct="handleModalProductChange"
                />
              </div>
            </div>

            <!-- Enhanced Loading indicator for infinite scroll -->
            <div
              v-if="isLoadingMoreSimilarProducts"
              class="flex justify-center py-6"
            >
              <div class="flex flex-col items-center gap-3 px-6 py-8">
                <div class="w-8 h-8 relative">
                  <div
                    class="w-full h-full rounded-full border-3 border-t-emerald-500 dark:border-t-emerald-400 border-transparent"
                    style="animation: spinGlow 1.2s linear infinite"
                  ></div>
                </div>
                <div class="text-center">
                  <p
                    class="text-sm font-medium text-gray-700 dark:text-slate-300 mb-1"
                  >
                    Loading more
                  </p>
                  <p class="text-xs text-gray-500 dark:text-slate-400">
                    {{
                      isLoadingSameCategory
                        ? "from same category..."
                        : "similar products..."
                    }}
                  </p>
                </div>
                <!-- Animated dots with enhanced timing -->
                <div class="flex gap-1">
                  <div
                    class="w-1.5 h-1.5 bg-emerald-500 dark:bg-emerald-400 rounded-full"
                    style="
                      animation: dotPulse 1.4s infinite;
                      animation-delay: 0s;
                    "
                  ></div>
                  <div
                    class="w-1.5 h-1.5 bg-emerald-500 dark:bg-emerald-400 rounded-full"
                    style="
                      animation: dotPulse 1.4s infinite;
                      animation-delay: 0.2s;
                    "
                  ></div>
                  <div
                    class="w-1.5 h-1.5 bg-emerald-500 dark:bg-emerald-400 rounded-full"
                    style="
                      animation: dotPulse 1.4s infinite;
                      animation-delay: 0.4s;
                    "
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-center my-4" v-if="seeDetails">
        <UButton
          :to="`/product-details/${currentProduct.slug}`"
          color="primary"
          variant="outline"
          size="md"
          icon="i-material-symbols-light-arrow-right-alt-rounded"
          :ui="{
            size: {
              lg: 'text-sm',
            },
          }"
          trailing
        >
          See Full Details
        </UButton>
      </div>
    </div>
  </UCard>
  <UCard v-else class="flex items-center justify-center p-8 h-64">
    <div class="text-center">
      <UIcon
        name="i-heroicons-face-frown"
        class="w-12 h-12 mx-auto text-slate-300 dark:text-slate-700 mb-3"
      />
      <p class="text-slate-500 dark:text-slate-400">No Product Found!</p>
      <UButton to="/eshop" class="mt-4" size="sm" color="primary">
        Browse Products
      </UButton>
    </div>
  </UCard>
</template>

<style scoped>
/* Horizontal scroll container styling with hidden scrollbar */
.horizontal-scroll-container {
  cursor: grab;
  scroll-behavior: smooth;
  /* Hide scrollbar for Firefox */
  scrollbar-width: none;
  /* Hide scrollbar for IE and Edge */
  -ms-overflow-style: none;
}

/* Hide scrollbar for WebKit browsers (Chrome, Safari, Edge) */
.horizontal-scroll-container::-webkit-scrollbar {
  display: none;
}

/* Fade-in animations */
.similar-product-fade-in {
  opacity: 0;
  transform: translateY(20px);
  animation: fadeInUp 0.6s ease-out forwards;
}

.store-product-fade-in {
  opacity: 0;
  transform: translateX(20px);
  animation: fadeInLeft 0.6s ease-out forwards;
}

@keyframes fadeInUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeInLeft {
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Savings badge animation */
.savings-badge {
  animation: pulse 2s infinite;
}

/* Enhanced loading spinner animations */
@keyframes spinGlow {
  0% {
    transform: rotate(0deg);
    filter: brightness(1);
  }
  50% {
    filter: brightness(1.2);
  }
  100% {
    transform: rotate(360deg);
    filter: brightness(1);
  }
}

/* Custom pulse animation for loading dots */
@keyframes dotPulse {
  0%,
  100% {
    opacity: 0.3;
    transform: scale(0.8);
  }
  50% {
    opacity: 1;
    transform: scale(1.2);
  }
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.8;
  }
}
</style>

<script setup>
const { currentProduct, modal, seeDetails } = defineProps({
  currentProduct: { type: Object, required: true },
  modal: { type: Boolean, required: false },
  seeDetails: { type: Boolean, required: false },
});

const emit = defineEmits([
  "close-modal",
  "open-message-modal",
  "close-and-reopen-modal",
]);

// Function to handle product updates from related products
function handleModalProductChange(newProduct) {
  emit("close-and-reopen-modal", newProduct);
}

const selectedImageIndex = ref(0);
const quantity = ref(1);
const similarProducts = ref([]);
const isSimilarProductsLoading = ref(false);
const isLoadingMoreSimilarProducts = ref(false);
const similarProductsContainer = ref(null);
const similarProductsPage = ref(1);
const hasMoreSimilarProducts = ref(true);
const allLoadedSimilarProducts = ref([]);

// Store products state
const storeProducts = ref([]);
const isLoadingStoreProducts = ref(false);
const isLoadingMoreStoreProducts = ref(false);
const storeProductsContainer = ref(null);
const storeProductsPage = ref(1);
const hasMoreStoreProducts = ref(true);
const totalStoreProducts = ref(0);

// Mouse drag state for horizontal scrolling
const isDragging = ref(false);
const startX = ref(0);
const scrollLeft = ref(0);

// Category-specific tracking for infinite scroll
const sameCategoryPage = ref(1);
const hasMoreSameCategoryProducts = ref(true);
const isLoadingSameCategory = ref(true); // Start with same category
const allLoadedSameCategoryProducts = ref([]);

// API composable
const { get, post } = useApi();

// User state for reviews
const user = useState("user");

// Dynamic rating stats
const productRatingStats = ref({
  total_reviews: 0,
  average_rating: 0,
  rating_5_count: 0,
  rating_4_count: 0,
  rating_3_count: 0,
  rating_2_count: 0,
  rating_1_count: 0,
});

// Reviews state
const productReviews = ref([]);
const isLoadingReviews = ref(false);
const isSubmittingReview = ref(false);
const userExistingReview = ref(null);
const isCheckingUserReview = ref(false);

// Reviews pagination state
const currentReviewPage = ref(1);
const totalReviewPages = ref(1);
const totalReviewCount = ref(0);
const reviewsPerPage = 6; // Match backend pagination

// Review form data
const reviewForm = ref({
  name: "",
  rating: 0,
  comment: "",
});

// Fetch product rating statistics from API
async function fetchProductRatingStats() {
  if (!currentProduct?.id) return;

  try {
    const response = await get(`/reviews/products/${currentProduct.id}/stats/`);

    if (response.data) {
      productRatingStats.value = response.data;
    } else {
      // Set default stats if no data returned
      productRatingStats.value = {
        total_reviews: 0,
        average_rating: 0,
        rating_5_count: 0,
        rating_4_count: 0,
        rating_3_count: 0,
        rating_2_count: 0,
        rating_1_count: 0,
      };
    }
  } catch (error) {
    console.error("Error fetching rating stats:", error);
    // Set default stats if API fails
    productRatingStats.value = {
      total_reviews: 0,
      average_rating: 0,
      rating_5_count: 0,
      rating_4_count: 0,
      rating_3_count: 0,
      rating_2_count: 0,
      rating_1_count: 0,
    };
  }
}

// Close modal function
function closeModal() {
  emit("close-modal");
}

// Open message modal function
function openMessageModal() {
  emit("open-message-modal", {
    sellerId: currentProduct.seller?.id,
    sellerName: currentProduct.seller?.name || "Seller",
    productId: currentProduct.id,
    productName: currentProduct.name,
  });
}

// Fetch similar products with priority: same category first, then alternative categories
async function fetchSimilarProducts(page = 1, append = false) {
  if (!currentProduct) return;

  if (page === 1) {
    isSimilarProductsLoading.value = true;
    similarProductsPage.value = 1;
    hasMoreSimilarProducts.value = true;
    allLoadedSimilarProducts.value = [];

    // Reset category-specific tracking
    sameCategoryPage.value = 1;
    hasMoreSameCategoryProducts.value = true;
    isLoadingSameCategory.value = true;
    allLoadedSameCategoryProducts.value = [];
  } else {
    isLoadingMoreSimilarProducts.value = true;
  }

  const pageSize = 8; // Products per page for infinite scroll

  try {
    const { get } = useApi();
    let similarProductsList = [];

    // Get the primary category ID - handle different data structures
    let primaryCategoryId = null;
    if (currentProduct.category) {
      // Handle if category is an array, comma-separated string, or single ID
      if (Array.isArray(currentProduct.category)) {
        primaryCategoryId = currentProduct.category[0];
      } else if (
        typeof currentProduct.category === "string" &&
        currentProduct.category.includes(",")
      ) {
        primaryCategoryId = currentProduct.category.split(",")[0].trim();
      } else {
        primaryCategoryId = currentProduct.category;
      }
    } else if (
      currentProduct.category_details &&
      currentProduct.category_details.length > 0
    ) {
      // Fallback to category_details if available
      primaryCategoryId = currentProduct.category_details[0].id;
    }

    // Phase 1: Load same category products first
    if (
      isLoadingSameCategory.value &&
      primaryCategoryId &&
      hasMoreSameCategoryProducts.value
    ) {
      try {
        // Calculate offset for same category pagination
        const sameCategoryOffset = (sameCategoryPage.value - 1) * pageSize;

        let queryParams = `category=${primaryCategoryId}&page_size=${pageSize}&offset=${sameCategoryOffset}&ordering=-created_at`;
        const sameCategory = await get(`/all-products/?${queryParams}`);

        if (sameCategory && sameCategory.data && sameCategory.data.results) {
          // Filter out current product and already loaded products
          const sameCategoryProducts = sameCategory.data.results.filter(
            (product) =>
              product.id !== currentProduct.id &&
              !allLoadedSameCategoryProducts.value.some(
                (existing) => existing.id === product.id
              )
          );

          if (sameCategoryProducts.length > 0) {
            similarProductsList.push(...sameCategoryProducts);
            allLoadedSameCategoryProducts.value.push(...sameCategoryProducts);

            // Check if we have more same category products
            if (sameCategoryProducts.length < pageSize) {
              hasMoreSameCategoryProducts.value = false;
              isLoadingSameCategory.value = false;
            } else {
              sameCategoryPage.value++;
            }
          } else {
            // No more same category products found
            hasMoreSameCategoryProducts.value = false;
            isLoadingSameCategory.value = false;
          }
        } else {
          hasMoreSameCategoryProducts.value = false;
          isLoadingSameCategory.value = false;
        }
      } catch (error) {
        console.error("Error fetching same category products:", error);
        hasMoreSameCategoryProducts.value = false;
        isLoadingSameCategory.value = false;
      }
    }

    // Phase 2: Load alternative category products (only after same category is exhausted)
    if (!isLoadingSameCategory.value && similarProductsList.length < pageSize) {
      try {
        const remainingCount = pageSize - similarProductsList.length;

        // Calculate offset for alternative products (excluding same category products already loaded)
        const alternativeOffset =
          (page - sameCategoryPage.value + 1) * pageSize;

        let additionalQueryParams = `page_size=${
          remainingCount * 2
        }&offset=${alternativeOffset}&ordering=-created_at`;

        // Exclude current category if it exists
        if (primaryCategoryId) {
          additionalQueryParams += `&exclude_category=${primaryCategoryId}`;
        }

        const additionalResponse = await get(
          `/all-products/?${additionalQueryParams}`
        );

        if (
          additionalResponse &&
          additionalResponse.data &&
          additionalResponse.data.results
        ) {
          const additionalProducts = additionalResponse.data.results.filter(
            (product) =>
              product.id !== currentProduct.id &&
              !allLoadedSimilarProducts.value.some(
                (existing) => existing.id === product.id
              )
          );

          if (additionalProducts.length > 0) {
            similarProductsList.push(
              ...additionalProducts.slice(0, remainingCount)
            );
          }

          // Check if we have fewer alternative products than requested
          if (additionalProducts.length < remainingCount) {
            hasMoreSimilarProducts.value = false;
          }
        } else {
          hasMoreSimilarProducts.value = false;
        }
      } catch (error) {
        console.error("Error fetching alternative category products:", error);
        hasMoreSimilarProducts.value = false;
      }
    }

    // Update state based on results
    if (similarProductsList.length === 0) {
      // If we're still loading same category but got no results, switch to alternatives
      if (isLoadingSameCategory.value) {
        isLoadingSameCategory.value = false;
        hasMoreSameCategoryProducts.value = false;
      } else {
        hasMoreSimilarProducts.value = false;
      }
    } else {
      allLoadedSimilarProducts.value.push(...similarProductsList);

      if (append) {
        similarProducts.value.push(...similarProductsList);
      } else {
        similarProducts.value = [...similarProductsList];
      }

      // Check if we have fewer products than requested (indicating no more products)
      if (
        similarProductsList.length < pageSize &&
        !isLoadingSameCategory.value
      ) {
        hasMoreSimilarProducts.value = false;
      }
    }
  } catch (error) {
    console.error("Error fetching similar products:", error);
    if (!append) {
      similarProducts.value = [];
    }
    hasMoreSimilarProducts.value = false;
    isLoadingSameCategory.value = false;
  } finally {
    isSimilarProductsLoading.value = false;
    isLoadingMoreSimilarProducts.value = false;
  }
}

// Handle infinite scroll for similar products
let intersectionObserver = null;

function setupInfiniteScroll() {
  nextTick(() => {
    const container = similarProductsContainer.value;
    if (!container) return;

    // Clean up existing observer
    if (intersectionObserver) {
      intersectionObserver.disconnect();
    }

    // Create a sentinel element at the bottom
    const sentinel = document.createElement("div");
    sentinel.style.height = "1px";
    sentinel.style.visibility = "hidden";
    container.appendChild(sentinel);

    // Set up intersection observer
    intersectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (
            entry.isIntersecting &&
            hasMoreSimilarProducts.value &&
            !isLoadingMoreSimilarProducts.value
          ) {
            loadMoreSimilarProducts();
          }
        });
      },
      {
        rootMargin: "100px", // Trigger 100px before reaching the sentinel
      }
    );

    intersectionObserver.observe(sentinel);
  });
}

// Load more similar products
async function loadMoreSimilarProducts() {
  if (!hasMoreSimilarProducts.value || isLoadingMoreSimilarProducts.value)
    return;

  similarProductsPage.value++;
  await fetchSimilarProducts(similarProductsPage.value, true);
}

// Fetch store products from the same seller
async function fetchStoreProducts(page = 1, append = false) {
  // Check if we have store_username for the dedicated store endpoint
  if (
    !currentProduct?.owner_details?.store_username &&
    !currentProduct?.owner_details?.id
  ) {
    return;
  }

  if (page === 1) {
    isLoadingStoreProducts.value = true;
    storeProductsPage.value = 1;
    hasMoreStoreProducts.value = true;
  } else {
    isLoadingMoreStoreProducts.value = true;
  }

  const pageSize = page === 1 ? 8 : 10; // Initial load: 8 products, subsequent loads: 10 products

  try {
    const { get } = useApi();

    let response;

    // Prefer store endpoint if store_username exists
    if (currentProduct.owner_details.store_username) {
      const storeUsername = currentProduct.owner_details.store_username;
      let queryParams = `page=${page}&page_size=${pageSize}`;
      const apiUrl = `/store/${storeUsername}/products/?${queryParams}`;
      response = await get(apiUrl);
    } else {
      // Fallback: Use owner filtering in AllProductsListView
      const ownerId = currentProduct.owner_details.id;
      let queryParams = `page=${page}&page_size=${pageSize}&owner=${ownerId}`;
      const apiUrl = `/all-products/?${queryParams}`;
      response = await get(apiUrl);
    }

    if (response && response.data && response.data.results) {
      // Filter out current product
      const storeProductsList = response.data.results.filter(
        (product) => product.id !== currentProduct.id
      );

      if (page === 1) {
        storeProducts.value = storeProductsList;
        totalStoreProducts.value = Math.max(0, (response.data.count || 0) - 1); // Subtract 1 for current product
      } else if (append) {
        storeProducts.value.push(...storeProductsList);
      }

      // Check if we have more products - use pagination info from API
      hasMoreStoreProducts.value =
        response.data.next !== null && storeProductsList.length > 0;
    } else {
      if (page === 1) {
        storeProducts.value = [];
        totalStoreProducts.value = 0;
      }
      hasMoreStoreProducts.value = false;
    }
  } catch (error) {
    if (page === 1) {
      storeProducts.value = [];
      totalStoreProducts.value = 0;
    }
    hasMoreStoreProducts.value = false;
  } finally {
    isLoadingStoreProducts.value = false;
    isLoadingMoreStoreProducts.value = false;
  }
}

// Load more store products
async function loadMoreStoreProducts() {
  if (!hasMoreStoreProducts.value || isLoadingMoreStoreProducts.value) return;

  storeProductsPage.value++;
  await fetchStoreProducts(storeProductsPage.value, true);
}

// Mouse drag handlers for horizontal scrolling
function handleMouseDown(e) {
  const container = storeProductsContainer.value;
  if (!container) return;

  isDragging.value = true;
  startX.value = e.pageX - container.offsetLeft;
  scrollLeft.value = container.scrollLeft;
  container.style.cursor = "grabbing";
  container.style.userSelect = "none";
}

function handleMouseLeave() {
  isDragging.value = false;
  const container = storeProductsContainer.value;
  if (container) {
    container.style.cursor = "grab";
    container.style.userSelect = "auto";
  }
}

function handleMouseUp() {
  isDragging.value = false;
  const container = storeProductsContainer.value;
  if (container) {
    container.style.cursor = "grab";
    container.style.userSelect = "auto";
  }
}

function handleMouseMove(e) {
  if (!isDragging.value) return;

  e.preventDefault();
  const container = storeProductsContainer.value;
  if (!container) return;

  const x = e.pageX - container.offsetLeft;
  const walk = (x - startX.value) * 2; // Multiply by 2 for faster scrolling
  container.scrollLeft = scrollLeft.value - walk;
}

// Handle horizontal scroll for infinite loading with throttle
let scrollTimeout = null;
function handleStoreProductsScroll(e) {
  // Throttle scroll events to improve performance
  if (scrollTimeout) {
    clearTimeout(scrollTimeout);
  }

  scrollTimeout = setTimeout(() => {
    const container = e.target;
    const scrollLeft = container.scrollLeft;
    const scrollWidth = container.scrollWidth;
    const clientWidth = container.clientWidth;

    // Calculate how close we are to the end (within 100px of the end)
    const isNearEnd = scrollLeft + clientWidth >= scrollWidth - 100;

    // Load more when near the end and we have more products to load
    if (
      isNearEnd &&
      hasMoreStoreProducts.value &&
      !isLoadingMoreStoreProducts.value
    ) {
      loadMoreStoreProducts();
    }
  }, 150); // Throttle to 150ms
}

const cart = useStoreCart();
function addToCart(product, qty) {
  cart.addProduct(product, qty);
  navigateTo("/checkout/");
}

function calculateSavings(sale_price, regular_price) {
  if (!sale_price || !regular_price) return 0;

  const current =
    typeof sale_price === "string"
      ? Number(sale_price.replace(/,/g, ""))
      : Number(sale_price);

  const regular =
    typeof regular_price === "string"
      ? Number(regular_price.replace(/,/g, ""))
      : Number(regular_price);

  return (regular - current).toLocaleString();
}

function formatMemberSince(dateString) {
  if (!dateString) return "Unknown";

  try {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
    });
  } catch (error) {
    console.error("Error formatting date:", error);
    return "Unknown";
  }
}

// Dynamic rating computations
const capitalizedProductName = computed(() => {
  if (!currentProduct.name) return "";
  return (
    currentProduct.name.charAt(0).toUpperCase() + currentProduct.name.slice(1)
  );
});

const reviewCount = computed(() => {
  const count = productRatingStats.value?.total_reviews || 0;

  return count;
});

const averageRating = computed(() => {
  if (productRatingStats.value?.average_rating) {
    const rating = parseFloat(productRatingStats.value.average_rating).toFixed(
      1
    );

    return rating;
  }

  return "0.0";
});

const displayRating = computed(() => {
  const rating = parseFloat(averageRating.value);

  return rating;
});

// Review-specific computed properties
const isLoggedIn = computed(() => {
  if (!user.value) return false;

  // Check for nested user object or direct user object
  return !!(user.value.user?.id || user.value.id || user.value.username);
});

const displayName = computed(() => {
  if (!user.value) return "Guest";

  // Handle nested user object structure
  const userData = user.value.user || user.value;

  if (userData.first_name) {
    return `${userData.first_name} ${userData.last_name || ""}`.trim();
  }

  return userData.username || user.value.username || "User";
});

const reviewsCount = computed(() => {
  const count = productRatingStats.value?.total_reviews || 0;

  return count;
});

const reviewsAverageRating = computed(() => {
  if (productRatingStats.value?.average_rating) {
    const rating = parseFloat(productRatingStats.value.average_rating).toFixed(
      1
    );

    return rating;
  }

  return "0.0";
});

const isReviewValid = computed(() => {
  const hasRating = reviewForm.value.rating > 0;
  const hasComment = reviewForm.value.comment.trim().length > 0;

  // For logged-in users, only need rating and comment (name is auto-filled)
  if (isLoggedIn.value) {
    return hasRating && hasComment;
  }

  // For non-logged-in users, also need name (though they won't see the form)
  const hasName = reviewForm.value.name.trim().length > 0;
  return hasRating && hasComment && hasName;
});

const canSubmitReview = computed(() => {
  const result =
    isLoggedIn.value &&
    !userExistingReview.value &&
    !isCheckingUserReview.value;

  return result;
});

const displayedReviews = computed(() => {
  if (isLoadingReviews.value) {
    return []; // Show loading state
  }

  // Use API data directly since pagination is handled by backend
  return productReviews.value || [];
});

const paginationRange = computed(() => {
  if (totalReviewPages.value <= 5) {
    return Array.from({ length: totalReviewPages.value }, (_, i) => i + 1);
  }

  if (currentReviewPage.value <= 3) {
    return [1, 2, 3, 4, "...", totalReviewPages.value];
  }

  if (currentReviewPage.value >= totalReviewPages.value - 2) {
    return [
      1,
      "...",
      totalReviewPages.value - 3,
      totalReviewPages.value - 2,
      totalReviewPages.value - 1,
      totalReviewPages.value,
    ];
  }

  return [
    1,
    "...",
    currentReviewPage.value - 1,
    currentReviewPage.value,
    currentReviewPage.value + 1,
    "...",
    totalReviewPages.value,
  ];
});

const similarProductsTitle = computed(() => {
  if (similarProducts.value.length === 0) {
    return "You may also like";
  }

  if (!currentProduct?.category_details?.length) {
    return "You may also like";
  }

  // Get the primary category ID for comparison
  let primaryCategoryId = null;
  if (currentProduct.category) {
    if (Array.isArray(currentProduct.category)) {
      primaryCategoryId = currentProduct.category[0];
    } else if (
      typeof currentProduct.category === "string" &&
      currentProduct.category.includes(",")
    ) {
      primaryCategoryId = currentProduct.category.split(",")[0].trim();
    } else {
      primaryCategoryId = currentProduct.category;
    }
  } else if (
    currentProduct.category_details &&
    currentProduct.category_details.length > 0
  ) {
    primaryCategoryId = currentProduct.category_details[0].id;
  }

  // Show category-specific title based on loading phase
  if (isLoadingSameCategory.value || hasMoreSameCategoryProducts.value) {
    // Still loading same category products or more same category products available
    return `More from ${
      currentProduct.category_details[0]?.name || "this category"
    }`;
  }

  // Check if we have products from the same category
  const sameCategoryProducts = similarProducts.value.filter(
    (product) => product.category === primaryCategoryId
  );

  if (
    sameCategoryProducts.length > 0 &&
    sameCategoryProducts.length === similarProducts.value.length
  ) {
    // All currently loaded products are from the same category
    return `More from ${
      currentProduct.category_details[0]?.name || "this category"
    }`;
  } else if (sameCategoryProducts.length > 0) {
    // Mixed products from same and different categories
    return "You may also like";
  } else {
    // All products are from different categories (alternative products phase)
    return "You may also like";
  }
});

// Review API functions
async function fetchProductReviews(page = 1) {
  if (!currentProduct?.id) return;

  isLoadingReviews.value = true;
  try {
    const response = await get(
      `/reviews/products/${currentProduct.id}/reviews/`,
      {
        params: {
          page: page,
          page_size: reviewsPerPage,
        },
      }
    );

    if (response.data) {
      // Handle paginated response
      if (response.data.results) {
        productReviews.value = response.data.results;
        totalReviewCount.value = response.data.count || 0;
        totalReviewPages.value = Math.ceil(
          totalReviewCount.value / reviewsPerPage
        );
      } else if (Array.isArray(response.data)) {
        // Handle non-paginated response (fallback)
        productReviews.value = response.data;
        totalReviewCount.value = response.data.length;
        totalReviewPages.value = Math.ceil(
          totalReviewCount.value / reviewsPerPage
        );
      } else {
        productReviews.value = [];
        totalReviewCount.value = 0;
        totalReviewPages.value = 1;
      }
    } else {
      productReviews.value = [];
      totalReviewCount.value = 0;
      totalReviewPages.value = 1;
    }
  } catch (error) {
    console.error("Error fetching reviews:", error);
    productReviews.value = [];
    totalReviewCount.value = 0;
    totalReviewPages.value = 1;
  } finally {
    isLoadingReviews.value = false;
  }
}

async function checkUserExistingReview() {
  if (!currentProduct?.id || !isLoggedIn.value) {
    userExistingReview.value = null;
    return;
  }

  isCheckingUserReview.value = true;
  try {
    const response = await get(
      `/reviews/products/${currentProduct.id}/my-review/`
    );

    if (response.data) {
      userExistingReview.value = response.data;
    } else {
      userExistingReview.value = null;
    }
  } catch (error) {
    // 404 means no existing review found, which is expected
    if (error.response?.status === 404) {
      userExistingReview.value = null;
    } else {
      console.error("Error checking user review:", error);
      userExistingReview.value = null;
    }
  } finally {
    isCheckingUserReview.value = false;
  }
}

async function submitReview() {
  if (!isReviewValid.value || !isLoggedIn.value || !currentProduct?.id) {
    return;
  }

  isSubmittingReview.value = true;

  try {
    const reviewData = {
      rating: reviewForm.value.rating,
      comment: reviewForm.value.comment.trim(),
      // Don't send name - it will be set from the authenticated user
    };

    const response = await post(
      `/reviews/products/${currentProduct.id}/reviews/`,
      reviewData
    );

    if (response.data) {
      // Show success message using Nuxt UI toast
      const toast = useToast();
      toast.add({
        title: "Review Submitted",
        description:
          "Thank you for your feedback! Your review has been submitted successfully.",
        color: "blue",
        timeout: 5000,
      });

      try {
        await fetchProductReviews(1); // Go back to first page to show the new review
      } catch (reviewsError) {
        console.error("Error refreshing reviews:", reviewsError);
      }

      try {
        await fetchProductRatingStats();
      } catch (statsError) {
        console.error("Error refreshing rating stats:", statsError);
      }

      try {
        await checkUserExistingReview();
      } catch (userReviewError) {
        console.error("Error refreshing user review status:", userReviewError);
      }

      // Reset form

      reviewForm.value = {
        name: "",
        rating: 0,
        comment: "",
      };

      // Reset to first page to potentially show the newly added review
      currentReviewPage.value = 1;
    }
  } catch (error) {
    console.error("Error submitting review:", error);

    // Show error message using Nuxt UI toast
    const toast = useToast();
    let errorMessage = "Failed to submit review. Please try again.";

    if (error.response?.data?.detail) {
      errorMessage = error.response.data.detail;
    } else if (error.response?.data?.message) {
      errorMessage = error.response.data.message;
    } else if (error.response?.data?.non_field_errors) {
      errorMessage = error.response.data.non_field_errors[0];
    }

    toast.add({
      title: "Error Submitting Review",
      description: errorMessage,
      color: "red",
      timeout: 5000,
    });
  } finally {
    // Ensure this always runs regardless of what happens above

    isSubmittingReview.value = false;

    // Force reactivity update
  }
}

function getRatingPercentage(rating) {
  if (!productRatingStats.value) return "0%";

  const total = productRatingStats.value.total_reviews;
  if (total === 0) return "0%";

  const count = productRatingStats.value[`rating_${rating}_count`] || 0;
  return `${((count / total) * 100).toFixed(1)}%`;
}

function getRatingCount(rating) {
  if (!productRatingStats.value) return 0;
  return productRatingStats.value[`rating_${rating}_count`] || 0;
}

// Pagination navigation functions
async function goToReviewPage(page) {
  if (page !== currentReviewPage.value) {
    currentReviewPage.value = page;
    await fetchProductReviews(page);
  }
}

async function previousReviewPage() {
  if (currentReviewPage.value > 1) {
    const newPage = currentReviewPage.value - 1;
    currentReviewPage.value = newPage;
    await fetchProductReviews(newPage);
  }
}

async function nextReviewPage() {
  if (currentReviewPage.value < totalReviewPages.value) {
    const newPage = currentReviewPage.value + 1;
    currentReviewPage.value = newPage;
    await fetchProductReviews(newPage);
  }
}

// Reset selected image when product changes
watch(
  () => currentProduct?.id,
  async (newId, oldId) => {
    selectedImageIndex.value = 0;
    quantity.value = 1;

    if (newId !== oldId) {
      // Clean up intersection observer
      if (intersectionObserver) {
        intersectionObserver.disconnect();
        intersectionObserver = null;
      }

      // Reset similar products state
      similarProducts.value = [];
      similarProductsPage.value = 1;
      hasMoreSimilarProducts.value = true;
      allLoadedSimilarProducts.value = [];

      // Reset store products state
      storeProducts.value = [];
      storeProductsPage.value = 1;
      hasMoreStoreProducts.value = true;
      totalStoreProducts.value = 0;

      // Reset category-specific state
      sameCategoryPage.value = 1;
      hasMoreSameCategoryProducts.value = true;
      isLoadingSameCategory.value = true;
      allLoadedSameCategoryProducts.value = [];
    }

    // Fetch data for the new product
    await Promise.all([
      fetchProductReviews(1), // Start from page 1
      fetchProductRatingStats(),
      checkUserExistingReview(),
      fetchSimilarProducts(1), // Fetch first page of similar products
      fetchStoreProducts(1), // Fetch first page of store products
    ]);

    // Setup infinite scroll after products are loaded
    if (similarProducts.value.length > 0) {
      setupInfiniteScroll();
    }
  },
  { immediate: true } // Fetch immediately on component creation
);

// Auto-scroll to reviews when page changes
watch(currentReviewPage, () => {
  // Smooth scroll to the reviews section on page change
  const reviewsSection = document.querySelector(".customer-reviews-section");
  if (reviewsSection) {
    setTimeout(() => {
      reviewsSection.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 300); // Increased timeout to allow for API response
  }
});

// Watch for user login status changes to check for existing review
watch(isLoggedIn, async (newValue) => {
  if (newValue) {
    await checkUserExistingReview();
  } else {
    userExistingReview.value = null;
  }
});

// Cleanup intersection observer on component unmount
onUnmounted(() => {
  if (intersectionObserver) {
    intersectionObserver.disconnect();
    intersectionObserver = null;
  }

  // Clear scroll timeout
  if (scrollTimeout) {
    clearTimeout(scrollTimeout);
    scrollTimeout = null;
  }
});
</script>

<style scoped>
/* Rating stars component styling */
.rating-stars {
  position: relative;
  display: inline-flex;
}

.prose img {
  border-radius: 0.5rem;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

/* Hide scrollbar for clean mobile experience */
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
.hide-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

/* Optimized animations for better performance */
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translate3d(0, 5px, 0);
  }
  to {
    opacity: 1;
    transform: translate3d(0, 0, 0);
  }
}

.similar-product-fade-in {
  animation: fade-in 0.2s ease-out forwards;
  will-change: transform, opacity;
}

.similar-product-fade-in:hover {
  opacity: 0.9;
  transition: opacity 0.15s ease;
}
</style>
