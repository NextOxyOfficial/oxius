<template>
  <div class="product-sales-funnel w-full">
    <!-- Hero Section -->
    <section
      class="hero-section bg-gradient-to-br from-slate-900 to-slate-800 text-white rounded-xl overflow-hidden w-full"
    >
      <div class="px-6 py-2 md:py-20 w-full">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <!-- Product Image -->
          <div class="relative order-2 md:order-1">
            <div
              class="aspect-square rounded-xl overflow-hidden bg-white/10 backdrop-blur-sm p-6 shadow-sm relative"
            >
              <img
                v-if="
                  currentProduct.image_details &&
                  currentProduct.image_details.length > 0
                "
                :src="currentProduct.image_details[0].image"
                :alt="currentProduct.name"
                class="w-full h-full object-contain"
              />
              <!-- Sale badge -->
              <div
                v-if="currentProduct.sale_price && currentProduct.regular_price"
                class="absolute top-4 right-4 bg-red-500 text-white text-sm font-semibold px-3 py-1.5 rounded-full shadow-sm animate-pulse"
              >
                SAVE
                {{
                  calculateDiscountPercentage(
                    currentProduct.regular_price,
                    currentProduct.sale_price
                  )
                }}%
              </div>
            </div>
          </div>

          <!-- Product Headline -->
          <div class="order-1 md:order-2">
            <span
              class="inline-block px-3 py-1 bg-primary-500/20 text-primary-400 rounded-full text-xs uppercase font-semibold mb-4"
            >
              {{ currentProduct.category_details?.name || "Premium Product" }}
            </span>
            <h1 class="text-2xl md:text-2xl lg:text-2xl font-semibold mb-4">
              {{ currentProduct.name }}
            </h1>
            <div class="flex items-center mb-4">
              <div class="flex text-amber-400">
                <UIcon
                  v-for="n in 5"
                  :key="n"
                  name="i-heroicons-star-solid"
                  class="w-5 h-5"
                />
              </div>
              <span class="text-sm text-white/70 ml-2">
                {{ reviewCount }} verified reviews
              </span>
            </div>
            <p class="text-lg text-white/80 mb-6">
              {{
                currentProduct.short_description ||
                "Experience the ultimate product designed to transform your life. Premium quality, outstanding performance, and exceptional value."
              }}
            </p>

            <!-- Price Section -->
            <div class="flex items-baseline mb-8">
              <span class="text-2xl font-semibold text-white">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </span>
              <span
                v-if="currentProduct.regular_price && currentProduct.sale_price"
                class="text-lg text-white/60 line-through ml-2"
              >
                ৳{{ currentProduct.regular_price }}
              </span>

              <!-- Stock indicator next to price -->
              <div class="ml-4 flex items-center">
                <div
                  v-if="currentProduct.quantity > 0"
                  class="flex items-center text-sm"
                >
                  <span
                    class="inline-block w-2 h-2 rounded-full mr-1.5"
                    :class="
                      currentProduct.quantity > 10
                        ? 'bg-green-400'
                        : 'bg-amber-400'
                    "
                  ></span>
                </div>
                <div v-else class="flex items-center text-sm">
                  <span
                    class="inline-block w-2 h-2 rounded-full bg-red-500 mr-1.5"
                  ></span>
                  <span class="text-white/80">Out of Stock</span>
                </div>
              </div>
            </div>

            <!-- Add Stock Count, Weight & Delivery Status Badges -->
            <div class="flex flex-wrap gap-2 mb-4">
              <!-- Stock Status Badge -->
              <div
                class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium"
                :class="
                  currentProduct.quantity > 10
                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                    : currentProduct.quantity > 0
                    ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400'
                    : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
                "
              >
                <UIcon name="i-heroicons-cube" class="w-4 h-4 mr-1" />
                <span v-if="currentProduct.quantity > 10"
                  >In Stock ({{ currentProduct.quantity }})</span
                >
                <span v-else-if="currentProduct.quantity > 0"
                  >Only {{ currentProduct.quantity }} left!</span
                >
                <span v-else>Out of Stock</span>
              </div>

              <!-- Weight Badge - Always show weight if available -->
              <div
                v-if="currentProduct.weight"
                class="inline-flex items-center px-3 py-1 bg-slate-100 dark:bg-slate-800/60 text-slate-700 dark:text-slate-300 rounded-full text-sm font-medium"
              >
                <UIcon name="i-heroicons-scale" class="w-4 h-4 mr-1" />
                Weight: {{ currentProduct.weight }}kg
              </div>

              <!-- Free Delivery Badge - Only show if free delivery -->
              <div
                v-if="currentProduct.is_free_delivery"
                class="inline-flex items-center px-3 py-1 bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400 rounded-full text-sm font-medium"
              >
                <UIcon name="i-heroicons-gift" class="w-4 h-4 mr-1" />
                Free Delivery
              </div>
            </div>

            <!-- Primary CTA Button -->
            <button
              @click="addToCart(currentProduct, 1)"
              class="w-full md:w-auto px-8 py-4 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white text-lg font-semibold rounded-xl shadow-sm hover:shadow-sm transition-all duration-300 focus:ring-4 focus:ring-primary-500/50 flex items-center justify-center gap-3 group"
            >
              <UIcon name="i-heroicons-shopping-cart" class="w-6 h-6" />
              Buy Now
              <span
                class="group-hover:translate-x-1 transition-transform duration-300"
              >
                <UIcon name="i-heroicons-arrow-right" class="w-5 h-5" />
              </span>
            </button>

            <!-- Trust Badges -->
            <div
              class="flex flex-wrap justify-center md:justify-start gap-4 mt-8"
            >
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-shield-check"
                  class="w-5 h-5 text-emerald-400"
                />
                <span class="text-xs text-white/70">Secure Payment</span>
              </div>
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-truck"
                  class="w-5 h-5 text-emerald-400"
                />
                <span class="text-xs text-white/70">Fast Delivery</span>
              </div>
              <div class="flex items-center gap-1.5">
                <UIcon
                  name="i-heroicons-arrow-path"
                  class="w-5 h-5 text-emerald-400"
                />
                <span class="text-xs text-white/70">30-Day Returns</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Description Section -->
    <section class="w-full my-6">
      <div class="bg-slate-50 dark:bg-slate-800/20 rounded-lg p-6">
        <div class="prose prose-slate dark:prose-invert max-w-none">
          <div
            v-if="currentProduct.description"
            v-html="currentProduct.description"
          ></div>
          <p v-else>
            This premium product offers exceptional performance and reliability.
            Built with high-quality materials and expert craftsmanship, it's
            designed to exceed your expectations. The ergonomic design ensures
            comfortable use while the durable construction guarantees
            long-lasting performance.
          </p>
        </div>
      </div>
    </section>

    <!-- Key Benefits Section -->
    <section class="py-2 w-full">
      <h2 class="text-xl md:text-2xl font-semibold text-center mb-6">
        {{ currentProduct.benefits_title }}
        <span class="text-primary-600 dark:text-primary-400">{{
          currentProduct.name
        }}</span
        >?
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div
          v-for="benefit in currentProduct?.benefits"
          :key="benefit.id"
          class="benefit-card"
        >
          <div class="icon-container">
            <UIcon :name="benefit.icon" class="w-8 h-8 text-primary-500" />
          </div>
          <h3 class="text-xl font-semibold mb-2">{{ benefit.title }}</h3>
          <p>
            {{ benefit.description }}
          </p>
        </div>
      </div>

      <div class="text-center mt-6">
        <button
          @click="addToCart(currentProduct, 1)"
          class="px-8 py-3 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white font-semibold rounded-xl shadow-sm transition-all duration-300"
        >
          {{ currentProduct.benefits_cta }}
        </button>
      </div>
    </section>

    <!-- Shipping Information Section -->
    <section
      class="pt-10 pb-2 bg-slate-50 dark:bg-slate-800/30 rounded-xl w-full"
    >
      <div class="w-full px-6">
        <h2 class="text-xl md:text-2xl font-semibold text-center mb-4">
          Shipping Information
        </h2>
        <p class="text-center text-gray-600 dark:text-slate-300 mb-6">
          Fast and reliable delivery options for {{ currentProduct.name }}
        </p>

        <div class="py-6 max-w-3xl mx-auto">
          <div
            class="mb-6 p-4 rounded-lg"
            :class="{
              'bg-green-50 dark:bg-green-900/20 border-green-100 dark:border-green-900':
                currentProduct.is_free_delivery,
              'bg-blue-50 dark:bg-blue-900/20 border-blue-100 dark:border-blue-900':
                !currentProduct.is_free_delivery,
            }"
          >
            <div class="flex items-start">
              <UIcon
                :name="
                  currentProduct.is_free_delivery
                    ? 'i-heroicons-gift'
                    : 'i-heroicons-information-circle'
                "
                :class="
                  currentProduct.is_free_delivery
                    ? 'w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 mr-2 flex-shrink-0'
                    : 'w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 mr-2 flex-shrink-0'
                "
              />
              <p
                :class="
                  currentProduct.is_free_delivery
                    ? 'text-green-800 dark:text-green-300 text-sm'
                    : 'text-blue-800 dark:text-blue-300 text-sm'
                "
              >
                <template v-if="currentProduct.is_free_delivery">
                  <strong>Free shipping available!</strong> This product
                  qualifies for free delivery nationwide.
                </template>
                <template v-else>
                  <strong>Shipping information:</strong> Standard delivery rates
                  apply. Orders over ৳5,000 qualify for free delivery.
                </template>
              </p>
            </div>
          </div>

          <div class="space-y-4">
            <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-truck"
                    class="w-5 h-5 text-gray-600 dark:text-slate-300 mr-2"
                  />
                  <h4 class="font-medium">Inside Dhaka</h4>
                </div>
                <div class="font-semibold">
                  ৳{{ currentProduct.delivery_fee_inside_dhaka || "100" }}
                </div>
              </div>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                Estimated delivery: 2-3 business days
              </p>
            </div>

            <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <UIcon
                    name="i-heroicons-truck"
                    class="w-5 h-5 text-gray-600 dark:text-slate-300 mr-2"
                  />
                  <h4 class="font-medium">Outside Dhaka</h4>
                </div>
                <div class="font-semibold">
                  ৳{{ currentProduct.delivery_fee_outside_dhaka || "150" }}
                </div>
              </div>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                Estimated delivery: 3-5 business days
              </p>
            </div>

            <div class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm">
              <div class="flex items-center">
                <UIcon
                  name="i-heroicons-gift"
                  class="w-5 h-5 text-gray-600 dark:text-slate-300 mr-2"
                />
                <h4 class="font-medium">Premium Packaging</h4>
              </div>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                All products are securely packed to ensure safe delivery
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Customer Reviews Section -->
    <section class="pb-2 pt-10 w-full customer-reviews-section">
      <div class="w-full px-3">
        <h2 class="text-xl md:text-2xl font-semibold text-center mb-4">
          Customer Reviews
        </h2>
        <p class="text-center text-gray-600 dark:text-slate-300 mb-6">
          Join thousands of satisfied customers who have experienced the
          difference
        </p>

        <!-- Reviews Summary -->
        <div
          class="mb-10 bg-white dark:bg-slate-800/80 rounded-xl shadow-sm p-6 max-w-4xl mx-auto"
        >
          <div class="flex flex-col md:flex-row gap-6 md:items-center">
            <div
              class="text-center md:border-r md:border-slate-200 dark:md:border-slate-700 md:pr-6"
            >
              <div
                class="text-2xl font-semibold text-gray-800 dark:text-white mb-2"
              >
                {{ averageRating }}
              </div>
              <div class="flex justify-center text-amber-400 my-1">
                <UIcon
                  v-for="i in 5"
                  :key="i"
                  name="i-heroicons-star-solid"
                  class="w-6 h-6"
                />
              </div>
              <div class="text-sm text-slate-500 dark:text-slate-400">
                Based on {{ reviewCount }} reviews
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
        </div>        <!-- Featured Reviews with Pagination -->
        <div class="max-w-6xl mx-auto mb-10">
          <!-- Loading state -->
          <div v-if="isLoadingReviews" class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div 
              v-for="n in 3" 
              :key="n"
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm p-6 animate-pulse"
            >
              <div class="flex mb-3">
                <div v-for="i in 5" :key="i" class="w-5 h-5 bg-gray-200 dark:bg-gray-700 rounded mr-1"></div>
              </div>
              <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
              <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-4 w-3/4"></div>
              <div class="flex items-center">
                <div class="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-full mr-3"></div>
                <div>
                  <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-1 w-20"></div>
                  <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded w-16"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Reviews grid -->
          <div v-else-if="displayedReviews.length > 0" class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div
              v-for="(review, index) in displayedReviews"
              :key="review.id || index"
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm p-6 transition-transform hover:translate-y-[-5px]"
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
              </div>              <p class="text-gray-600 dark:text-slate-300 mb-4">
                "{{ review.comment }}"
              </p>
              <div class="flex items-center">                <div
                  class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-3 text-primary-700 dark:text-primary-300 font-medium"
                >
                  {{ review.user?.display_name?.charAt(0) || review.reviewer_name?.charAt(0) || "U" }}
                </div>
                <div>
                  <div class="font-medium text-gray-800 dark:text-white">
                    {{ review.user?.display_name || review.reviewer_name || "Anonymous" }}
                  </div>
                  <div class="text-xs text-slate-500 dark:text-slate-400">
                    {{ review.formatted_date || "Verified Purchase" }}
                  </div></div>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div v-else class="text-center">
            <UIcon 
              name="i-heroicons-chat-bubble-bottom-center-text" 
              class="w-16 h-16 text-gray-300 dark:text-gray-600 mx-auto mb-4"
            />
            <h3 class="text-lg font-medium text-gray-800 dark:text-white mb-2">
              No Reviews Yet
            </h3>
            <p class="text-gray-600 dark:text-gray-400 mb-4">
              Be the first to share your experience with this product!
            </p>
          </div>

          <!-- Pagination controls -->
          <div
            class="flex justify-center items-center mt-8 gap-2"
            v-if="totalReviewPages > 1"
          >
            <!-- Previous button -->
            <UButton
              icon="i-heroicons-chevron-left"
              color="gray"
              variant="ghost"
              :disabled="currentReviewPage === 1"
              @click="previousReviewPage"
              size="sm"
              class="rounded-full"
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
              :disabled="currentReviewPage === totalReviewPages"
              @click="nextReviewPage"
              size="sm"
              class="rounded-full"
            />
          </div>
        </div>        <!-- Write a Review Section (Updated) -->
        <div
          class=" bg-slate-50 dark:bg-slate-800/50 rounded-xl p-2 max-w-3xl mx-auto"
        >
          <!-- Only show title if user can submit a review or needs to log in -->
          <h3 
            v-if="!isLoggedIn || (!userExistingReview && !isCheckingUserReview)" 
            class="text-xl font-semibold mb-4 text-center"
          >
            Share Your Experience
          </h3>

          <!-- Loading state for checking user review -->
          <div v-if="isCheckingUserReview" class="text-center p-6">
            <div class="animate-spin w-8 h-8 border-2 border-primary-500 border-t-transparent rounded-full mx-auto mb-4"></div>
            <p class="text-gray-600 dark:text-slate-400">Checking your review status...</p>
          </div>

          <!-- User has already submitted a review -->
          <div v-else-if="isLoggedIn && userExistingReview" class="text-center p-6">
            <UIcon
              name="i-heroicons-check-circle"
              class="w-12 h-12 text-green-500 mx-auto mb-4"
            />
            <h4 class="text-lg font-medium mb-2 text-green-700 dark:text-green-400">Thank You for Your Review!</h4>
            <p class="text-gray-600 dark:text-slate-400 mb-4">
              You have already submitted a review for this product.
            </p>
            
            <!-- Show the user's existing review -->
            <div class="bg-white dark:bg-slate-700 rounded-lg p-4 text-left max-w-md mx-auto">
              <div class="flex text-amber-400 mb-2">
                <UIcon
                  v-for="star in 5"
                  :key="star"
                  :name="star <= userExistingReview.rating ? 'i-heroicons-star-solid' : 'i-heroicons-star'"
                  class="w-4 h-4"
                  :class="star <= userExistingReview.rating ? 'text-amber-400' : 'text-gray-300'"
                />
                <span class="ml-2 text-sm text-gray-600 dark:text-slate-400">Your Rating</span>
              </div>
              <p class="text-gray-700 dark:text-slate-300 text-sm">
                "{{ userExistingReview.comment }}"
              </p>
              <p class="text-xs text-gray-500 dark:text-slate-500 mt-2">
                Submitted {{ userExistingReview.formatted_date || 'recently' }}
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
              </div>              <div>
                <label
                  class="block text-sm mb-1 text-gray-600 dark:text-slate-300"
                >
                  Your Name
                </label>
                <div class="px-3 py-2 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-md text-gray-800 dark:text-white font-medium">
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
                  {{ isSubmittingReview ? 'Submitting...' : 'Submit Review' }}
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
    </section>

    <!-- FAQ Section -->
    <section class="py-2 w-full">
      <div class="w-full px-3 max-w-4xl mx-auto">
        <h2 class="text-xl md:text-2xl font-semibold text-center mb-4">
          {{ currentProduct.faqs_title }}
        </h2>
        <p class="text-center text-gray-600 dark:text-slate-300 mb-6">
          {{ currentProduct.faqs_subtitle }}
        </p>

        <div>
          <UAccordion :items="currentProduct?.faqs" />
        </div>
      </div>
    </section>

    <!-- Final CTA Section -->
    <section
      class="py-2 bg-gradient-to-br from-primary-600 to-primary-800 text-white rounded-xl my-6 w-full"
    >
      <div class="px-6 py-8 text-center w-full">
        <h2 class="text-2xl md:text-2xl font-semibold mb-6">
          {{ currentProduct.cta_title }}
        </h2>
        <p class="text-white/80 mb-8 text-lg max-w-3xl mx-auto">
          {{ currentProduct.cta_subtitle }} {{ currentProduct.name }}.
        </p>

        <!-- Price Box -->
        <div
          class="mb-8 inline-block bg-white/10 backdrop-blur-sm rounded-xl p-6 mx-auto"
        >
          <div class="flex items-center justify-center gap-4">
            <div class="text-center">
              <div class="text-white/60 line-through text-lg">
                Regular Price:
              </div>
              <div class="text-xl font-semibold">
                ৳{{
                  currentProduct.regular_price ||
                  (currentProduct.sale_price || 0) * 1.5
                }}
              </div>
            </div>
            <div class="text-2xl font-semibold">→</div>
            <div class="text-center">
              <div class="text-white/90 text-lg">Special Offer:</div>
              <div class="text-2xl font-semibold">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </div>
            </div>
          </div>
        </div>

        <button
          @click="addToCart(currentProduct, 1)"
          class="px-10 py-4 bg-white hover:bg-slate-50 text-primary-700 text-xl font-semibold rounded-xl shadow-sm transition-all duration-300 animate-pulse hover:animate-none transform hover:scale-105"
        >
          {{ currentProduct.cta_button_text }}
          <span class="block text-sm font-normal mt-1">{{
            currentProduct.cta_button_subtext
          }}</span>
        </button>

        <!-- Trust Badges -->
        <div class="flex flex-wrap justify-center gap-6 mt-8">
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
            v-if="currentProduct.cta_badge1"
          >
            <UIcon name="i-heroicons-credit-card" class="w-5 h-5" />
            <span class="text-sm">Secure Payment</span>
          </div>
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
            v-if="currentProduct.cta_badge2"
          >
            <UIcon name="i-heroicons-shield-check" class="w-5 h-5" />
            <span class="text-sm">Money-Back Guarantee</span>
          </div>
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
            v-if="currentProduct.cta_badge3"
          >
            <UIcon name="i-heroicons-truck" class="w-5 h-5" />
            <span class="text-sm">Fast Delivery</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Sticky Buy Now Button - Updated to show stock count -->
    <div
      class="fixed bottom-24 left-12 right-12 z-50 transform transition-transform"
      :class="{ 'translate-y-full': hideSticky, 'translate-y-0': !hideSticky }"
    >
      <div class="max-w-md mx-auto flex flex-col items-center justify-center">
        <button
          @click="addToCart(currentProduct, 1)"
          class="w-full bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white px-6 py-3 rounded-lg font-medium shadow flex items-center justify-center gap-2"
          :disabled="currentProduct.quantity <= 0"
          :class="{
            'opacity-75 cursor-not-allowed': currentProduct.quantity <= 0,
          }"
        >
          <div class="flex items-center gap-2">
            <UIcon name="i-heroicons-shopping-cart" class="w-5 h-5" />
            <span v-if="currentProduct.quantity > 0">
              Buy Now - ৳{{
                currentProduct.sale_price || currentProduct.regular_price
              }}
            </span>
            <span v-else> Out of Stock </span>
          </div>
        </button>

        <!-- Stock status indicator with count -->
        <div
          v-if="currentProduct.quantity > 0"
          class="mt-2 text-xs bg-slate-50 border border-slate-200 dark:bg-slate-800 dark:border-slate-700 px-3 py-1 rounded-full"
          :class="{
            'animate-pulse bg-amber-100 text-amber-800 dark:bg-amber-900/50 dark:text-amber-400':
              currentProduct.quantity <= 10,
          }"
        >
          <span v-if="currentProduct.quantity <= 10"
            >Only {{ currentProduct.quantity }} left in stock!</span
          >
          <span v-else>{{ currentProduct.quantity }} in stock</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { currentProduct, modal } = defineProps({
  currentProduct: { type: Object, required: true },
  modal: { type: Boolean, required: false },
});

const emit = defineEmits(["close-modal"]);

const cart = useStoreCart();
const user = useState("user"); // Access user state
const { get, post } = useApi(); // Add API composable

// Check if user is logged in
const isLoggedIn = computed(() => !!(user.value && (user.value.user || user.value.username)));

// Computed property for display name
const displayName = computed(() => {
  if (!user.value) return 'Guest';
  
  // Handle nested user object structure
  const userData = user.value.user || user.value;
  
  if (userData.first_name) {
    return `${userData.first_name} ${userData.last_name || ''}`.trim();
  }
  
  return userData.username || user.value.username || 'User';
});

// Reviews state
const productReviews = ref([]);
const productRatingStats = ref(null);
const isLoadingReviews = ref(false);
const isSubmittingReview = ref(false);
const userExistingReview = ref(null);
const isCheckingUserReview = ref(false);

// Review form data - must be declared before the watcher
const reviewForm = ref({
  name: "",
  rating: 0,
  comment: "",
});

// Fetch product reviews from API
async function fetchProductReviews() {
  if (!currentProduct?.id) return;
  
  isLoadingReviews.value = true;  try {
    const response = await get(`/reviews/products/${currentProduct.id}/reviews/`);
    if (response.data && response.data.results) {
      productReviews.value = response.data.results;
    } else if (response.data && Array.isArray(response.data)) {
      // Handle non-paginated response
      productReviews.value = response.data;
    } else {
      productReviews.value = [];
    }
  } catch (error) {
    console.error('Error fetching reviews:', error);
    productReviews.value = [];
  } finally {
    isLoadingReviews.value = false;
  }
}

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
        rating_1_count: 0
      };
    }
  } catch (error) {
    console.error('Error fetching rating stats:', error);
    // Set default stats if API fails
    productRatingStats.value = {
      total_reviews: 0,
      average_rating: 0,
      rating_5_count: 0,
      rating_4_count: 0,
      rating_3_count: 0,
      rating_2_count: 0,
      rating_1_count: 0
    };
  }
}

// Check if current user has already reviewed this product
async function checkUserExistingReview() {
  if (!currentProduct?.id || !isLoggedIn.value) {
    userExistingReview.value = null;
    return;
  }
  
  isCheckingUserReview.value = true;
  try {
    const response = await get(`/reviews/products/${currentProduct.id}/my-review/`);
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
      console.error('Error checking user review:', error);
      userExistingReview.value = null;
    }
  } finally {
    isCheckingUserReview.value = false;
  }
}

// Load reviews and stats when component mounts
onMounted(async () => {
  await Promise.all([
    fetchProductReviews(),
    fetchProductRatingStats(),
    checkUserExistingReview()
  ]);
  
  // Optional: Track product views after 70 seconds
  setTimeout(() => {
    try {
      // increaseProductViews(); // Function not defined, removing for now
    } catch (error) {
      console.log('Product view tracking not available');
    }
  }, 70000);
});

function addToCart(product, quantity) {
  cart.addProduct(product, quantity);
  navigateTo("/checkout/");
}

// Calculate discount percentage
function calculateDiscountPercentage(regular, sale) {
  if (!regular || !sale) return 0;

  const regularPrice = parseFloat(regular);
  const salePrice = parseFloat(sale);

  if (regularPrice <= 0) return 0;

  const discount = Math.round(
    ((regularPrice - salePrice) / regularPrice) * 100
  );
  return discount;
}

// Calculate savings
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

// Review calculations updated to use API data
const reviewCount = computed(() => {
  return productRatingStats.value?.total_reviews || 0;
});

const averageRating = computed(() => {
  if (productRatingStats.value?.average_rating) {
    return productRatingStats.value.average_rating.toFixed(1);
  }
  return "0.0";
});

// Computed for review validity
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

// Computed to check if user can submit a review (not already submitted)
const canSubmitReview = computed(() => {
  return isLoggedIn.value && !userExistingReview.value && !isCheckingUserReview.value;
});

// Rating distribution functions updated to use API data
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

// Reviews pagination
const reviewsPerPage = 3;
const currentReviewPage = ref(1);

// Modified to support pagination with API data
const displayedReviews = computed(() => {
  if (isLoadingReviews.value) {
    return []; // Show loading state
  }
  
  // Use API data if available, otherwise show empty array
  const allReviews = productReviews.value || [];

  // Calculate the start and end index for the current page
  const startIndex = (currentReviewPage.value - 1) * reviewsPerPage;
  const endIndex = startIndex + reviewsPerPage;

  // Return the reviews for the current page
  return allReviews.slice(startIndex, endIndex);
});

// Calculate total number of pages using API data
const totalReviewPages = computed(() => {
  const totalReviews = productReviews.value?.length || 0;
  return Math.ceil(totalReviews / reviewsPerPage);
});

// Generate pagination range with ellipsis for many pages
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

// Navigation functions
function goToReviewPage(page) {
  currentReviewPage.value = page;
}

function previousReviewPage() {
  if (currentReviewPage.value > 1) {
    currentReviewPage.value--;
  }
}

function nextReviewPage() {
  if (currentReviewPage.value < totalReviewPages.value) {
    currentReviewPage.value++;
  }
}

// Auto-scroll to reviews when page changes
watch(currentReviewPage, () => {
  // Optional: Smooth scroll to the reviews section on page change
  const reviewsSection = document.querySelector(".customer-reviews-section");
  if (reviewsSection) {
    setTimeout(() => {
      reviewsSection.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 100);
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

// Submit review function updated to use API
async function submitReview() {
  console.log('=== submitReview started ===');
  console.log('isReviewValid:', isReviewValid.value);
  console.log('isLoggedIn:', isLoggedIn.value);
  console.log('currentProduct.id:', currentProduct?.id);
  
  if (!isReviewValid.value || !isLoggedIn.value || !currentProduct?.id) {
    console.log('Early return due to validation failure');
    return;
  }    console.log('Setting isSubmittingReview to true');
    isSubmittingReview.value = true;
    console.log('After setting to true:', isSubmittingReview.value);

  try {
    const reviewData = {
      rating: reviewForm.value.rating,
      comment: reviewForm.value.comment.trim(),
      // Don't send name - it will be set from the authenticated user
    };
    
    console.log('Submitting review data:', reviewData);
    const response = await post(`/reviews/products/${currentProduct.id}/reviews/`, reviewData);
    console.log('Review submission response:', response);
    
    if (response.data) {
      console.log('Review submitted successfully');
      
      // Show success message using Nuxt UI toast
      const toast = useToast();
      toast.add({
        title: 'Review Submitted',
        description: 'Thank you for your feedback! Your review has been submitted successfully.',
        color: 'green',
        timeout: 5000
      });
        // Refresh the reviews list and stats with individual error handling
      console.log('Refreshing reviews and stats...');
      try {
        await fetchProductReviews();
        console.log('Reviews refreshed successfully');
      } catch (reviewsError) {
        console.error('Error refreshing reviews:', reviewsError);
      }
      
      try {
        await fetchProductRatingStats();
        console.log('Stats refreshed successfully');
      } catch (statsError) {
        console.error('Error refreshing rating stats:', statsError);
      }
      
      try {
        await checkUserExistingReview();
        console.log('User review status refreshed successfully');
      } catch (userReviewError) {
        console.error('Error refreshing user review status:', userReviewError);
      }
      
      // Reset form
      console.log('Resetting form...');
      reviewForm.value = {
        name: "",
        rating: 0,
        comment: "",
      };

      // Reset to first page to potentially show the newly added review
      currentReviewPage.value = 1;
      console.log('Form reset and page set to 1');
    }
  } catch (error) {
    console.error('Error submitting review:', error);
    
    // Show error message using Nuxt UI toast
    const toast = useToast();
    let errorMessage = 'Failed to submit review. Please try again.';
    
    if (error.response?.data?.detail) {
      errorMessage = error.response.data.detail;
    } else if (error.response?.data?.message) {
      errorMessage = error.response.data.message;
    } else if (error.response?.data?.non_field_errors) {
      errorMessage = error.response.data.non_field_errors[0];
    }
    
    toast.add({
      title: 'Error Submitting Review',
      description: errorMessage,
      color: 'red',
      timeout: 5000
    });  } finally {
    // Ensure this always runs regardless of what happens above
    console.log('FINALLY BLOCK: Setting isSubmittingReview to false');
    isSubmittingReview.value = false;
    console.log('FINALLY BLOCK: isSubmittingReview is now:', isSubmittingReview.value);
    
    // Force reactivity update
    nextTick(() => {
      console.log('After nextTick, isSubmittingReview:', isSubmittingReview.value);
    });
  }
}

onMounted(() => {
  setTimeout(() => {
    increaseProductViews();
  }, 70000);
});

// Sticky button visibility control
const lastScrollPosition = ref(0);
const hideSticky = ref(true);

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});

function handleScroll() {
  // Show sticky button when user has scrolled a bit (200px)
  if (window.scrollY > 200) {
    hideSticky.value = false;

    // Hide when scrolling up at the very top
    if (window.scrollY < lastScrollPosition.value && window.scrollY < 50) {
      hideSticky.value = true;
    }

    // Hide when reaching the bottom of the page (near the CTA)
    const bottomPosition =
      document.documentElement.scrollHeight - window.innerHeight - 300;
    if (window.scrollY > bottomPosition) {
      hideSticky.value = true;
    }
  } else {
    hideSticky.value = true;
  }

  lastScrollPosition.value = window.scrollY;
}
</script>

<style scoped>
.product-sales-funnel {
  width: 100%; /* Make it full width */
}

.benefit-card {
  background-color: white;
  padding: 1.5rem;
  border-radius: 0.75rem;
  box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  text-align: center;
}

.dark .benefit-card {
  background-color: rgb(30 41 59);
}

.icon-container {
  width: 4rem;
  height: 4rem;
  margin: 0 auto;
  background-color: rgb(239 246 255);
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
}

.dark .icon-container {
  background-color: rgb(30 58 138 / 0.3);
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: white;
  padding: 0.75rem;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
}

.dark .feature-item {
  background-color: rgb(30 41 59);
}
</style>
