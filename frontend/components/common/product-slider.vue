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
            <span class="relative inline-block">
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
        to="/shop"
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
                        :to="`/product-details/${product.id}`"
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
                    <h3
                      class="font-medium text-slate-800 dark:text-white mb-1.5 line-clamp-2 text-sm flex-grow"
                    >
                      {{ product.name }}
                    </h3>

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
                        >({{ product.reviews.length }})</span
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
                        @click="openBuyEvent(product)"
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
      <UModal v-model="isModalOpen" :ui="{ width: 'w-full max-w-4xl' }">
        <UCard v-if="selectedProduct" class="p-0">
          <!-- Modal Header -->
          <template #header>
            <div
              class="relative bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 px-5 py-4 border-b border-slate-200 dark:border-slate-700"
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
                    :src="selectedProduct.image"
                    :alt="selectedProduct.name"
                    class="absolute inset-0 w-full h-full object-contain"
                    @load="imageLoaded = true"
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
                <div class="grid grid-cols-4 gap-2 mt-2">
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
                        selectedProduct.reviews.length
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
                    <UInputNumber
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
                <UTabs
                  :items="[
                    {
                      label: 'Details',
                      slot: 'details',
                      icon: 'i-heroicons-document-text',
                    },
                    {
                      label: 'Reviews',
                      slot: 'reviews',
                      icon: 'i-heroicons-chat-bubble-left-right',
                      badge: selectedProduct.reviews.length,
                    },
                  ]"
                  :ui="{
                    list: {
                      background: 'bg-slate-100/50 dark:bg-slate-800/50',
                      rounded: 'rounded-lg',
                      padding: 'p-1',
                    },
                    container: {
                      background: 'bg-white dark:bg-slate-800/30',
                      rounded: 'rounded-lg',
                      padding: 'p-4 mt-3',
                    },
                  }"
                >
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
                              {{ selectedProduct.reviews.length }} reviews
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
                                  :style="{ width: `${Math.random() * 100}%` }"
                                ></div>
                              </div>
                              <div class="text-xs w-5 text-right ml-2">
                                {{
                                  Math.floor(
                                    Math.random() *
                                      selectedProduct.reviews.length
                                  )
                                }}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <!-- Reviews List -->
                      <div class="space-y-3 max-h-60 overflow-y-auto pr-2">
                        <div
                          v-for="(review, index) in selectedProduct.reviews"
                          :key="index"
                          class="p-3 bg-white dark:bg-slate-800 rounded-lg shadow-sm"
                        >
                          <div class="flex justify-between mb-2">
                            <div class="flex items-center gap-2">
                              <div
                                class="w-8 h-8 bg-primary/20 text-primary rounded-full flex items-center justify-center"
                              >
                                <span class="font-medium text-sm">{{
                                  review.name.charAt(0)
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

                  <!-- Shipping Tab -->
                  <!-- <template #shipping>
                    <div class="text-slate-600 dark:text-slate-300">
                      <p class="mb-4">
                        We offer multiple shipping options to meet your needs:
                      </p>
                      <ul class="space-y-3">
                        <li class="flex items-start gap-2">
                          <UIcon
                            name="i-heroicons-truck"
                            class="w-5 h-5 text-primary mt-0.5"
                          />
                          <div>
                            <p
                              class="font-medium text-slate-800 dark:text-white"
                            >
                              Standard Shipping
                            </p>
                            <p class="text-sm">
                              Delivery within 3-5 business days
                            </p>
                          </div>
                        </li>
                        <li class="flex items-start gap-2">
                          <UIcon
                            name="i-heroicons-bolt"
                            class="w-5 h-5 text-primary mt-0.5"
                          />
                          <div>
                            <p
                              class="font-medium text-slate-800 dark:text-white"
                            >
                              Express Shipping
                            </p>
                            <p class="text-sm">
                              Delivery within 1-2 business days
                            </p>
                          </div>
                        </li>
                        <li class="flex items-start gap-2">
                          <UIcon
                            name="i-heroicons-map-pin"
                            class="w-5 h-5 text-primary mt-0.5"
                          />
                          <div>
                            <p
                              class="font-medium text-slate-800 dark:text-white"
                            >
                              Local Pickup
                            </p>
                            <p class="text-sm">Available at select locations</p>
                          </div>
                        </li>
                      </ul>

                      <div
                        class="mt-4 p-3 bg-slate-50 dark:bg-slate-800/70 rounded-lg"
                      >
                        <div class="flex items-center gap-2 text-sm">
                          <UIcon
                            name="i-heroicons-information-circle"
                            class="w-5 h-5 text-primary"
                          />
                          <span>Free shipping on orders over ৳5,000</span>
                        </div>
                      </div>
                    </div>
                  </template> -->
                </UTabs>
              </div>
            </div>
          </div>
        </UCard>
      </UModal>
    </div>

    <!-- Features List - Improved Responsive Layout -->
    <!-- <div class="bg-slate-50 dark:bg-slate-800/50 p-3 sm:p-4 rounded-lg mb-4">
      <div class="text-sm sm:text-base font-medium mb-2">Key Features:</div>
      <ul class="space-y-1.5 sm:space-y-2 text-slate-600 dark:text-slate-300">
        <li class="flex items-start gap-1.5 text-xs sm:text-sm">
          <UIcon
            name="i-heroicons-check-circle"
            class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
          />
          <span>Premium Quality</span>
        </li>
        <li class="flex items-start gap-1.5 text-xs sm:text-sm">
          <UIcon
            name="i-heroicons-check-circle"
            class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
          />
          <span>30-Day Money-Back Guarantee</span>
        </li>
        <li class="flex items-start gap-1.5 text-xs sm:text-sm">
          <UIcon
            name="i-heroicons-check-circle"
            class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
          />
          <span>Free Shipping Available</span>
        </li>
        <li class="flex items-start gap-1.5 text-xs sm:text-sm">
          <UIcon
            name="i-heroicons-check-circle"
            class="w-4 h-4 text-green-500 flex-shrink-0 mt-0.5"
          />
          <span>24/7 Customer Support</span>
        </li>
      </ul>
    </div> -->

    <!-- Tabs - Improved Responsiveness -->
    <!-- <UTabs
      :items="[
        {
          label: 'Reviews',
          slot: 'reviews',
          icon: 'i-heroicons-chat-bubble-left-right',
        },
        {
          label: 'Details',
          slot: 'details',
          icon: 'i-heroicons-document-text',
        },
        { label: 'Shipping', slot: 'shipping', icon: 'i-heroicons-truck' },
      ]"
    >
    </UTabs> -->

    <UModal
      v-model="openBuyModal"
      :ui="{
        width: 'sm:max-w-md',
        overlay: {
          background: 'bg-slate-900/30 backdrop-blur-sm',
        },
        container: 'transition-all duration-300 ease-out-cubic',
      }"
      transition="fade-scale"
    >
      <div class="modal-subscription overflow-hidden rounded-xl">
        <!-- Animated Header -->
        <div class="relative overflow-hidden">
          <div
            class="absolute inset-0 bg-gradient-to-r from-sky-500/20 to-blue-500/20 animate-gradient"
          ></div>
          <div
            class="relative px-6 py-5 bg-gradient-to-r from-sky-500 to-blue-500"
          >
            <!-- Animated particles -->
            <div
              class="absolute top-3 right-3 w-2 h-2 rounded-full bg-white/30 animate-ping-slow"
            ></div>
            <div
              class="absolute top-10 right-12 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.5s"
            ></div>
            <div
              class="absolute bottom-5 left-10 w-1.5 h-1.5 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 1s"
            ></div>

            <div class="flex items-center gap-3">
              <div
                class="bg-white/20 p-2.5 rounded-lg flex items-center justify-center backdrop-blur-sm"
              >
                <UIcon name="i-heroicons-star" class="text-white w-5 h-5" />
              </div>
              <div>
                <h2 class="text-white font-semibold text-xl flex items-center">
                  Checkout your purchase
                  <div class="ml-2 flex">
                    <span class="animate-shimmer-star">✨</span>
                  </div>
                </h2>
                <p class="text-sky-100 text-sm mt-0.5">
                  Complete the steps inorder to make a successful purchase
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="p-0">
          <!-- Loading State -->
          <div
            v-if="isLoading"
            class="flex flex-col items-center justify-center py-16 px-6"
          >
            <div class="relative">
              <div
                class="w-12 h-12 rounded-full border-2 border-sky-500/20"
              ></div>
              <div
                class="absolute inset-0 w-12 h-12 rounded-full border-t-2 border-sky-500 animate-spin"
              ></div>
            </div>
            <p class="mt-4 text-slate-600 dark:text-slate-400">
              Loading plan details...
            </p>
          </div>

          <!-- Content -->
          <div v-else class="px-6 py-5">
            <!-- Plan Details -->
            <div class="mb-6">
              <h3 class="text-base font-medium mb-3 flex items-center">
                <UIcon
                  name="i-heroicons-document-text"
                  class="mr-2 text-sky-500 w-4 h-4"
                />
                Plan Details
              </h3>
              <div
                class="p-4 rounded-lg bg-gradient-to-r from-slate-50 to-sky-50 dark:from-slate-800/80 dark:to-sky-900/30 border border-slate-100 dark:border-slate-700/50 relative overflow-hidden group"
              >
                <!-- Shimmer effect on hover -->
                <div
                  class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 dark:via-white/5 to-transparent -translate-x-full group-hover:animate-shimmer"
                ></div>

                <!-- Plan content -->
                <div class="flex justify-between items-center mb-3">
                  <span class="text-slate-600 dark:text-slate-300">Plan:</span>
                  <span
                    class="font-semibold bg-gradient-to-r from-sky-600 to-blue-600 dark:from-sky-400 dark:to-blue-400 bg-clip-text text-transparent"
                    >Pro Plan</span
                  >
                </div>
                <div class="flex justify-between items-center mb-3">
                  <span class="text-slate-600 dark:text-slate-300">Price:</span>
                  <span class="font-semibold">৳2,900 / month</span>
                </div>
                <div class="flex justify-between items-center">
                  <span class="text-slate-600 dark:text-slate-300"
                    >Duration:</span
                  >
                  <span class="font-semibold">30 days</span>
                </div>
              </div>
            </div>
            <!-- Shipping Options Selection -->
            <div class="mb-6">
              <h3 class="text-base font-medium mb-3 flex items-center">
                <UIcon
                  name="i-heroicons-truck"
                  class="mr-2 text-sky-500 w-4 h-4"
                />
                Shipping Options
              </h3>

              <!-- Free Shipping -->

              <!-- Inside Dhaka -->
              <div class="payment-option-container mb-3">
                <URadio
                  v-model="shippingOption"
                  name="shipping"
                  value="inside_dhaka"
                  class="sr-only"
                  id="inside_dhaka"
                />
                <label
                  for="inside_dhaka"
                  class="block p-4 border rounded-lg transition-all duration-200 cursor-pointer relative"
                  :class="
                    shippingOption === 'inside_dhaka'
                      ? 'border-sky-500 dark:border-sky-500 bg-sky-50 dark:bg-sky-900/20 ring-1 ring-sky-500/30'
                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50'
                  "
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 flex-shrink-0 rounded-md bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
                      >
                        <UIcon
                          name="i-heroicons-home"
                          class="w-5 h-5 text-sky-600 dark:text-sky-400"
                        />
                      </div>
                      <div>
                        <p class="font-medium">Inside Dhaka</p>
                        <p class="text-xs text-slate-500 dark:text-slate-400">
                          Delivery in 2-3 business days
                        </p>
                      </div>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="font-medium">৳100</span>
                      <div
                        class="flex items-center justify-center w-5 h-5 rounded-full border-2"
                        :class="
                          shippingOption === 'inside_dhaka'
                            ? 'bg-sky-500 border-sky-500 flex items-center justify-center'
                            : 'border-slate-300 dark:border-slate-600'
                        "
                      >
                        <div
                          v-if="shippingOption === 'inside_dhaka'"
                          class="w-2 h-2 bg-white rounded-full animate-scale-in"
                        ></div>
                      </div>
                    </div>
                  </div>
                </label>
              </div>

              <!-- Outside Dhaka -->
              <div class="payment-option-container">
                <URadio
                  v-model="shippingOption"
                  name="shipping"
                  value="outside_dhaka"
                  class="sr-only"
                  id="outside_dhaka"
                />
                <label
                  for="outside_dhaka"
                  class="block p-4 border rounded-lg transition-all duration-200 cursor-pointer relative"
                  :class="
                    shippingOption === 'outside_dhaka'
                      ? 'border-sky-500 dark:border-sky-500 bg-sky-50 dark:bg-sky-900/20 ring-1 ring-sky-500/30'
                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50'
                  "
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 flex-shrink-0 rounded-md bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
                      >
                        <UIcon
                          name="i-heroicons-truck"
                          class="w-5 h-5 text-sky-600 dark:text-sky-400"
                        />
                      </div>
                      <div>
                        <p class="font-medium">Outside Dhaka</p>
                        <p class="text-xs text-slate-500 dark:text-slate-400">
                          Delivery in 3-5 business days
                        </p>
                      </div>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="font-medium">৳150</span>
                      <div
                        class="flex items-center justify-center w-5 h-5 rounded-full border-2"
                        :class="
                          shippingOption === 'outside_dhaka'
                            ? 'bg-sky-500 border-sky-500 flex items-center justify-center'
                            : 'border-slate-300 dark:border-slate-600'
                        "
                      >
                        <div
                          v-if="shippingOption === 'outside_dhaka'"
                          class="w-2 h-2 bg-white rounded-full animate-scale-in"
                        ></div>
                      </div>
                    </div>
                  </div>
                </label>
              </div>
            </div>

            <!-- Payment Method Selection - FIXED -->
            <div class="mb-6">
              <h3 class="text-base font-medium mb-3 flex items-center">
                <UIcon
                  name="i-heroicons-credit-card"
                  class="mr-2 text-sky-500 w-4 h-4"
                />
                Payment Method
              </h3>

              <!-- Account Funds Option -->
              <div class="payment-option-container mb-3">
                <URadio
                  v-model="paymentMethod"
                  name="payment"
                  value="account_funds"
                  class="sr-only"
                  id="account_funds"
                />
                <label
                  for="account_funds"
                  class="block p-4 border rounded-lg transition-all duration-200 cursor-pointer relative"
                  :class="
                    paymentMethod === 'account_funds'
                      ? 'border-sky-500 dark:border-sky-500 bg-sky-50 dark:bg-sky-900/20 ring-1 ring-sky-500/30'
                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50'
                  "
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 flex-shrink-0 rounded-md bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
                      >
                        <UIcon
                          name="i-heroicons-wallet"
                          class="w-5 h-5 text-sky-600 dark:text-sky-400"
                        />
                      </div>
                      <div>
                        <p class="font-medium">Account Funds</p>
                        <p class="text-xs text-slate-500 dark:text-slate-400">
                          Available balance: ৳3,500
                        </p>
                      </div>
                    </div>
                    <div
                      class="flex items-center justify-center w-5 h-5 rounded-full border-2"
                      :class="
                        paymentMethod === 'account_funds'
                          ? 'bg-sky-500 border-sky-500 flex items-center justify-center'
                          : 'border-slate-300 dark:border-slate-600'
                      "
                    >
                      <div
                        v-if="paymentMethod === 'account_funds'"
                        class="w-2 h-2 bg-white rounded-full animate-scale-in"
                      ></div>
                    </div>
                  </div>

                  <!-- Instant badge -->
                  <div class="absolute top-2 right-2">
                    <span
                      class="px-1.5 py-0.5 text-[10px] uppercase tracking-wider font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 rounded"
                      >Instant</span
                    >
                  </div>
                </label>
              </div>

              <!-- Cash on Delivery Option -->
              <div class="payment-option-container">
                <URadio
                  v-model="paymentMethod"
                  name="payment"
                  value="cod"
                  class="sr-only"
                  id="cod"
                />
                <label
                  for="cod"
                  class="block p-4 border rounded-lg transition-all duration-200 cursor-pointer relative"
                  :class="
                    paymentMethod === 'cod'
                      ? 'border-sky-500 dark:border-sky-500 bg-sky-50 dark:bg-sky-900/20 ring-1 ring-sky-500/30'
                      : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800/50'
                  "
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 flex-shrink-0 rounded-md bg-slate-100 dark:bg-slate-700 flex items-center justify-center"
                      >
                        <UIcon
                          name="i-heroicons-banknotes"
                          class="w-5 h-5 text-green-600 dark:text-green-400"
                        />
                      </div>
                      <div>
                        <p class="font-medium">Cash on Delivery</p>
                        <p class="text-xs text-slate-500 dark:text-slate-400">
                          Pay when your order arrives
                        </p>
                      </div>
                    </div>
                    <div
                      class="flex items-center justify-center w-5 h-5 rounded-full border-2"
                      :class="
                        paymentMethod === 'cod'
                          ? 'bg-sky-500 border-sky-500 flex items-center justify-center'
                          : 'border-slate-300 dark:border-slate-600'
                      "
                    >
                      <div
                        v-if="paymentMethod === 'cod'"
                        class="w-2 h-2 bg-white rounded-full animate-scale-in"
                      ></div>
                    </div>
                  </div>

                  <!-- Popular badge -->
                  <div class="absolute top-2 right-2">
                    <span
                      class="px-1.5 py-0.5 text-[10px] uppercase tracking-wider font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 rounded"
                      >Popular</span
                    >
                  </div>
                </label>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex flex-col gap-3">
              <button
                class="w-full py-3 font-medium relative overflow-hidden group"
                :class="[
                  isSubscribing
                    ? 'cursor-not-allowed opacity-80'
                    : 'cursor-pointer',
                  'bg-gradient-to-r from-sky-500 to-blue-500 hover:from-sky-600 hover:to-blue-600 text-white rounded-xl transition-all duration-300',
                ]"
                @click="createSubscription"
                :disabled="isSubscribing"
              >
                <span
                  class="relative z-10 flex items-center justify-center gap-2"
                >
                  <span v-if="isSubscribing" class="flex items-center">
                    <UIcon
                      name="i-heroicons-arrow-path"
                      class="w-4 h-4 animate-spin mr-2"
                    />
                    Processing...
                  </span>
                  <span v-else>
                    Confirm Purchase
                    <UIcon
                      name="i-heroicons-arrow-right"
                      class="w-4 h-4 transition-transform group-hover:translate-x-1"
                    />
                  </span>
                </span>
                <div
                  class="absolute inset-0 w-full h-full bg-gradient-to-r from-white/0 via-white/20 to-white/0 -translate-x-full group-hover:animate-shimmer"
                ></div>
              </button>

              <button
                class="w-full py-3 border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800 transition-all duration-200 font-medium"
                @click="openBuyModal = false"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </UModal>
    <UModal
      v-model="showSuccessModal"
      :ui="{
        width: 'sm:max-w-md',
        overlay: {
          background: 'bg-slate-900/40 backdrop-blur-sm',
        },
        container: 'transition-all duration-300 ease-out-cubic',
      }"
      transition="zoom-fade"
    >
      <div class="success-modal rounded-xl overflow-hidden">
        <!-- Animated Success Header -->
        <div class="relative overflow-hidden">
          <div
            class="absolute inset-0 bg-gradient-to-r from-emerald-500/20 to-green-500/20 animate-gradient"
          ></div>
          <div
            class="relative px-6 pt-8 pb-6 bg-gradient-to-r from-emerald-500 to-green-500 flex flex-col items-center"
          >
            <!-- Animated confetti -->
            <div
              class="absolute top-3 right-10 w-1.5 h-1.5 rounded-full bg-white/30 animate-ping-slow"
            ></div>
            <div
              class="absolute bottom-10 left-8 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.8s"
            ></div>
            <div
              class="absolute top-12 left-10 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 1.2s"
            ></div>
            <div
              class="absolute bottom-4 right-12 w-2 h-2 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.4s"
            ></div>

            <!-- Success icon with animations -->
            <div class="relative mb-4">
              <!-- Outer rings animation -->
              <div
                class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/20 animate-pulse-slow"
              ></div>
              <div
                class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/10 animate-pulse-slower"
                style="animation-delay: 0.5s"
              ></div>

              <!-- Icon container -->
              <div
                class="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center z-10 relative"
              >
                <UIcon name="i-heroicons-check" class="w-10 h-10 text-white" />

                <!-- Success rays -->
                <div class="absolute inset-0 success-rays"></div>
              </div>
            </div>

            <h2 class="text-white font-bold text-2xl mb-1">
              Payment Successful!
            </h2>
            <div class="flex items-center gap-1">
              <UIcon
                name="i-heroicons-shield-check"
                class="w-4 h-4 text-white/80"
              />
              <p class="text-green-50 text-sm">
                Transaction processed securely
              </p>
            </div>
          </div>
        </div>

        <!-- Success Content -->
        <div class="p-6 bg-white dark:bg-slate-800">
          <div class="mb-6">
            <div class="flex flex-col gap-4">
              <!-- Success details card -->
              <div
                class="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/30 border border-slate-100 dark:border-slate-700/50"
              >
                <div class="flex justify-between items-center mb-3">
                  <span class="text-slate-500 dark:text-slate-400">Plan:</span>
                  <span class="font-semibold text-slate-800 dark:text-white"
                    >Pro Plan</span
                  >
                </div>
                <div class="flex justify-between items-center mb-3">
                  <span class="text-slate-500 dark:text-slate-400"
                    >Amount:</span
                  >
                  <span class="font-semibold text-slate-800 dark:text-white"
                    >৳2,900</span
                  >
                </div>
                <div class="flex justify-between items-center">
                  <span class="text-slate-500 dark:text-slate-400"
                    >Active until:</span
                  >
                  <span class="font-semibold text-slate-800 dark:text-white">{{
                    new Date(
                      Date.now() + 30 * 24 * 60 * 60 * 1000
                    ).toLocaleDateString()
                  }}</span>
                </div>

                <!-- Animated tick marks -->
                <div
                  class="mt-4 pt-3 border-t border-slate-200 dark:border-slate-600/50"
                >
                  <div
                    class="flex items-center gap-2 mb-2 animate-fade-in"
                    style="animation-delay: 0.2s"
                  >
                    <div
                      class="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-check"
                        class="w-3 h-3 text-green-500"
                      />
                    </div>
                    <span class="text-sm text-slate-600 dark:text-slate-300"
                      >Unlimited products activated</span
                    >
                  </div>
                  <div
                    class="flex items-center gap-2 animate-fade-in"
                    style="animation-delay: 0.4s"
                  >
                    <div
                      class="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-check"
                        class="w-3 h-3 text-green-500"
                      />
                    </div>
                    <span class="text-sm text-slate-600 dark:text-slate-300"
                      >Priority support enabled</span
                    >
                  </div>
                </div>
              </div>

              <!-- Receipt ID -->
              <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500 dark:text-slate-400"
                  >Transaction ID:</span
                >
                <code
                  class="bg-slate-100 dark:bg-slate-700/50 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-mono"
                  >{{
                    "TXN_" +
                    Math.random().toString(36).substring(2, 10).toUpperCase()
                  }}</code
                >
              </div>
            </div>
          </div>

          <button
            class="w-full py-3.5 group relative rounded-xl font-medium overflow-hidden transform transition-all duration-300 active:scale-[0.98] hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-emerald-500/30 dark:focus:ring-emerald-400/30 flex justify-center"
            @click="goToDashboard"
          >
            <!-- Layered background with 3D effect -->
            <div
              class="absolute inset-0 bg-gradient-to-br from-emerald-600 to-green-600 shadow-lg"
            ></div>
            <div
              class="absolute inset-[1px] bg-gradient-to-r from-emerald-500 to-green-500 rounded-[10px]"
            ></div>
            <div
              class="absolute inset-0 bg-gradient-to-r from-emerald-400/0 via-white/30 to-emerald-400/0 -translate-x-full group-hover:animate-shimmer-slow"
            ></div>

            <!-- Button content -->
            <div
              class="relative z-10 flex items-center justify-center gap-2 text-white"
            >
              <!-- Particle effects that appear on hover -->
              <div
                class="absolute -top-2 -left-2 w-1 h-1 rounded-full bg-white/80 opacity-0 group-hover:opacity-100 group-hover:animate-float-up-left transition-opacity"
              ></div>
              <div
                class="absolute -top-1 left-1/4 w-1.5 h-1.5 rounded-full bg-white/60 opacity-0 group-hover:opacity-100 group-hover:animate-float-up-slow transition-opacity"
                style="animation-delay: 0.2s"
              ></div>
              <div
                class="absolute -top-1.5 right-1/3 w-1 h-1 rounded-full bg-white/70 opacity-0 group-hover:opacity-100 group-hover:animate-float-up transition-opacity"
                style="animation-delay: 0.5s"
              ></div>

              <!-- Success check icon that appears on hover -->
              <span
                class="flex items-center justify-center absolute -left-6 opacity-0 group-hover:opacity-100 group-hover:left-3 transition-all duration-300"
              >
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-white"
                />
              </span>

              <!-- Text with slide effect -->
              <span
                class="transform group-hover:translate-x-2 transition-transform duration-300"
              >
                Continue to Home
              </span>

              <!-- Animated arrow -->
              <span
                class="relative flex items-center transform group-hover:translate-x-1.5 transition-all duration-300"
              >
                <UIcon name="i-heroicons-arrow-right" class="w-5 h-5" />

                <!-- Arrow trail effect -->
                <span
                  class="absolute inset-0 opacity-0 group-hover:opacity-70 group-hover:animate-ping-fast"
                ></span>
              </span>
            </div>

            <!-- Bottom highlight for 3D effect -->
            <div
              class="absolute bottom-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-emerald-300 to-transparent opacity-50 group-hover:opacity-80 transition-opacity"
            ></div>
          </button>
        </div>
      </div>
    </UModal>

    <!-- Failure Modal -->
    <UModal
      v-model="showFailureModal"
      :ui="{
        width: 'sm:max-w-md',
        overlay: {
          background: 'bg-slate-900/40 backdrop-blur-sm',
        },
        container: 'transition-all duration-300 ease-out-cubic',
      }"
      transition="zoom-fade"
    >
      <div class="failure-modal rounded-xl overflow-hidden">
        <!-- Animated Failure Header -->
        <div class="relative overflow-hidden">
          <div
            class="absolute inset-0 bg-gradient-to-r from-red-500/20 to-orange-500/20 animate-gradient"
          ></div>
          <div
            class="relative px-6 pt-8 pb-6 bg-gradient-to-r from-red-500 to-orange-500 flex flex-col items-center"
          >
            <!-- Animated particles -->
            <div
              class="absolute top-5 right-12 w-1.5 h-1.5 rounded-full bg-white/20 animate-ping-slow"
            ></div>
            <div
              class="absolute bottom-8 left-10 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.6s"
            ></div>

            <!-- Error icon with animations -->
            <div class="relative mb-4">
              <!-- Pulsing effect -->
              <div
                class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/20 animate-pulse-slow"
              ></div>

              <!-- Icon container -->
              <div
                class="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center z-10 relative"
              >
                <UIcon
                  name="i-heroicons-exclamation-triangle"
                  class="w-10 h-10 text-white animate-subtle-bounce"
                />
              </div>
            </div>

            <h2 class="text-white font-bold text-2xl mb-1">Payment Failed</h2>
            <p class="text-red-50 text-sm">We couldn't process your payment</p>
          </div>
        </div>

        <!-- Failure Content -->
        <div class="p-6 bg-white dark:bg-slate-800">
          <div class="mb-6">
            <!-- Error message card -->
            <div
              class="p-4 rounded-lg bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/20 mb-4"
            >
              <div class="flex items-start gap-3">
                <UIcon
                  name="i-heroicons-information-circle"
                  class="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5"
                />
                <div>
                  <p class="text-sm text-red-700 dark:text-red-300">
                    {{
                      errorMessage ||
                      "We couldn't process your payment. Your account hasn't been charged."
                    }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Suggested solutions -->
            <div class="space-y-2 mb-5">
              <p class="text-sm font-medium text-slate-700 dark:text-slate-300">
                Suggested solutions:
              </p>
              <div
                class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
              >
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 text-slate-400"
                />
                <span>Try a different payment method</span>
              </div>
              <div
                class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
              >
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 text-slate-400"
                />
                <span>Check your account balance</span>
              </div>
              <div
                class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
              >
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 text-slate-400"
                />
                <span>Contact customer support if the issue persists</span>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex flex-col gap-3">
            <UButton
              class="w-full"
              :ui="{
                rounded: 'rounded-xl',
                padding: 'py-3',
                variant: {
                  solid:
                    'bg-gradient-to-r from-red-500 to-orange-500 hover:from-red-600 hover:to-orange-600 text-white shadow-sm',
                },
              }"
              variant="solid"
              @click="showFailureModal = false"
            >
              <span class="flex items-center justify-center gap-1">
                <UIcon name="i-heroicons-arrow-path" class="w-4 h-4" />
                Try Again
              </span>
            </UButton>

            <UButton
              color="gray"
              variant="soft"
              class="rounded-xl py-2.5"
              @click="handleFailureClose"
            >
              Cancel
            </UButton>
          </div>
        </div>
      </div>
    </UModal>
    <!-- Success Modal -->
    <UModal
      v-model="showSuccessModal"
      :ui="{
        width: 'sm:max-w-md',
        overlay: {
          background: 'bg-slate-900/40 backdrop-blur-sm',
        },
        container: 'transition-all duration-300 ease-out-cubic',
      }"
      transition="zoom-fade"
    >
      <div class="success-modal rounded-xl overflow-hidden">
        <!-- Animated Success Header -->
        <div class="relative overflow-hidden">
          <div
            class="absolute inset-0 bg-gradient-to-r from-emerald-500/20 to-green-500/20 animate-gradient"
          ></div>
          <div
            class="relative px-6 pt-8 pb-6 bg-gradient-to-r from-emerald-500 to-green-500 flex flex-col items-center"
          >
            <!-- Animated confetti -->
            <div
              class="absolute top-3 right-10 w-1.5 h-1.5 rounded-full bg-white/30 animate-ping-slow"
            ></div>
            <div
              class="absolute bottom-10 left-8 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.8s"
            ></div>
            <div
              class="absolute top-12 left-10 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 1.2s"
            ></div>
            <div
              class="absolute bottom-4 right-12 w-2 h-2 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.4s"
            ></div>

            <!-- Success icon with animations -->
            <div class="relative mb-4">
              <!-- Outer rings animation -->
              <div
                class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/20 animate-pulse-slow"
              ></div>
              <div
                class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/10 animate-pulse-slower"
                style="animation-delay: 0.5s"
              ></div>

              <!-- Icon container -->
              <div
                class="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center z-10 relative"
              >
                <UIcon name="i-heroicons-check" class="w-10 h-10 text-white" />

                <!-- Success rays -->
                <div class="absolute inset-0 success-rays"></div>
              </div>
            </div>

            <h2 class="text-white font-bold text-2xl mb-1">
              Payment Successful!
            </h2>
            <div class="flex items-center gap-1">
              <UIcon
                name="i-heroicons-shield-check"
                class="w-4 h-4 text-white/80"
              />
              <p class="text-green-50 text-sm">
                Transaction processed securely
              </p>
            </div>
          </div>
        </div>

        <!-- Success Content -->
        <div class="p-6 bg-white dark:bg-slate-800">
          <div class="mb-6">
            <div class="flex flex-col gap-4">
              <!-- Success details card -->
              <div
                class="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/30 border border-slate-100 dark:border-slate-700/50"
              >
                <div class="flex justify-between items-center mb-3">
                  <span class="text-slate-500 dark:text-slate-400">Plan:</span>
                  <span class="font-semibold text-slate-800 dark:text-white"
                    >Pro Plan</span
                  >
                </div>
                <div class="flex justify-between items-center mb-3">
                  <span class="text-slate-500 dark:text-slate-400"
                    >Amount:</span
                  >
                  <span class="font-semibold text-slate-800 dark:text-white"
                    >৳2,900</span
                  >
                </div>
                <div class="flex justify-between items-center">
                  <span class="text-slate-500 dark:text-slate-400"
                    >Active until:</span
                  >
                  <span class="font-semibold text-slate-800 dark:text-white">{{
                    new Date(
                      Date.now() + 30 * 24 * 60 * 60 * 1000
                    ).toLocaleDateString()
                  }}</span>
                </div>

                <!-- Animated tick marks -->
                <div
                  class="mt-4 pt-3 border-t border-slate-200 dark:border-slate-600/50"
                >
                  <div
                    class="flex items-center gap-2 mb-2 animate-fade-in"
                    style="animation-delay: 0.2s"
                  >
                    <div
                      class="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-check"
                        class="w-3 h-3 text-green-500"
                      />
                    </div>
                    <span class="text-sm text-slate-600 dark:text-slate-300"
                      >Unlimited products activated</span
                    >
                  </div>
                  <div
                    class="flex items-center gap-2 animate-fade-in"
                    style="animation-delay: 0.4s"
                  >
                    <div
                      class="flex-shrink-0 w-5 h-5 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-check"
                        class="w-3 h-3 text-green-500"
                      />
                    </div>
                    <span class="text-sm text-slate-600 dark:text-slate-300"
                      >Priority support enabled</span
                    >
                  </div>
                </div>
              </div>

              <!-- Receipt ID -->
              <div class="flex items-center justify-between text-sm">
                <span class="text-slate-500 dark:text-slate-400"
                  >Transaction ID:</span
                >
                <code
                  class="bg-slate-100 dark:bg-slate-700/50 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-mono"
                  >{{
                    "TXN_" +
                    Math.random().toString(36).substring(2, 10).toUpperCase()
                  }}</code
                >
              </div>
            </div>
          </div>

          <button
            class="w-full py-3.5 group relative rounded-xl font-medium overflow-hidden transform transition-all duration-300 active:scale-[0.98] hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-emerald-500/30 dark:focus:ring-emerald-400/30 flex justify-center"
            @click="goToDashboard"
          >
            <!-- Layered background with 3D effect -->
            <div
              class="absolute inset-0 bg-gradient-to-br from-emerald-600 to-green-600 shadow-lg"
            ></div>
            <div
              class="absolute inset-[1px] bg-gradient-to-r from-emerald-500 to-green-500 rounded-[10px]"
            ></div>
            <div
              class="absolute inset-0 bg-gradient-to-r from-emerald-400/0 via-white/30 to-emerald-400/0 -translate-x-full group-hover:animate-shimmer-slow"
            ></div>

            <!-- Button content -->
            <div
              class="relative z-10 flex items-center justify-center gap-2 text-white"
            >
              <!-- Particle effects that appear on hover -->
              <div
                class="absolute -top-2 -left-2 w-1 h-1 rounded-full bg-white/80 opacity-0 group-hover:opacity-100 group-hover:animate-float-up-left transition-opacity"
              ></div>
              <div
                class="absolute -top-1 left-1/4 w-1.5 h-1.5 rounded-full bg-white/60 opacity-0 group-hover:opacity-100 group-hover:animate-float-up-slow transition-opacity"
                style="animation-delay: 0.2s"
              ></div>
              <div
                class="absolute -top-1.5 right-1/3 w-1 h-1 rounded-full bg-white/70 opacity-0 group-hover:opacity-100 group-hover:animate-float-up transition-opacity"
                style="animation-delay: 0.5s"
              ></div>

              <!-- Success check icon that appears on hover -->
              <span
                class="flex items-center justify-center absolute -left-6 opacity-0 group-hover:opacity-100 group-hover:left-3 transition-all duration-300"
              >
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-white"
                />
              </span>

              <!-- Text with slide effect -->
              <span
                class="transform group-hover:translate-x-2 transition-transform duration-300"
              >
                Continue to Home
              </span>

              <!-- Animated arrow -->
              <span
                class="relative flex items-center transform group-hover:translate-x-1.5 transition-all duration-300"
              >
                <UIcon name="i-heroicons-arrow-right" class="w-5 h-5" />

                <!-- Arrow trail effect -->
                <span
                  class="absolute inset-0 opacity-0 group-hover:opacity-70 group-hover:animate-ping-fast"
                ></span>
              </span>
            </div>

            <!-- Bottom highlight for 3D effect -->
            <div
              class="absolute bottom-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-emerald-300 to-transparent opacity-50 group-hover:opacity-80 transition-opacity"
            ></div>
          </button>
        </div>
      </div>
    </UModal>

    <!-- Failure Modal -->
    <UModal
      v-model="showFailureModal"
      :ui="{
        width: 'sm:max-w-md',
        overlay: {
          background: 'bg-slate-900/40 backdrop-blur-sm',
        },
        container: 'transition-all duration-300 ease-out-cubic',
      }"
      transition="zoom-fade"
    >
      <div class="failure-modal rounded-xl overflow-hidden">
        <!-- Animated Failure Header -->
        <div class="relative overflow-hidden">
          <div
            class="absolute inset-0 bg-gradient-to-r from-red-500/20 to-orange-500/20 animate-gradient"
          ></div>
          <div
            class="relative px-6 pt-8 pb-6 bg-gradient-to-r from-red-500 to-orange-500 flex flex-col items-center"
          >
            <!-- Animated particles -->
            <div
              class="absolute top-5 right-12 w-1.5 h-1.5 rounded-full bg-white/20 animate-ping-slow"
            ></div>
            <div
              class="absolute bottom-8 left-10 w-1 h-1 rounded-full bg-white/20 animate-ping-slow"
              style="animation-delay: 0.6s"
            ></div>

            <!-- Error icon with animations -->
            <div class="relative mb-4">
              <!-- Pulsing effect -->
              <div
                class="absolute inset-0 w-20 h-20 rounded-full border-4 border-white/20 animate-pulse-slow"
              ></div>

              <!-- Icon container -->
              <div
                class="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center z-10 relative"
              >
                <UIcon
                  name="i-heroicons-exclamation-triangle"
                  class="w-10 h-10 text-white animate-subtle-bounce"
                />
              </div>
            </div>

            <h2 class="text-white font-bold text-2xl mb-1">Payment Failed</h2>
            <p class="text-red-50 text-sm">We couldn't process your payment</p>
          </div>
        </div>

        <!-- Failure Content -->
        <div class="p-6 bg-white dark:bg-slate-800">
          <div class="mb-6">
            <!-- Error message card -->
            <div
              class="p-4 rounded-lg bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/20 mb-4"
            >
              <div class="flex items-start gap-3">
                <UIcon
                  name="i-heroicons-information-circle"
                  class="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5"
                />
                <div>
                  <p class="text-sm text-red-700 dark:text-red-300">
                    {{
                      errorMessage ||
                      "We couldn't process your payment. Your account hasn't been charged."
                    }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Suggested solutions -->
            <div class="space-y-2 mb-5">
              <p class="text-sm font-medium text-slate-700 dark:text-slate-300">
                Suggested solutions:
              </p>
              <div
                class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
              >
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 text-slate-400"
                />
                <span>Try a different payment method</span>
              </div>
              <div
                class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
              >
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 text-slate-400"
                />
                <span>Check your account balance</span>
              </div>
              <div
                class="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400"
              >
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 text-slate-400"
                />
                <span>Contact customer support if the issue persists</span>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex flex-col gap-3">
            <UButton
              class="w-full"
              :ui="{
                rounded: 'rounded-xl',
                padding: 'py-3',
                variant: {
                  solid:
                    'bg-gradient-to-r from-red-500 to-orange-500 hover:from-red-600 hover:to-orange-600 text-white shadow-sm',
                },
              }"
              variant="solid"
              @click="showFailureModal = false"
            >
              <span class="flex items-center justify-center gap-1">
                <UIcon name="i-heroicons-arrow-path" class="w-4 h-4" />
                Try Again
              </span>
            </UButton>

            <UButton
              color="gray"
              variant="soft"
              class="rounded-xl py-2.5"
              @click="handleFailureClose"
            >
              Cancel
            </UButton>
          </div>
        </div>
      </div>
    </UModal>
  </UContainer>
</template>

<script setup>
// State
const openBuyModal = ref(false);
const isOpen = ref(false);
const searchQuery = ref("");
const selectedCategory = ref(null);
const searchInput = ref(null);

const imageLoaded = ref(false);
// Sample category data with random product counts
const categories = [
  {
    id: 1,
    name: "Electronics",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-device-phone-mobile",
  },
  {
    id: 2,
    name: "Clothing & Fashion",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-shirt",
  },
  {
    id: 3,
    name: "Home & Kitchen",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-home",
  },
  {
    id: 4,
    name: "Beauty & Personal Care",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-sparkles",
  },
  {
    id: 5,
    name: "Books & Stationery",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-book-open",
  },
  {
    id: 6,
    name: "Sports & Outdoors",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-trophy",
  },
  {
    id: 7,
    name: "Toys & Games",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-puzzle-piece",
  },
  {
    id: 8,
    name: "Health & Wellness",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-heart",
  },
  {
    id: 9,
    name: "Automotive",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-truck",
  },
  {
    id: 10,
    name: "Jewelry & Watches",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-clock",
  },
  {
    id: 11,
    name: "Food & Grocery",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-shopping-bag",
  },
  {
    id: 12,
    name: "Baby & Kids",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-face-smile",
  },
  {
    id: 13,
    name: "Pet Supplies",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-bug-ant",
  },
  {
    id: 14,
    name: "Office Supplies",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-document",
  },
  {
    id: 15,
    name: "Musical Instruments",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-musical-note",
  },
  {
    id: 16,
    name: "Garden & Outdoor",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-sun",
  },
  {
    id: 17,
    name: "Furniture",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-cube",
  },
  {
    id: 18,
    name: "Computers & Accessories",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-computer-desktop",
  },
  {
    id: 19,
    name: "Arts & Crafts",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-paint-brush",
  },
  {
    id: 20,
    name: "Travel & Luggage",
    count: Math.floor(Math.random() * 500) + 100,
    icon: "i-heroicons-globe-alt",
  },
];

// Total product count
const totalProductCount = computed(() => {
  return categories.reduce((total, category) => total + category.count, 0);
});

// Filter categories based on search query
const filteredCategories = computed(() => {
  if (!searchQuery.value) return categories;

  const query = searchQuery.value.toLowerCase();
  return categories.filter((category) =>
    category.name.toLowerCase().includes(query)
  );
});

// Toggle dropdown
const toggleDropdown = () => {
  isOpen.value = !isOpen.value;

  if (isOpen.value) {
    // Focus search input when dropdown opens
    setTimeout(() => {
      searchInput.value?.focus();
    }, 100);
  } else {
    // Clear search when dropdown closes
    searchQuery.value = "";
  }
};

// Select a category
const selectCategory = (category) => {
  selectedCategory.value = category;
  isOpen.value = false;
  searchQuery.value = "";

  // In a real app, you would trigger a product filter here
  console.log(
    `Selected category: ${category ? category.name : "All Categories"}`
  );
};

// Close dropdown when clicking outside
const handleClickOutside = (event) => {
  if (isOpen.value && !event.target.closest(".category-dropdown-container")) {
    isOpen.value = false;
    searchQuery.value = "";
  }
};

// Keyboard navigation
const handleKeyDown = (event) => {
  if (event.key === "Escape" && isOpen.value) {
    isOpen.value = false;
    searchQuery.value = "";
  }
};

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
  document.addEventListener("keydown", handleKeyDown);
});

onBeforeUnmount(() => {
  document.removeEventListener("click", handleClickOutside);
  document.removeEventListener("keydown", handleKeyDown);
});
// Product carousel and modal state
const currentSlide = ref(0);
const itemsPerSlide = ref(5);
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);
const userRating = ref(0);
const reviewComment = ref("");

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
  {
    id: 2,
    name: "Smartphone With 108MP Camera",
    price: "32,999",
    oldPrice: "36,999",
    discount: 10,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Smartphone",
    category: "Electronics",
    rating: 4.7,
    description:
      "Capture stunning photos with the 108MP camera system. Features a 6.7-inch display, 5G connectivity, and all-day battery life.",
    reviews: [
      {
        name: "Rajib Hossain",
        rating: 5,
        date: "February 28, 2025",
        comment:
          "The camera on this phone is incredible! Battery life exceeds my expectations.",
        avatar: "",
      },
    ],
  },
  {
    id: 3,
    name: "Men's Premium Cotton T-Shirt",
    price: "999",
    oldPrice: "1,499",
    discount: 33,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=T-Shirt",
    category: "Clothing & Fashion",
    rating: 4.5,
    description:
      "Made from 100% premium cotton for maximum comfort and durability. Available in multiple colors and sizes.",
    reviews: [
      {
        name: "Kamal Rahman",
        rating: 5,
        date: "March 15, 2025",
        comment:
          "The quality of this t-shirt is exceptional. Fits perfectly and feels great!",
        avatar: "",
      },
      {
        name: "Nazia Islam",
        rating: 4,
        date: "March 2, 2025",
        comment:
          "Nice fabric quality but runs slightly large. I recommend sizing down.",
        avatar: "",
      },
    ],
  },
  {
    id: 4,
    name: "Smart Fitness Tracker Watch",
    price: "4,599",
    oldPrice: "5,999",
    discount: 23,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Watch",
    category: "Wearables",
    rating: 4.6,
    description:
      "Track your steps, heart rate, sleep quality and more with this advanced fitness tracker. Includes GPS and 15+ sport modes.",
    reviews: [
      {
        name: "Tanvir Ahmed",
        rating: 5,
        date: "February 20, 2025",
        comment:
          "Accurate tracking and the battery lasts for days! Great value for money.",
        avatar: "",
      },
    ],
  },
  {
    id: 5,
    name: "Non-stick Cookware Set (10 Pieces)",
    price: "5,999",
    oldPrice: "8,999",
    discount: 33,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Cookware",
    category: "Home & Kitchen",
    rating: 4.9,
    description:
      "Complete cookware set featuring non-stick coating and heat-resistant handles. Includes pots, pans, and cooking utensils.",
    reviews: [
      {
        name: "Sabina Yasmin",
        rating: 5,
        date: "March 10, 2025",
        comment:
          "Everything you need in one set! The quality is excellent and they clean up so easily.",
        avatar: "",
      },
    ],
  },
  {
    id: 6,
    name: "Digital SLR Camera with 18-55mm Lens",
    price: "42,999",
    oldPrice: "49,999",
    discount: 14,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Camera",
    category: "Electronics",
    rating: 4.7,
    description:
      "Perfect for beginners and enthusiasts alike. Features a 24.1MP sensor, optical viewfinder, and fast autofocus system.",
    reviews: [
      {
        name: "Rakib Hasan",
        rating: 4,
        date: "February 25, 2025",
        comment:
          "Great camera for beginners! Easy to use with excellent image quality.",
        avatar: "",
      },
    ],
  },
  {
    id: 7,
    name: "Organic Skincare Gift Set",
    price: "2,899",
    oldPrice: "3,499",
    discount: 17,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Skincare",
    category: "Beauty & Personal Care",
    rating: 4.8,
    description:
      "All-natural and organic skincare products featuring cleanser, toner, moisturizer, and face mask. Perfect for all skin types.",
    reviews: [
      {
        name: "Nusrat Jahan",
        rating: 5,
        date: "March 18, 2025",
        comment:
          "My skin feels amazing after using these products. Love that they're all organic!",
        avatar: "",
      },
    ],
  },
  {
    id: 8,
    name: "Bluetooth Portable Speaker",
    price: "2,499",
    oldPrice: "2,999",
    discount: 16,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Speaker",
    category: "Electronics",
    rating: 4.5,
    description:
      "Compact yet powerful speaker with 20W output and waterproof design. Perfect for outdoor adventures or home use.",
    reviews: [
      {
        name: "Mehedi Hasan",
        rating: 4,
        date: "March 5, 2025",
        comment:
          "Great sound quality for its size. Battery life could be better though.",
        avatar: "",
      },
    ],
  },
  {
    id: 9,
    name: "Stainless Steel Water Bottle",
    price: "799",
    oldPrice: "999",
    discount: 20,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Bottle",
    category: "Sports & Outdoors",
    rating: 4.9,
    description:
      "Keeps drinks cold for 24 hours or hot for 12 hours. Durable, leak-proof design with eco-friendly materials.",
    reviews: [
      {
        name: "Tamanna Akter",
        rating: 5,
        date: "March 15, 2025",
        comment:
          "Best water bottle I've ever had. Keeps my water cold all day long!",
        avatar: "",
      },
    ],
  },
  {
    id: 10,
    name: "Professional Knife Set with Block",
    price: "4,999",
    oldPrice: "7,999",
    discount: 37,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Knives",
    category: "Home & Kitchen",
    rating: 4.7,
    description:
      "Complete 15-piece knife set with premium stainless steel blades. Includes chef's knife, bread knife, steak knives, and more.",
    reviews: [
      {
        name: "Imran Hossain",
        rating: 5,
        date: "February 22, 2025",
        comment:
          "Very sharp knives and the block looks great on my counter. Worth every penny.",
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
function openBuyEvent(product) {
  selectedProduct.value = product;
  openBuyModal.value = true;

  quantity.value = 1;
  userRating.value = 0;
  reviewComment.value = "";
}

function submitReview() {
  if (!userRating.value || !reviewComment.value.trim()) {
    // You could add toast notification here
    return;
  }

  // Add review to product
  selectedProduct.value.reviews.unshift({
    name: "You", // In a real app, this would be the user's name
    rating: userRating.value,
    date: "Just now",
    comment: reviewComment.value.trim(),
    avatar: "", // In a real app, this would be the user's avatar
  });

  // Reset form
  userRating.value = 0;
  reviewComment.value = "";
}

// Add these refs to your script setup section
const activeImage = ref(null);
const selectedThumb = ref(-1);
const imageZoomed = ref(false);

// Generate random thumbnail images from the main image
// In a real app, you'd have actual additional product images
const thumbnailImages = computed(() => {
  return Array(4).fill(selectedProduct.value?.image || "");
});

// Calculate price savings
function calculateSavings(currentPrice, oldPrice) {
  // Remove commas and convert to numbers
  const current = Number(currentPrice.replace(/,/g, ""));
  const old = Number(oldPrice.replace(/,/g, ""));
  return (old - current).toLocaleString();
}

// Add to existing script setup section
const shippingOption = ref("free"); // Default to free shipping

// Optional: Calculate total with shipping
const totalWithShipping = computed(() => {
  const basePrice = 2900; // Your subscription price
  let shippingCost = 0;

  if (shippingOption.value === "inside_dhaka") {
    shippingCost = 100;
  } else if (shippingOption.value === "outside_dhaka") {
    shippingCost = 150;
  }

  return basePrice + shippingCost;
});
// Add to your script setup section
const paymentMethod = ref("cod"); // Default to Cash on Delivery

// Calculate shipping cost based on option
const shippingCost = computed(() => {
  switch (shippingOption.value) {
    case "inside_dhaka":
      return 100;
    case "outside_dhaka":
      return 150;
    case "free":
    default:
      return 0;
  }
});

// Calculate final total with shipping
const orderTotal = computed(() => {
  const productPrice = selectedProduct.value
    ? Number(selectedProduct.value.price.replace(/,/g, ""))
    : 0;
  return productPrice + shippingCost.value;
});

const openModal = ref(false);
const showSuccessModal = ref(false);
const showFailureModal = ref(false);
const isLoading = ref(false);
const isSubscribing = ref(false);
const errorMessage = ref("");
const transactionId = ref("");

async function createSubscription() {
  try {
    if (paymentMethod.value === "account_funds") {
      // Account funds path - process immediately
      await new Promise((resolve) => setTimeout(resolve, 1500));

      // Simulate successful payment
      const response = {
        success: true,
        data: {
          subscription_id: "sub_" + Math.random().toString(36).substring(2, 9),
          status: "active",
          start_date: new Date().toISOString(),
          end_date: new Date(
            Date.now() + 30 * 24 * 60 * 60 * 1000
          ).toISOString(),
        },
      };

      // Generate transaction ID for display in success modal
      transactionId.value =
        "TXN_" + Math.random().toString(36).substring(2, 10).toUpperCase();

      // Show success modal
      showSuccessModal.value = true;
      openModal.value = false;
    } else if (paymentMethod.value === "surjopay") {
      // SurjoPay path - redirect to payment gateway
      await new Promise((resolve) => setTimeout(resolve, 1000));

      // In production, this would be:
      // const sessionResponse = await $api.post("/api/payment/create-session", {
      //   plan_id: 1,
      //   payment_method: paymentMethod.value,
      //   auto_renew: autoRenew.value
      // });
      // window.location.href = sessionResponse.data.payment_url;

      window.location.href = "/simulate-surjopay-redirect";
      return;
    }
  } catch (error) {
    console.error("Payment failed:", error);

    // Show error message
    errorMessage.value = error.message || "Payment processing failed";
    showFailureModal.value = true;
  } finally {
    isSubscribing.value = false;
  }
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
