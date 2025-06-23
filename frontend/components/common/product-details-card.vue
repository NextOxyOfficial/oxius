<template>
  <UCard
    v-if="currentProduct"
    class="p-0 overflow-hidden border-none shadow-sm"
    :ui="{
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
              color="green"
              class="mr-2"
            >
              In Stock
            </UBadge>
            <UBadge v-else color="red"> Out of Stock </UBadge>
          </div>
          <div class="flex gap-3 justify-between items-start">
            <h3
              class="text-lg ml-1 md:text-lg font-medium text-primary-700 dark:text-primary-300 text-left"
            >
              {{ capitalizedProductName }}
            </h3>
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
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-8">
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
                class="absolute inset-0 w-full h-full object-contain p-2"
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
                class="absolute top-2 right-2 bg-green-500 text-white text-sm font-medium px-3 py-1 rounded-full shadow-sm"
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
          <!-- Category Name -->
          <div
            class="flex items-center gap-2 mb-2"
            v-if="currentProduct?.category_details?.length > 0"
          >
            <UBadge
              color="gray"
              variant="subtle"
              class="uppercase text-xs tracking-wider"
            >
              {{ currentProduct?.category_details[0]?.name || "Uncategorized" }}
            </UBadge>
            <div
              v-if="currentProduct.weight && currentProduct.weight > 0"
              class="text-xs text-slate-500"
            >
              Weight: {{ currentProduct.weight }}kg
            </div>
          </div>
          <!-- Ratings section with dynamic data -->
          <div class="flex items-center gap-2 mb-4">
            <div class="rating-stars relative inline-block">
              <!-- Background stars -->
              <div class="flex">
                <UIcon
                  v-for="n in 5"
                  :key="`bg-${n}`"
                  name="i-heroicons-star"
                  class="w-5 h-5 text-slate-200 dark:text-slate-700"
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
                  class="w-5 h-5 text-yellow-400"
                />
              </div>
            </div>

            <span
              class="text-sm font-medium text-slate-700 dark:text-slate-300"
            >
              {{ averageRating }} ({{ reviewCount }} reviews)
            </span>
          </div>

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
                class="savings-badge bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-md ml-auto animate-pulse"
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
                    ? 'text-green-600 dark:text-green-400'
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
              class="flex-1 relative overflow-hidden group bg-gradient-to-r from-primary-600 to-primary-500 hover:from-primary-500 hover:to-primary-400 rounded-lg py-3 px-6 text-white font-medium shadow-sm hover:shadow-sm transition-colors duration-200"
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
                  class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5"
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
                  class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5"
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
                  class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5"
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
              <div class="flex items-center gap-2">
                <NuxtLink
                  v-if="
                    currentProduct.owner_details?.store_username ||
                    currentProduct.owner_details?.id
                  "
                  :to="`/eshop/${
                    currentProduct.owner_details?.store_username ||
                    currentProduct.owner_details?.id
                  }`"
                  class="hover:text-emerald-600 transition-colors"
                >
                  <h4
                    class="font-medium text-green-800 dark:text-white truncate"
                  >
                    {{
                      currentProduct.owner_details?.store_name ||
                      "Anonymous Seller"
                    }}
                  </h4>
                </NuxtLink>
                <h4
                  v-else
                  class="font-medium text-gray-800 dark:text-white truncate"
                >
                  {{
                    currentProduct.owner_details?.store_name ||
                    "Anonymous Seller"
                  }}
                </h4>
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
                  size="xs"
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
                {{ currentProduct.owner_details?.date_joined }}
              </span>
            </div>
          </div>

          <!-- Contact Actions -->
          <div
            class="p-4 bg-slate-100 dark:bg-slate-800/80 flex flex-wrap gap-3"
          >
            <!-- Call Button -->
            <UButton
              v-if="currentProduct.seller?.phone"
              color="primary"
              variant="soft"
              size="sm"
              class="flex-1 min-w-0 sm:flex-initial"
              :to="`tel:${currentProduct.seller?.phone}`"
              icon="i-heroicons-phone"
            >
              Call Seller
            </UButton>

            <!-- WhatsApp Button -->
            <UButton
              v-if="
                currentProduct.seller?.whatsapp || currentProduct.seller?.phone
              "
              color="green"
              variant="soft"
              size="sm"
              class="flex-1 min-w-0 sm:flex-initial"
              :to="`https://wa.me/${
                currentProduct.seller?.whatsapp || currentProduct.seller?.phone
              }`"
              target="_blank"
              icon="i-heroicons-chat-bubble-left-right"
            >
              WhatsApp
            </UButton>

            <!-- Store Button -->
            <UButton
              v-if="
                currentProduct.owner_details?.store_username ||
                currentProduct.owner_details?.id
              "
              color="gray"
              variant="soft"
              size="sm"
              class="flex-1 min-w-0 sm:flex-initial"
              :to="`/eshop/${
                currentProduct.owner_details?.store_username ||
                currentProduct.owner_details?.id
              }`"
              icon="i-heroicons-building-storefront"
            >
              Visit Store
            </UButton>
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
              name="i-heroicons-document-text"
              class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
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

          <!-- Reviews Summary -->
          <div class="bg-white dark:bg-slate-800/80 rounded-xl shadow-sm p-6">
            <div class="flex flex-col md:flex-row gap-6 md:items-center">
              <div
                class="text-center md:border-r md:border-slate-200 dark:md:border-slate-700 md:pr-6"
              >
                <div
                  class="text-2xl font-semibold text-gray-800 dark:text-white mb-2"
                >
                  {{ reviewsAverageRating }}
                </div>
                <div class="flex justify-center text-amber-400 my-1">
                  <UIcon
                    v-for="i in 5"
                    :key="i"
                    :name="
                      i <= Math.round(parseFloat(reviewsAverageRating))
                        ? 'i-heroicons-star-solid'
                        : 'i-heroicons-star'
                    "
                    class="w-6 h-6"
                    :class="
                      i <= Math.round(parseFloat(reviewsAverageRating))
                        ? 'text-amber-400'
                        : 'text-gray-300 dark:text-gray-600'
                    "
                  />
                </div>
                <div class="text-sm text-slate-500 dark:text-slate-400">
                  Based on {{ reviewsCount }} reviews
                </div>
              </div>

              <div class="flex-1 space-y-2">
                <div v-for="n in 5" :key="n" class="flex items-center">
                  <div class="text-sm w-5 text-right mr-3">
                    {{ 6 - n }}
                  </div>
                  <UIcon
                    name="i-heroicons-star-solid"
                    class="w-4 h-4 text-amber-400 mr-2"
                  />
                  <div
                    class="flex-1 h-2.5 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden"
                  >
                    <div
                      class="h-full bg-amber-400"
                      :style="{ width: getRatingPercentage(6 - n) }"
                    ></div>
                  </div>
                  <div class="text-sm w-10 text-left ml-3">
                    {{ getRatingCount(6 - n) }}
                  </div>
                </div>
              </div>
            </div>
          </div>

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
                  <div
                    class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-3 text-primary-700 dark:text-primary-300 font-medium"
                  >
                    {{
                      review.user?.display_name?.charAt(0) ||
                      review.reviewer_name?.charAt(0) ||
                      "U"
                    }}
                  </div>
                  <div>
                    <div class="font-medium text-gray-800 dark:text-white">
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

            <!-- Empty state -->
            <div v-else class="text-center">
              <UIcon
                name="i-heroicons-chat-bubble-bottom-center-text"
                class="w-16 h-16 text-gray-300 dark:text-gray-600 mx-auto my-2"
              />
              <p class="text-gray-500 dark:text-gray-400 text-lg">
                No reviews yet
              </p>
              <p class="text-gray-400 dark:text-gray-500 text-sm">
                Be the first to share your experience!
              </p>
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
            <!-- Only show title if user can submit a review or needs to log in -->
            <h3
              v-if="
                !isLoggedIn || (!userExistingReview && !isCheckingUserReview)
              "
              class="text-xl font-semibold mb-4 text-center"
            >
              Share Your Experience
            </h3>

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
                class="w-12 h-12 text-green-500 mx-auto mb-4"
              />
              <h4
                class="text-lg font-medium mb-2 text-green-700 dark:text-green-400"
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
        </div>        <!-- You may also like Section -->
        <div class="bg-slate-50 dark:bg-slate-800/30 rounded-xl">
          <h3
            class="text-base font-medium py-3 px-2 text-gray-800 dark:text-white flex items-center"
          >
            <UIcon
              name="i-heroicons-squares-2x2"
              class="w-5 h-5 mr-2 text-primary-600 dark:text-primary-400"
            />
            {{ similarProductsTitle }}
          </h3>
          <div v-if="isSimilarProductsLoading" class="flex justify-center py-6">
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
                Loading similar products...
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
          </div>          <div v-else>
            <!-- Mobile Similar Products - Horizontal scroll with multiple items -->
            <div class="sm:hidden">
              <div class="flex overflow-x-auto gap-3 py-2 px-2 hide-scrollbar">
                <div
                  v-for="(product, index) in similarProducts"
                  :key="`mobile-${product.id}`"
                  class="flex-shrink-0 w-[45%] similar-product-fade-in"
                  style="animation-delay: calc(var(--i) * 0.1s)"
                  :style="{ '--i': index }"
                >
                  <CommonProductCard :product="product" />
                </div>
              </div>
            </div>
            
            <!-- Desktop Similar Products - 4 items in a single row -->
            <div
              class="hidden sm:grid sm:grid-cols-4 gap-3 px-2 pb-4"
            >
              <div
                v-for="(product, index) in similarProducts.slice(0, 4)"
                :key="`desktop-${product.id}`"
                class="similar-product-fade-in"
                style="animation-delay: calc(var(--i) * 0.1s)"
                :style="{ '--i': index }"
              >
                <CommonProductCard :product="product" />
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

<script setup>
const { currentProduct, modal, seeDetails } = defineProps({
  currentProduct: { type: Object, required: true },
  modal: { type: Boolean, required: false },
  seeDetails: { type: Boolean, required: false },
});

const emit = defineEmits(["close-modal", "open-message-modal"]);
const selectedImageIndex = ref(0);
const quantity = ref(1);
const similarProducts = ref([]);
const isSimilarProductsLoading = ref(false);

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

// Fetch similar products based on the current product's category
async function fetchSimilarProducts() {
  if (!currentProduct) return;

  isSimilarProductsLoading.value = true;
  const targetCount = 8; // Target number of similar products to show (more for mobile scroll)

  try {
    const { get } = useApi();
    let similarProductsList = [];

    // First, try to get products from the same category
    if (currentProduct.category) {
      try {
        let queryParams = `category=${currentProduct.category}&page_size=12&ordering=random`;
        const sameCategory = await get(`/all-products/?${queryParams}`);
        
        if (sameCategory && sameCategory.data && sameCategory.data.results) {
          // Filter out current product
          const sameCategoryProducts = sameCategory.data.results
            .filter((product) => product.id !== currentProduct.id);
          
          similarProductsList.push(...sameCategoryProducts);
        }
      } catch (error) {
        console.error("Error fetching same category products:", error);
      }
    }

    // If we don't have enough products from the same category, fetch from other categories
    if (similarProductsList.length < targetCount) {
      try {
        const remainingCount = targetCount - similarProductsList.length + 6; // Get a few extra for filtering
        let additionalQueryParams = `page_size=${remainingCount}&ordering=random`;
        
        // Exclude current category if it exists
        if (currentProduct.category) {
          additionalQueryParams += `&exclude_category=${currentProduct.category}`;
        }

        const additionalResponse = await get(`/all-products/?${additionalQueryParams}`);
        
        if (additionalResponse && additionalResponse.data && additionalResponse.data.results) {
          const additionalProducts = additionalResponse.data.results
            .filter((product) => 
              product.id !== currentProduct.id && 
              !similarProductsList.some(existing => existing.id === product.id)
            );
          
          similarProductsList.push(...additionalProducts);
        }
      } catch (error) {
        console.error("Error fetching additional category products:", error);
      }
    }

    // If we still don't have enough, get any random products as fallback
    if (similarProductsList.length < targetCount) {
      try {
        const fallbackCount = targetCount - similarProductsList.length + 4;
        const fallbackResponse = await get(`/all-products/?page_size=${fallbackCount}&ordering=random`);
        
        if (fallbackResponse && fallbackResponse.data && fallbackResponse.data.results) {
          const fallbackProducts = fallbackResponse.data.results
            .filter((product) => 
              product.id !== currentProduct.id && 
              !similarProductsList.some(existing => existing.id === product.id)
            );
          
          similarProductsList.push(...fallbackProducts);
        }
      } catch (error) {
        console.error("Error fetching fallback products:", error);
      }
    }

    // Shuffle the final list and limit to target count
    similarProducts.value = similarProductsList
      .sort(() => Math.random() - 0.5)
      .slice(0, targetCount);

  } catch (error) {
    console.error("Error fetching similar products:", error);
    similarProducts.value = [];
  } finally {
    isSimilarProductsLoading.value = false;
  }
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
  
  // Check if we have products from the same category
  const sameCategoryProducts = similarProducts.value.filter(product => 
    product.category === currentProduct.category
  );
  
  if (sameCategoryProducts.length === similarProducts.value.length) {
    // All products are from the same category
    return `More from ${currentProduct.category_details[0]?.name || 'this category'}`;
  } else if (sameCategoryProducts.length > 0) {
    // Mixed products from same and different categories
    return "You may also like";
  } else {
    // All products are from different categories
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
        color: "green",
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

    // Fetch data for the new product

    fetchSimilarProducts(); // Fetch similar products when current product changes
    await Promise.all([
      fetchProductReviews(1), // Start from page 1
      fetchProductRatingStats(),
      checkUserExistingReview(),
    ]);
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
