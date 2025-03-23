<template>
  <UContainer>
    <div class="flex items-center justify-between mt-5 mb-4">
      <!-- Title Section with Icon -->
      <div class="flex items-center gap-2">
        <div
          class="p-1.5 rounded bg-gradient-to-r from-primary-50 to-primary-100 dark:from-primary-900/20 dark:to-primary-800/30 text-primary"
        >
          <UIcon name="i-heroicons-shopping-bag" class="w-5 h-5" />
        </div>
        <div class="flex flex-col">
          <h2
            class="font-bold text-lg md:text-xl text-slate-800 dark:text-white relative z-10 group"
          >
            <span class="relative inline-block text-lg">
              eShop
              <span
                class="absolute -bottom-0.5 left-0 w-0 h-0.5 bg-gradient-to-r from-primary to-primary-400 group-hover:w-full transition-all duration-300"
              ></span>
            </span>
            <UBadge
              color="primary"
              variant="subtle"
              class="ml-2 text-xs font-medium hidden sm:inline-flex"
            >
              New
            </UBadge>
          </h2>
        </div>
      </div>

      <!-- View All Button -->
      <NuxtLink
        to="/eshop"
        class="group inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-gradient-to-r hover:from-primary-50 hover:to-blue-50 dark:hover:from-primary-900/20 dark:hover:to-blue-900/20 hover:border-primary-200 dark:hover:border-primary-800/30 transition-all duration-300 shadow-sm hover:shadow text-sm font-medium text-slate-700 dark:text-slate-200"
      >
        <span>View All</span>
        <div
          class="relative overflow-hidden w-4 h-4 rounded-full bg-gradient-to-r from-primary-500 to-blue-500 flex items-center justify-center transform transition-transform group-hover:scale-110"
        >
          <UIcon name="i-heroicons-arrow-right" class="w-3 h-3 text-white" />
        </div>
      </NuxtLink>
    </div>
    <!-- Product Carousel Section -->
    <div class="product-carousel-section mt-3">
      <!-- Carousel Container -->
      <div class="relative">
        <!-- Navigation Arrows -->
        <button
          @click="prevSlide"
          class="absolute -left-4 md:-left-6 top-1/2 -translate-y-1/2 z-10 w-10 h-10 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-md hover:shadow-lg transition-all duration-200 group"
          :class="{ 'opacity-50 cursor-not-allowed': currentSlide === 0 }"
          :disabled="currentSlide === 0"
        >
          <UIcon
            name="i-heroicons-chevron-left"
            class="w-5 h-5 text-slate-600 dark:text-slate-300 group-hover:text-primary transition-colors"
          />
        </button>

        <button
          @click="nextSlide"
          class="absolute -right-4 md:-right-6 top-1/2 -translate-y-1/2 z-10 w-10 h-10 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-md hover:shadow-lg transition-all duration-200 group"
          :class="{
            'opacity-50 cursor-not-allowed':
              currentSlide === Math.ceil(products.length / itemsPerSlide) - 1,
          }"
          :disabled="
            currentSlide === Math.ceil(products.length / itemsPerSlide) - 1
          "
        >
          <UIcon
            name="i-heroicons-chevron-right"
            class="w-5 h-5 text-slate-600 dark:text-slate-300 group-hover:text-primary transition-colors"
          />
        </button>

        <!-- Carousel Track -->
        <div class="overflow-hidden rounded-xl">
          <div
            class="flex transition-transform duration-500 ease-out"
            :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
          >
            <div
              v-for="i in Math.ceil(products.length / itemsPerSlide)"
              :key="i"
              class="flex-shrink-0 w-full grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4"
            >
              <div
                v-for="product in getProductsForSlide(i - 1)"
                :key="product.id"
                class="product-card relative group"
              >
                <!-- Product Card Content -->
                <div
                  class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 h-full flex flex-col"
                >
                  <!-- Single Product Image Section with All Features -->
                  <div class="relative pt-[100%] overflow-hidden group">
                    <!-- Product Badges -->
                    <div
                      class="absolute top-0 left-0 right-0 z-10 p-2 flex justify-between"
                    >
                      <div v-if="product.discount" class="badge-discount">
                        -{{ product.discount }}%
                      </div>
                      <div class="status-badge">
                        <span>Sold 12</span>
                      </div>
                    </div>

                    <!-- Product Image -->
                    <img
                      :src="product.image"
                      :alt="product.name"
                      class="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-700 ease-out group-hover:scale-105"
                    />

                    <!-- Hover Elements -->
                    <div
                      class="absolute inset-0 bg-black/0 group-hover:bg-black/20 flex items-center justify-center transition-all duration-300 opacity-0 group-hover:opacity-100"
                    >
                      <UButton
                        @click="openReviewModal(product)"
                        class="quick-view-button"
                      >
                        Quick View
                      </UButton>
                    </div>
                  </div>

                  <!-- Product Details -->
                  <div class="p-3 flex-grow flex flex-col">
                    <!-- Category -->

                    <!-- Title -->
                    <NuxtLink :to="`/product-details/${product.id}`">
                      <h3
                        class="font-medium text-slate-800 dark:text-white mb-1.5 line-clamp-2 text-sm flex-grow"
                      >
                        {{ product.name }}
                      </h3>
                    </NuxtLink>
                    <!-- Rating -->
                    <div class="flex items-center gap-1 mb-1.5">
                      <div class="flex">
                        <UIcon
                          v-for="n in 5"
                          :key="n"
                          :name="
                            n <= Math.floor(product.rating)
                              ? 'i-heroicons-star-solid'
                              : 'i-heroicons-star'
                          "
                          class="w-3.5 h-3.5"
                          :class="
                            n <= Math.floor(product.rating)
                              ? 'text-yellow-400'
                              : 'text-gray-200'
                          "
                        />
                      </div>
                      <span class="text-xs text-slate-500 dark:text-slate-400"
                        >({{ product.reviews?.length }})</span
                      >
                    </div>

                    <!-- Price -->

                    <!-- Price -->
                    <div class="flex items-center justify-between">
                      <div class="flex items-center gap-2">
                        <span
                          class="font-semibold text-slate-800 dark:text-white"
                          >৳{{ product.price }}</span
                        >
                        <span
                          v-if="product.oldPrice"
                          class="text-xs text-slate-400 line-through"
                          >৳{{ product.oldPrice }}</span
                        >
                      </div>
                      <UButton
                        size="sm"
                        color="primary"
                        icon="i-material-symbols-light-garden-cart-outline"
                        @click="openReviewModal(product)"
                        :trailing="false"
                        class="rounded-full"
                      >
                        Buy
                      </UButton>
                    </div>

                    <!-- Buy Button -->
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Dots Navigation -->
        <div class="flex justify-center gap-2 mt-6">
          <button
            v-for="i in Math.ceil(products.length / itemsPerSlide)"
            :key="i"
            @click="goToSlide(i - 1)"
            class="w-2 h-2 rounded-full transition-all duration-200"
            :class="
              currentSlide === i - 1
                ? 'bg-primary w-6'
                : 'bg-slate-300 dark:bg-slate-600'
            "
          ></button>
        </div>
      </div>

      <!-- Product Review Modal -->
      <UModal v-model="isModalOpen">
        <UCard v-if="selectedProduct" class="p-0">
          <!-- Modal Header -->
          <template #header>
            <div
              class="relative bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 px-5 py-4"
            >
              <div class="flex justify-between items-center">
                <h3 class="text-xl font-medium text-slate-800 dark:text-white">
                  {{ selectedProduct.name }}
                </h3>
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  class="hover:rotate-90 transition-transform duration-300"
                  @click="isModalOpen = false"
                />
              </div>
            </div>
          </template>

          <!-- Modal Body -->
          <div class="p-5">
            <div class="grid grid-cols-1 gap-6">
              <!-- Left: Product Image Gallery -->
              <div>
                <div
                  class="relative pt-[100%] bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden"
                >
                  <img
                    v-if="selectedProduct.image"
                    :src="selectedProduct.image"
                    :alt="selectedProduct.name"
                    class="absolute inset-0 w-full h-full object-contain"
                  />

                  <!-- Discount Badge -->
                  <div
                    v-if="selectedProduct.discount"
                    class="absolute top-2 left-2 badge-discount"
                  >
                    -{{ selectedProduct.discount }}%
                  </div>
                </div>

                <!-- Thumbnail Gallery -->
                <div
                  class="grid grid-cols-4 gap-2 mt-2"
                  v-if="selectedProduct.medias"
                >
                  <div
                    v-for="i in 4"
                    :key="i"
                    class="aspect-square relative bg-slate-100 dark:bg-slate-800 rounded-md overflow-hidden cursor-pointer hover:opacity-80 border-2"
                    :class="i === 1 ? 'border-primary' : 'border-transparent'"
                  >
                    <img
                      :src="selectedProduct.image"
                      :alt="selectedProduct.name"
                      class="absolute inset-0 w-full h-full object-cover"
                    />
                  </div>
                </div>
              </div>

              <!-- Right: Product Info -->
              <div>
                <div class="mb-4">
                  <div class="text-sm text-slate-500 dark:text-slate-400 mb-1">
                    {{ selectedProduct.category }}
                  </div>
                  <h2
                    class="text-xl font-medium text-slate-800 dark:text-white mb-2"
                  >
                    {{ selectedProduct.name }}
                  </h2>

                  <!-- Rating -->
                  <div class="flex items-center gap-2 mb-3">
                    <div class="rating-stars">
                      <div class="stars-background">
                        <UIcon
                          v-for="n in 5"
                          :key="`bg-${n}`"
                          name="i-heroicons-star"
                          class="w-4 h-4 text-slate-200 dark:text-slate-700"
                        />
                      </div>
                      <div
                        class="stars-foreground"
                        :style="{
                          width: `${(selectedProduct.rating / 5) * 100}%`,
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
                    <span class="text-sm text-slate-500 dark:text-slate-400">
                      {{ selectedProduct.rating }} ({{
                        selectedProduct.reviews?.length || 0
                      }}
                      reviews)
                    </span>
                  </div>

                  <!-- Price -->
                  <div class="flex items-center gap-3 mb-4">
                    <span
                      class="text-2xl font-semibold text-slate-800 dark:text-white"
                    >
                      ৳{{ selectedProduct.price }}
                    </span>
                    <span
                      v-if="selectedProduct.oldPrice"
                      class="text-sm text-slate-400 line-through"
                    >
                      ৳{{ selectedProduct.oldPrice }}
                    </span>
                    <span v-if="selectedProduct.discount" class="savings-badge">
                      Save ৳{{
                        calculateSavings(
                          selectedProduct.price,
                          selectedProduct.oldPrice
                        )
                      }}
                    </span>
                  </div>

                  <!-- Description -->
                  <p
                    class="text-sm text-slate-600 dark:text-slate-300 mb-4 description-text"
                  >
                    {{ selectedProduct.description }}
                  </p>

                  <!-- Add to Cart Area -->
                  <div class="flex items-center gap-3 mb-6">
                    <UInput
                      v-model="quantity"
                      :min="1"
                      :max="10"
                      :ui="{ base: 'w-24' }"
                      size="md"
                    />

                    <button
                      class="flex-1 relative overflow-hidden group bg-gradient-to-r from-primary to-primary-600 hover:from-primary-600 hover:to-primary rounded-lg py-3 px-4 text-white font-medium shadow-md hover:shadow-lg transition-all duration-300"
                      @click="addToCart"
                    >
                      <!-- Hover overlay effect -->
                      <div
                        class="absolute inset-0 w-full h-full bg-white/10 transform origin-left scale-x-0 group-hover:scale-x-100 transition-transform duration-500"
                      ></div>

                      <!-- Content container -->
                      <div
                        class="relative flex items-center justify-center gap-2"
                      >
                        <!-- Shopping cart icon -->
                        <UIcon
                          name="i-heroicons-shopping-cart"
                          class="w-5 h-5 transition-transform group-hover:scale-110 duration-300"
                        />

                        <!-- Button text with animated dot -->
                        <span class="text-base">
                          Buy Now
                          <span
                            class="inline-block w-1.5 h-1.5 bg-white rounded-full ml-0.5 animate-pulse"
                          ></span>
                        </span>
                      </div>
                    </button>
                  </div>

                  <!-- Features List - Improved Responsive Layout -->
                  <div class="bg-slate-50 dark:bg-slate-800/50 p-3 rounded-lg">
                    <div class="text-sm font-medium mb-2">
                      Shipping Information:
                    </div>
                    <ul class="space-y-1.5 text-slate-600 dark:text-slate-300">
                      <li class="flex items-start gap-1.5 text-xs sm:text-sm">
                        <UIcon
                          name="i-heroicons-check-circle"
                          class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
                        />
                        <span>Inside Dhaka ৳100</span>
                      </li>
                      <li class="flex items-start gap-1.5 text-xs sm:text-sm">
                        <UIcon
                          name="i-heroicons-check-circle"
                          class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
                        />
                        <span>Outside Dhaka ৳150</span>
                      </li>

                      <li class="flex items-start gap-1.5 text-xs sm:text-sm">
                        <UIcon
                          name="i-heroicons-check-circle"
                          class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
                        />
                        <span>Delivery within 3-5 business days</span>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>

              <!-- Tabs - Improved Responsiveness -->
              <div class="">
                <UTabs v-model="activeTab" :items="tabItems">
                  <!-- Reviews Tab -->
                  <template #reviews>
                    <div>
                      <!-- Reviews Summary -->
                      <div
                        class="mb-4 p-3 bg-slate-50/70 dark:bg-slate-800/70 rounded-lg"
                      >
                        <div class="flex flex-col sm:flex-row gap-4">
                          <div
                            class="flex flex-col items-center sm:border-r sm:border-slate-200 sm:dark:border-slate-700 sm:pr-6"
                          >
                            <div
                              class="text-2xl font-bold text-slate-800 dark:text-white"
                            >
                              {{ selectedProduct.rating }}
                            </div>
                            <div class="flex text-yellow-400 my-1">
                              <UIcon
                                v-for="i in 5"
                                :key="i"
                                name="i-heroicons-star-solid"
                                class="w-4 h-4"
                              />
                            </div>
                            <div class="text-xs text-slate-500">
                              {{ selectedProduct.reviews?.length || 0 }} reviews
                            </div>
                          </div>

                          <div class="flex-1 space-y-1.5">
                            <div
                              v-for="n in 5"
                              :key="n"
                              class="flex items-center"
                            >
                              <div class="text-xs w-5 text-right mr-2">
                                {{ 6 - n }}
                              </div>
                              <UIcon
                                name="i-heroicons-star"
                                class="w-3.5 h-3.5 text-yellow-400 mr-1.5"
                              />
                              <div
                                class="flex-1 h-2 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden"
                              >
                                <div
                                  class="h-full bg-yellow-400"
                                  :style="{ width: getRatingPercentage(6 - n) }"
                                ></div>
                              </div>
                              <div class="text-xs w-5 text-right ml-2">
                                {{ getRatingCount(6 - n) }}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <!-- Reviews List -->
                      <div class="space-y-3 max-h-60 overflow-y-auto pr-2">
                        <div
                          v-for="(review, index) in selectedProduct.reviews ||
                          []"
                          :key="index"
                          class="p-3 bg-white dark:bg-slate-800 rounded-lg shadow-sm"
                        >
                          <div class="flex justify-between mb-2">
                            <div class="flex items-center gap-2">
                              <div
                                class="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center"
                              >
                                <span class="font-medium text-sm">{{
                                  review.name?.charAt(0) || "?"
                                }}</span>
                              </div>
                              <div>
                                <div
                                  class="font-medium text-slate-800 dark:text-white"
                                >
                                  {{ review.name }}
                                </div>
                                <div class="text-xs text-slate-500">
                                  {{ review.date }}
                                </div>
                              </div>
                            </div>
                            <div class="flex">
                              <UIcon
                                v-for="n in 5"
                                :key="n"
                                :name="
                                  n <= review.rating
                                    ? 'i-heroicons-star-solid'
                                    : 'i-heroicons-star'
                                "
                                class="w-3.5 h-3.5"
                                :class="
                                  n <= review.rating
                                    ? 'text-yellow-400'
                                    : 'text-gray-200'
                                "
                              />
                            </div>
                          </div>
                          <p class="text-sm text-slate-600 dark:text-slate-300">
                            {{ review.comment }}
                          </p>
                        </div>
                      </div>
                      <!-- Write a Review Section -->
                      <div
                        class="mb-6 p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg"
                      >
                        <h4
                          class="font-medium text-slate-800 dark:text-white mb-3"
                        >
                          Write a Review
                        </h4>
                        <div class="space-y-4">
                          <div>
                            <label
                              class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                            >
                              Rating
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
                                      ? 'text-yellow-400'
                                      : 'text-slate-300 dark:text-slate-600'
                                  "
                                />
                              </UButton>
                            </div>
                          </div>
                          <div>
                            <label
                              class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                            >
                              Your Name
                            </label>
                            <UInput
                              v-model="reviewForm.name"
                              placeholder="Enter your name"
                            />
                          </div>
                          <div>
                            <label
                              class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
                            >
                              Review Comment
                            </label>
                            <UTextarea
                              v-model="reviewForm.comment"
                              placeholder="Share your thoughts about this product"
                              :ui="{ rounded: 'rounded-lg' }"
                              rows="3"
                            />
                          </div>
                          <UButton
                            color="primary"
                            @click="submitReview"
                            :disabled="!isReviewValid"
                            block
                          >
                            Submit Review
                          </UButton>
                        </div>
                      </div>
                    </div>
                  </template>

                  <!-- Details Tab -->
                  <template #details>
                    <div
                      class="prose prose-sm max-w-none text-slate-600 dark:text-slate-300"
                    >
                      <p>{{ selectedProduct.description }}</p>
                      <p class="mt-3">
                        Experience the perfect blend of design and functionality
                        with our {{ selectedProduct.name }}. Designed with the
                        modern consumer in mind.
                      </p>

                      <h4
                        class="text-base font-semibold mt-4 mb-2 text-slate-800 dark:text-white"
                      >
                        Specifications
                      </h4>
                      <div
                        class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-2"
                      >
                        <div
                          class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                        >
                          <span class="text-slate-500 dark:text-slate-400"
                            >Brand:</span
                          >
                          <span class="font-medium">Premium Selection</span>
                        </div>
                        <div
                          class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                        >
                          <span class="text-slate-500 dark:text-slate-400"
                            >Model:</span
                          >
                          <span class="font-medium"
                            >X-{{
                              1000 + Math.floor(Math.random() * 9000)
                            }}</span
                          >
                        </div>
                        <div
                          class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                        >
                          <span class="text-slate-500 dark:text-slate-400"
                            >Dimensions:</span
                          >
                          <span class="font-medium">24 x 12 x 8 cm</span>
                        </div>
                        <div
                          class="flex justify-between py-2 border-b border-slate-100 dark:border-slate-700"
                        >
                          <span class="text-slate-500 dark:text-slate-400"
                            >Weight:</span
                          >
                          <span class="font-medium">1.2 kg</span>
                        </div>
                      </div>
                    </div>
                  </template>
                </UTabs>
              </div>
            </div>
          </div>
        </UCard>
      </UModal>

      <!-- Checkout Modal -->
      <UModal v-model="isCheckoutModalOpen">
        <UCard class="p-0">
          <!-- Modal Header -->
          <template #header>
            <div
              class="relative bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 px-5 py-4 border-b border-slate-200 dark:border-slate-700"
            >
              <div class="flex justify-between items-center">
                <h3 class="text-xl font-medium text-slate-800 dark:text-white">
                  Checkout
                </h3>
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  class="hover:rotate-90 transition-transform duration-300"
                  @click="isCheckoutModalOpen = false"
                />
              </div>
            </div>
          </template>

          <!-- Checkout modal body - empty as requested -->
          <div class="p-6">
            <div
              class="flex items-center justify-center h-60 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-dashed border-slate-200 dark:border-slate-700"
            >
              <div class="text-center">
                <UIcon
                  name="i-heroicons-shopping-cart"
                  class="w-12 h-12 mx-auto text-slate-300 dark:text-slate-600 mb-3"
                />
                <p class="text-slate-500 dark:text-slate-400">
                  Checkout form will be designed later
                </p>
              </div>
            </div>
          </div>
        </UCard>
      </UModal>
    </div>
  </UContainer>
</template>

<script setup>
const imageLoaded = ref(false);

// Product carousel and modal state
const currentSlide = ref(0);
const itemsPerSlide = ref(5);
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);
const userRating = ref(0);
const reviewComment = ref("");
const isCheckoutModalOpen = ref(false);

// Sample products data with reviews
const products = [
  {
    id: 1,
    name: "Wireless Noise-Cancelling Headphones",
    price: "3,499",
    oldPrice: "4,999",
    discount: 30,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Headphones",
    category: "Electronics",
    rating: 4.8,
    description:
      "Experience premium sound quality with these wireless noise-cancelling headphones. Perfect for work, travel, and everyday use with up to 30 hours of battery life.",
    reviews: [
      {
        name: "Asif Khan",
        rating: 5,
        date: "March 12, 2025",
        comment:
          "Amazing sound quality and the noise cancellation is perfect for my daily commute!",
        avatar: "",
      },
      {
        name: "Farah Ahmed",
        rating: 4,
        date: "March 5, 2025",
        comment:
          "Great battery life and comfortable to wear for hours. The app could use some improvements though.",
        avatar: "",
      },
    ],
  },
];

// Update responsive items per slide based on screen size
onMounted(() => {
  updateItemsPerSlide();
  window.addEventListener("resize", updateItemsPerSlide);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateItemsPerSlide);
});

function updateItemsPerSlide() {
  if (window.innerWidth < 640) {
    itemsPerSlide.value = 2;
  } else if (window.innerWidth < 768) {
    itemsPerSlide.value = 3;
  } else if (window.innerWidth < 1024) {
    itemsPerSlide.value = 4;
  } else {
    itemsPerSlide.value = 5;
  }
}

// Carousel navigation
function prevSlide() {
  if (currentSlide.value > 0) {
    currentSlide.value--;
  }
}

function nextSlide() {
  if (
    currentSlide.value <
    Math.ceil(products.length / itemsPerSlide.value) - 1
  ) {
    currentSlide.value++;
  }
}

function goToSlide(index) {
  currentSlide.value = index;
}

// Get products for current slide
function getProductsForSlide(slideIndex) {
  const start = slideIndex * itemsPerSlide.value;
  const end = start + itemsPerSlide.value;
  return products.slice(start, end);
}

// Modal and review functions
function openReviewModal(product) {
  selectedProduct.value = product;
  isModalOpen.value = true;
}

// Calculate price savings
function calculateSavings(currentPrice, oldPrice) {
  // Remove commas and convert to numbers
  const current = Number(currentPrice.replace(/,/g, ""));
  const old = Number(oldPrice.replace(/,/g, ""));
  return (old - current).toLocaleString();
}

// Add these to your existing script section
const activeTab = ref("details");
const reviewForm = ref({
  name: "",
  rating: 0,
  comment: "",
});

// Computed property for tabs configuration - prevents recursive updates
const tabItems = computed(() => {
  if (!selectedProduct.value) return [];

  return [
    {
      label: "Details",
      slot: "details",
      icon: "i-heroicons-document-text",
    },
    {
      label: "Reviews",
      slot: "reviews",
      icon: "i-heroicons-chat-bubble-left-right",
      badge: selectedProduct.value.reviews?.length || 0,
    },
  ];
});

// Computed for review validity
const isReviewValid = computed(() => {
  return (
    reviewForm.value.name &&
    reviewForm.value.rating > 0 &&
    reviewForm.value.comment.trim().length > 0
  );
});

// Rating distribution functions
function getRatingPercentage(rating) {
  if (!selectedProduct.value || !selectedProduct.value.reviews) return "0%";

  const total = selectedProduct.value.reviews.length || 1;
  const count = selectedProduct.value.reviews.filter(
    (r) => Math.round(r.rating) === rating
  ).length;

  return `${(count / total) * 100}%`;
}

function getRatingCount(rating) {
  if (!selectedProduct.value || !selectedProduct.value.reviews) return 0;

  return selectedProduct.value.reviews.filter(
    (r) => Math.round(r.rating) === rating
  ).length;
}

// Improved submit review function
function submitReview() {
  if (!isReviewValid.value) return;

  // Add review to product
  if (!selectedProduct.value.reviews) {
    selectedProduct.value.reviews = [];
  }

  selectedProduct.value.reviews.unshift({
    name: reviewForm.value.name,
    rating: reviewForm.value.rating,
    date: "Just now",
    comment: reviewForm.value.comment.trim(),
    avatar: "",
  });

  // Reset form
  reviewForm.value = {
    name: "",
    rating: 0,
    comment: "",
  };
}
</script>

<style scoped>
/* Dropdown styles */
.dropdown-trigger {
  @apply flex items-center justify-between p-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg shadow-sm hover:shadow-md cursor-pointer transition-all duration-200 select-none;
}

.dropdown-trigger.is-open {
  @apply shadow-md ring-1 ring-primary/40 border-primary/30;
}

.dropdown-content {
  @apply absolute w-full mt-1.5 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg shadow-lg overflow-hidden;
}

.search-container {
  @apply relative flex items-center p-3 border-b border-slate-200 dark:border-slate-700;
}

.search-icon {
  @apply absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400;
}

.search-input {
  @apply w-full py-2 pl-8 pr-8 bg-slate-50 dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary/50 transition-all;
}

.clear-button {
  @apply absolute right-5 top-1/2 -translate-y-1/2;
}

.categories-list-container {
  @apply max-h-[400px] overflow-y-auto p-2;
}

.category-item {
  @apply p-2.5 rounded-md cursor-pointer transition-colors duration-150 hover:bg-slate-50 dark:hover:bg-slate-700;
}

.category-item.is-active {
  @apply bg-primary/10 text-primary;
}

.icon-container {
  @apply flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-slate-100 dark:bg-slate-700;
}

.category-icon {
  @apply w-4 h-4;
}

.empty-state {
  @apply py-8 flex flex-col items-center justify-center text-center;
}

/* Custom scrollbar */
.categories-list-container::-webkit-scrollbar {
  width: 6px;
}

.categories-list-container::-webkit-scrollbar-track {
  @apply bg-slate-100 dark:bg-slate-700 rounded-full;
}

.categories-list-container::-webkit-scrollbar-thumb {
  @apply bg-slate-300 dark:bg-slate-600 rounded-full hover:bg-slate-400 dark:hover:bg-slate-500;
}

/* Product card styles */
.badge-discount {
  @apply px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-full;
}

.wishlist-button {
  @apply w-8 h-8 flex items-center justify-center bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm shadow-sm rounded-full border border-slate-200/50 dark:border-slate-700/50 transition-all hover:scale-110;
}

.quick-view-button {
  @apply px-3 py-1.5 bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm text-sm font-medium text-slate-800 dark:text-white rounded-lg border border-slate-200/50 dark:border-slate-700/50 shadow-sm transform transition-all hover:scale-105;
}

.review-item {
  @apply p-3 border border-slate-100 dark:border-slate-700 rounded-lg mb-3;
}

/* New premium product image styles */
.status-badge {
  @apply absolute top-2 right-2 z-20 bg-gradient-to-r from-emerald-500 to-teal-500 text-white text-xs font-semibold px-2 py-0.5 rounded-md shadow-sm opacity-100 transform  transition-all duration-500;
  animation: pulse-badge 2s infinite;
}

/* .group:hover .status-badge {
  @apply opacity-100 translate-x-0;
} */

@keyframes pulse-badge {
  0%,
  100% {
    @apply shadow-sm;
  }
  50% {
    @apply shadow-md;
  }
}

/* Premium action buttons */
.product-action-btn {
  @apply flex items-center justify-center gap-1.5 py-2 px-3 bg-white dark:bg-slate-800 rounded-md shadow-sm backdrop-blur-md text-sm font-medium transition-all duration-300 transform;
}

.quick-view-btn {
  @apply text-primary hover:bg-primary hover:text-white transform translate-y-3 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500;
}

.add-cart-btn {
  @apply text-slate-800 dark:text-white hover:bg-slate-800 dark:hover:bg-white hover:text-white dark:hover:text-slate-800 transform translate-y-3 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500 delay-100;
}

.btn-icon {
  @apply flex-shrink-0;
}

.btn-text {
  @apply relative overflow-hidden;
}

.btn-text:after {
  @apply absolute left-0 bottom-0 w-0 h-0.5 bg-current opacity-0 transition-all duration-300;
  content: "";
}

.product-action-btn:hover .btn-text:after {
  @apply w-full opacity-100;
}

/* Feature badges */
.feature-badge {
  @apply flex items-center text-[0.65rem] py-0.5 px-1.5 bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm text-slate-700 dark:text-slate-300 rounded-full shadow-sm border border-slate-200/50 dark:border-slate-700/50;
}

/* Enhanced Gallery Styles */
.product-gallery {
  @apply relative;
}

.gallery-main-image {
  @apply border border-slate-200 dark:border-slate-700 shadow-sm;
}

.shimmer-effect {
  @apply opacity-0;
  animation: shimmer 2s infinite;
  transform: skewX(-20deg);
  width: 40%;
  left: -100%;
}

@keyframes shimmer {
  0% {
    left: -100%;
    opacity: 0;
  }
  20% {
    opacity: 0.3;
  }
  80% {
    opacity: 0.3;
  }
  100% {
    left: 200%;
    opacity: 0;
  }
}

.gallery-main-image:hover .shimmer-effect {
  animation-play-state: running;
}

.corner-effect {
  @apply absolute w-4 h-4 opacity-0 transition-opacity duration-300 border-2 border-primary;
}

.gallery-main-image:hover .corner-effect {
  @apply opacity-100;
}

.top-left {
  @apply top-2 left-2;
  border-top: 2px solid;
  border-left: 2px solid;
}

.top-right {
  @apply top-2 right-2;
  border-top: 2px solid;
  border-right: 2px solid;
}

.bottom-left {
  @apply bottom-2 left-2;
  border-bottom: 2px solid;
  border-left: 2px solid;
}

.bottom-right {
  @apply bottom-2 right-2;
  border-bottom: 2px solid;
  border-right: 2px solid;
}

/* Thumbnails */
.thumbnail-container {
  @apply cursor-pointer transition-all duration-300 transform;
}

.thumbnail-container:hover {
  @apply -translate-y-1;
}

.thumbnail-container div {
  @apply border-2 border-transparent transition-colors duration-200;
}

.thumbnail-active div {
  @apply border-primary shadow-md;
}

/* Zoom Indicator */
.zoom-indicator {
  @apply absolute bottom-3 right-3 bg-white/80 dark:bg-slate-800/80 text-slate-600 dark:text-slate-300 p-1.5 rounded-full opacity-0 transition-opacity duration-300;
}

.gallery-main-image:hover .zoom-indicator {
  @apply opacity-80;
}

/* Discount Badge */
.discount-badge {
  @apply transition-all duration-300 origin-left;
  animation: pulse-badge 2s infinite;
}

.badge-background {
  @apply absolute -inset-1 bg-gradient-to-r from-red-500 to-pink-500 rounded-md blur-sm opacity-75;
  animation: pulse-glow 2s infinite alternate;
}

.badge-text {
  @apply relative block px-2 py-1 bg-red-500 text-white text-xs font-bold rounded leading-none;
}

@keyframes pulse-glow {
  0% {
    opacity: 0.5;
  }
  100% {
    opacity: 0.8;
  }
}

/* Rating Stars */
.rating-stars {
  @apply relative inline-flex;
}

.stars-background {
  @apply flex;
}

.stars-foreground {
  @apply absolute top-0 left-0 flex overflow-hidden;
}

/* Savings Badge */
.price-comparison {
  @apply flex flex-col;
}

.savings-badge {
  @apply text-xs font-medium text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/30 px-1.5 py-0.5 rounded mt-0.5;
  animation: fade-in 0.5s ease-out;
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Description highlight effect */
.description-text {
  @apply relative leading-relaxed;
}

.description-text::after {
  @apply absolute bottom-0 left-0 w-0 h-0.5 bg-primary/20 transition-all duration-1000;
  content: "";
}

.description-text:hover::after {
  @apply w-full;
}
</style>
