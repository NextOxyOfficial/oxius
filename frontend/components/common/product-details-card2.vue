<template>
  <div class="product-sales-funnel">
    <!-- Hero Section -->
    <section
      class="hero-section bg-gradient-to-br from-slate-900 to-slate-800 text-white rounded-xl overflow-hidden"
    >
      <div class="container mx-auto px-6 py-12 md:py-20">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <!-- Product Image -->
          <div class="relative order-2 md:order-1">
            <div
              class="aspect-square rounded-xl overflow-hidden bg-white/10 backdrop-blur-sm p-6 shadow-2xl relative"
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
                class="absolute top-4 right-4 bg-red-500 text-white text-sm font-bold px-3 py-1.5 rounded-full shadow-lg animate-pulse"
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
            <h1 class="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">
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
                {{ currentProduct.reviews?.length || 125 }} verified reviews
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
              <span class="text-4xl font-bold text-white">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </span>
              <span
                v-if="currentProduct.regular_price && currentProduct.sale_price"
                class="text-lg text-white/60 line-through ml-2"
              >
                ৳{{ currentProduct.regular_price }}
              </span>
            </div>

            <!-- Primary CTA Button -->
            <button
              @click="addToCart(currentProduct, 1)"
              class="w-full md:w-auto px-8 py-4 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white text-lg font-bold rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 focus:ring-4 focus:ring-primary-500/50 flex items-center justify-center gap-3 group"
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

    <!-- Countdown Timer Section -->
    <section
      class="py-6 bg-amber-50 dark:bg-amber-900/20 rounded-lg my-6 text-center"
    >
      <p class="text-amber-800 dark:text-amber-400 font-medium mb-2">
        Limited Time Offer
      </p>
      <div class="flex justify-center gap-4">
        <div class="flex flex-col items-center">
          <div
            class="bg-white dark:bg-slate-800 w-12 h-12 rounded shadow-md flex items-center justify-center text-xl font-bold"
          >
            12
          </div>
          <span class="text-xs mt-1 text-amber-700 dark:text-amber-500"
            >Hours</span
          >
        </div>
        <div class="flex flex-col items-center">
          <div
            class="bg-white dark:bg-slate-800 w-12 h-12 rounded shadow-md flex items-center justify-center text-xl font-bold"
          >
            45
          </div>
          <span class="text-xs mt-1 text-amber-700 dark:text-amber-500"
            >Minutes</span
          >
        </div>
        <div class="flex flex-col items-center">
          <div
            class="bg-white dark:bg-slate-800 w-12 h-12 rounded shadow-md flex items-center justify-center text-xl font-bold"
          >
            22
          </div>
          <span class="text-xs mt-1 text-amber-700 dark:text-amber-500"
            >Seconds</span
          >
        </div>
      </div>
    </section>

    <!-- Key Benefits Section -->
    <section class="py-12">
      <h2 class="text-2xl md:text-3xl font-bold text-center mb-12">
        Why Choose
        <span class="text-primary-600 dark:text-primary-400">{{
          currentProduct.name
        }}</span
        >?
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div class="benefit-card">
          <div class="icon-container">
            <UIcon
              name="i-heroicons-sparkles"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <h3 class="text-xl font-semibold mb-2">Premium Quality</h3>
          <p>
            Crafted with the highest quality materials for exceptional
            durability and performance.
          </p>
        </div>

        <div class="benefit-card">
          <div class="icon-container">
            <UIcon
              name="i-heroicons-rocket-launch"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <h3 class="text-xl font-semibold mb-2">Fast Results</h3>
          <p>
            Experience immediate benefits and see results faster than with
            competing products.
          </p>
        </div>

        <div class="benefit-card">
          <div class="icon-container">
            <UIcon
              name="i-heroicons-check-badge"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <h3 class="text-xl font-semibold mb-2">Satisfaction Guarantee</h3>
          <p>
            Not completely satisfied? Return within 30 days for a full refund,
            no questions asked.
          </p>
        </div>
      </div>

      <div class="text-center mt-12">
        <button
          @click="addToCart(currentProduct, 1)"
          class="px-8 py-3 bg-gradient-to-r from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 text-white font-bold rounded-xl shadow-lg transition-all duration-300"
        >
          Yes! I Want This Now
        </button>
      </div>
    </section>

    <!-- Product Features Section -->
    <section class="py-12 bg-slate-50 dark:bg-slate-800/30 rounded-xl">
      <div class="container mx-auto px-6">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Product Details & Specifications
        </h2>
        <p
          class="text-center text-slate-600 dark:text-slate-300 mb-12 max-w-2xl mx-auto"
        >
          Experience the perfect blend of design and functionality with our
          {{ currentProduct.name }}. Designed with the modern consumer in mind.
        </p>

        <!-- Product Tabs -->
        <UTabs
          v-model="activeTab"
          :items="[
            {
              label: 'Features',
              slot: 'features',
              icon: 'i-heroicons-list-bullet',
            },
            {
              label: 'Specifications',
              slot: 'specs',
              icon: 'i-heroicons-document-text',
            },
            { label: 'Shipping', slot: 'shipping', icon: 'i-heroicons-truck' },
          ]"
          class="mb-8"
        >
          <template #features>
            <div class="py-6 max-w-3xl mx-auto">
              <div
                v-html="
                  currentProduct.description ||
                  '<p>This premium product offers exceptional performance and reliability. Built with high-quality materials and expert craftsmanship, it\'s designed to exceed your expectations.</p>'
                "
              ></div>

              <div class="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="feature-item">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                  <span>Premium Materials</span>
                </div>
                <div class="feature-item">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                  <span>Ergonomic Design</span>
                </div>
                <div class="feature-item">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                  <span>Long-lasting Performance</span>
                </div>
                <div class="feature-item">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                  <span>Energy Efficient</span>
                </div>
                <div class="feature-item">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                  <span>Easy to Use</span>
                </div>
                <div class="feature-item">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                  <span>Modern Aesthetic</span>
                </div>
              </div>
            </div>
          </template>

          <template #specs>
            <div class="py-6 max-w-3xl mx-auto">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-2">
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400">Brand:</span>
                  <span class="font-medium">Premium Selection</span>
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400">Model:</span>
                  <span class="font-medium"
                    >X-{{ 1000 + Math.floor(Math.random() * 9000) }}</span
                  >
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400"
                    >Dimensions:</span
                  >
                  <span class="font-medium">24 x 12 x 8 cm</span>
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400"
                    >Weight:</span
                  >
                  <span class="font-medium"
                    >{{ currentProduct.weight || "1.2" }} kg</span
                  >
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400"
                    >Material:</span
                  >
                  <span class="font-medium">Premium Composite</span>
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400">Color:</span>
                  <span class="font-medium">Classic Black</span>
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400"
                    >Warranty:</span
                  >
                  <span class="font-medium">1 Year</span>
                </div>
                <div
                  class="flex justify-between py-3 border-b border-slate-100 dark:border-slate-700"
                >
                  <span class="text-slate-500 dark:text-slate-400"
                    >In Stock:</span
                  >
                  <span class="font-medium"
                    >{{ currentProduct.quantity || "Limited" }} units</span
                  >
                </div>
              </div>
            </div>
          </template>

          <template #shipping>
            <div class="py-6 max-w-3xl mx-auto">
              <div
                class="mb-6 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-100 dark:border-green-900"
              >
                <div class="flex items-start">
                  <UIcon
                    name="i-heroicons-information-circle"
                    class="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 mr-2 flex-shrink-0"
                  />
                  <p class="text-green-800 dark:text-green-300 text-sm">
                    <strong>Free shipping available!</strong> Orders over ৳5,000
                    qualify for free delivery nationwide.
                  </p>
                </div>
              </div>

              <div class="space-y-4">
                <div
                  class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <UIcon
                        name="i-heroicons-truck"
                        class="w-5 h-5 text-slate-600 dark:text-slate-300 mr-2"
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

                <div
                  class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <UIcon
                        name="i-heroicons-truck"
                        class="w-5 h-5 text-slate-600 dark:text-slate-300 mr-2"
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

                <div
                  class="bg-white dark:bg-slate-800 p-4 rounded-lg shadow-sm"
                >
                  <div class="flex items-center">
                    <UIcon
                      name="i-heroicons-gift"
                      class="w-5 h-5 text-slate-600 dark:text-slate-300 mr-2"
                    />
                    <h4 class="font-medium">Premium Packaging</h4>
                  </div>
                  <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                    All products are securely packed to ensure safe delivery
                  </p>
                </div>
              </div>
            </div>
          </template>
        </UTabs>
      </div>
    </section>

    <!-- Customer Reviews Section -->
    <section class="py-12">
      <div class="container mx-auto px-6">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Customer Reviews
        </h2>
        <p
          class="text-center text-slate-600 dark:text-slate-300 mb-12 max-w-2xl mx-auto"
        >
          Join thousands of satisfied customers who have experienced the
          difference
        </p>

        <!-- Reviews Summary -->
        <div
          class="max-w-4xl mx-auto mb-10 bg-white dark:bg-slate-800/80 rounded-xl shadow-md p-6"
        >
          <div class="flex flex-col md:flex-row gap-6 md:items-center">
            <div
              class="text-center md:border-r md:border-slate-200 dark:md:border-slate-700 md:pr-6"
            >
              <div
                class="text-5xl font-bold text-slate-800 dark:text-white mb-2"
              >
                {{ currentProduct?.rating || "4.9" }}
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
                Based on {{ currentProduct?.reviews?.length || "125" }} reviews
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
                  {{
                    getRatingCount(6 - n) ||
                    (6 - n === 5
                      ? "98"
                      : 6 - n === 4
                      ? "22"
                      : 6 - n === 3
                      ? "4"
                      : "1")
                  }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Featured Reviews -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="(review, index) in displayedReviews"
            :key="index"
            class="bg-white dark:bg-slate-800 rounded-xl shadow-md p-6 transition-transform hover:translate-y-[-5px]"
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
                  star <= review.rating ? 'text-amber-400' : 'text-gray-200'
                "
              />
            </div>
            <p class="text-slate-600 dark:text-slate-300 mb-4">
              "{{ review.comment }}"
            </p>
            <div class="flex items-center">
              <div
                class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-3 text-primary-700 dark:text-primary-300 font-medium"
              >
                {{ review.name?.charAt(0) || "U" }}
              </div>
              <div>
                <div class="font-medium text-slate-900 dark:text-white">
                  {{ review.name }}
                </div>
                <div class="text-xs text-slate-500 dark:text-slate-400">
                  {{ review.date || "Verified Purchase" }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Write a Review Section -->
        <div
          class="max-w-2xl mx-auto mt-12 bg-slate-50 dark:bg-slate-800/50 rounded-xl p-6"
        >
          <h3 class="text-xl font-semibold mb-4 text-center">
            Share Your Experience
          </h3>
          <div class="space-y-4">
            <div>
              <label
                class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
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
              <UInput v-model="reviewForm.name" placeholder="Enter your name" />
            </div>
            <div>
              <label
                class="block text-sm mb-1 text-slate-600 dark:text-slate-300"
              >
                Your Review
              </label>
              <UTextarea
                v-model="reviewForm.comment"
                placeholder="Share your experience with this product..."
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
    </section>

    <!-- Comparison Table Section -->
    <section
      class="py-12 bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800/80 rounded-xl"
    >
      <div class="container mx-auto px-6">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Why Choose Our Product?
        </h2>
        <p
          class="text-center text-slate-600 dark:text-slate-300 mb-12 max-w-2xl mx-auto"
        >
          See how our product compares to the competition
        </p>

        <div class="max-w-4xl mx-auto overflow-x-auto">
          <table class="w-full border-collapse">
            <thead>
              <tr>
                <th
                  class="py-4 px-6 bg-white dark:bg-slate-800 text-left sticky left-0 z-10"
                ></th>
                <th
                  class="py-4 px-6 bg-primary-100 dark:bg-primary-900/30 text-center relative"
                >
                  <div
                    class="absolute -top-3 left-1/2 transform -translate-x-1/2 bg-primary-500 text-white text-xs px-3 py-1 rounded-full"
                  >
                    BEST CHOICE
                  </div>
                  <span
                    class="text-primary-700 dark:text-primary-300 font-bold"
                    >{{ currentProduct.name }}</span
                  >
                </th>
                <th
                  class="py-4 px-6 bg-slate-100 dark:bg-slate-800/80 text-center"
                >
                  <span class="text-slate-500">Competitor A</span>
                </th>
                <th
                  class="py-4 px-6 bg-slate-100 dark:bg-slate-800/80 text-center"
                >
                  <span class="text-slate-500">Competitor B</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td
                  class="py-4 px-6 bg-white dark:bg-slate-800 font-medium sticky left-0 z-10"
                >
                  Quality
                </td>
                <td
                  class="py-4 px-6 bg-primary-50 dark:bg-primary-900/10 text-center"
                >
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-6 h-6 text-green-500 mx-auto"
                  />
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  <UIcon
                    name="i-heroicons-x-circle"
                    class="w-6 h-6 text-red-500 mx-auto"
                  />
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-6 h-6 text-green-500 mx-auto"
                  />
                </td>
              </tr>
              <tr>
                <td
                  class="py-4 px-6 bg-white dark:bg-slate-800 font-medium sticky left-0 z-10"
                >
                  Price
                </td>
                <td
                  class="py-4 px-6 bg-primary-50 dark:bg-primary-900/10 text-center font-bold"
                >
                  ৳{{
                    currentProduct.sale_price || currentProduct.regular_price
                  }}
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  ৳{{
                    (currentProduct.sale_price ||
                      currentProduct.regular_price) * 1.4
                  }}
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  ৳{{
                    (currentProduct.sale_price ||
                      currentProduct.regular_price) * 1.2
                  }}
                </td>
              </tr>
              <tr>
                <td
                  class="py-4 px-6 bg-white dark:bg-slate-800 font-medium sticky left-0 z-10"
                >
                  Warranty
                </td>
                <td
                  class="py-4 px-6 bg-primary-50 dark:bg-primary-900/10 text-center"
                >
                  1 Year
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  6 Months
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  None
                </td>
              </tr>
              <tr>
                <td
                  class="py-4 px-6 bg-white dark:bg-slate-800 font-medium sticky left-0 z-10"
                >
                  Delivery
                </td>
                <td
                  class="py-4 px-6 bg-primary-50 dark:bg-primary-900/10 text-center"
                >
                  2-3 Days
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  5-7 Days
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  3-5 Days
                </td>
              </tr>
              <tr>
                <td
                  class="py-4 px-6 bg-white dark:bg-slate-800 font-medium sticky left-0 z-10"
                >
                  Customer Support
                </td>
                <td
                  class="py-4 px-6 bg-primary-50 dark:bg-primary-900/10 text-center"
                >
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-6 h-6 text-green-500 mx-auto"
                  />
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  <UIcon
                    name="i-heroicons-x-circle"
                    class="w-6 h-6 text-red-500 mx-auto"
                  />
                </td>
                <td class="py-4 px-6 bg-white dark:bg-slate-800/60 text-center">
                  <UIcon
                    name="i-heroicons-x-circle"
                    class="w-6 h-6 text-red-500 mx-auto"
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-12">
      <div class="container mx-auto px-6">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-4">
          Frequently Asked Questions
        </h2>
        <p
          class="text-center text-slate-600 dark:text-slate-300 mb-12 max-w-2xl mx-auto"
        >
          Everything you need to know about our product
        </p>

        <div class="max-w-3xl mx-auto">
          <UAccordion :items="faqs" />
        </div>
      </div>
    </section>

    <!-- Final CTA Section -->
    <section
      class="py-12 bg-gradient-to-br from-primary-600 to-primary-800 text-white rounded-xl my-6"
    >
      <div class="container mx-auto px-6 text-center">
        <h2 class="text-3xl md:text-4xl font-bold mb-6">
          Ready to Experience the Difference?
        </h2>
        <p class="text-white/80 mb-8 max-w-2xl mx-auto text-lg">
          Join thousands of satisfied customers who have already transformed
          their experience with {{ currentProduct.name }}.
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
              <div class="text-2xl font-bold">
                ৳{{
                  currentProduct.regular_price ||
                  (currentProduct.sale_price || 0) * 1.5
                }}
              </div>
            </div>
            <div class="text-4xl font-bold">→</div>
            <div class="text-center">
              <div class="text-white/90 text-lg">Special Offer:</div>
              <div class="text-4xl font-bold">
                ৳{{ currentProduct.sale_price || currentProduct.regular_price }}
              </div>
            </div>
          </div>
        </div>

        <button
          @click="addToCart(currentProduct, 1)"
          class="px-10 py-4 bg-white hover:bg-slate-50 text-primary-700 text-xl font-bold rounded-xl shadow-2xl transition-all duration-300 animate-pulse hover:animate-none transform hover:scale-105"
        >
          Order Now & Save
          <span class="block text-sm font-normal mt-1"
            >30-Day Money Back Guarantee</span
          >
        </button>

        <!-- Trust Badges -->
        <div class="flex flex-wrap justify-center gap-6 mt-8">
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
          >
            <UIcon name="i-heroicons-credit-card" class="w-5 h-5" />
            <span class="text-sm">Secure Payment</span>
          </div>
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
          >
            <UIcon name="i-heroicons-shield-check" class="w-5 h-5" />
            <span class="text-sm">Money-Back Guarantee</span>
          </div>
          <div
            class="flex items-center gap-1.5 bg-white/10 px-4 py-2 rounded-full"
          >
            <UIcon name="i-heroicons-truck" class="w-5 h-5" />
            <span class="text-sm">Fast Delivery</span>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
const { currentProduct, modal } = defineProps({
  currentProduct: { type: Object, required: true },
  modal: { type: Boolean, required: false },
});

const emit = defineEmits(["close-modal"]);

function closeModal() {
  emit("close-modal");
}

const cart = useStoreCart();
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
  // Safety check in case prices are undefined
  if (!sale_price || !regular_price) return 0;

  // Handle both string and number inputs
  const current =
    typeof sale_price === "string"
      ? Number(sale_price.replace(/,/g, ""))
      : Number(sale_price);

  const regular =
    typeof regular_price === "string"
      ? Number(regular_price.replace(/,/g, ""))
      : Number(regular_price);

  // Calculate and format savings
  return (regular - current).toLocaleString();
}

// Add these to your existing script section
const activeTab = ref("features");
const reviewForm = ref({
  name: "",
  rating: 0,
  comment: "",
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
  if (!currentProduct || !currentProduct.reviews) return "0%";

  const total = currentProduct.reviews.length || 1;
  const count =
    currentProduct.reviews?.filter((r) => Math.round(r.rating) === rating)
      .length || 0;

  return `${(count / total) * 100}%`;
}

function getRatingCount(rating) {
  if (!currentProduct || !currentProduct.reviews) return 0;

  return (
    currentProduct.reviews?.filter((r) => Math.round(r.rating) === rating)
      .length || 0
  );
}

// Improved submit review function
function submitReview() {
  if (!isReviewValid.value) return;

  // Add review to product
  if (!currentProduct.reviews) {
    currentProduct.reviews = [];
  }

  currentProduct.reviews.unshift({
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

// Sample reviews when none exist
const displayedReviews = computed(() => {
  if (currentProduct?.reviews?.length > 0) {
    return currentProduct.reviews.slice(0, 6);
  }

  // Sample reviews when none exist
  return [
    {
      name: "Ahmed Khan",
      rating: 5,
      date: "2 weeks ago",
      comment:
        "This product exceeded my expectations! The quality is outstanding and it arrived quickly. Would definitely recommend to anyone looking for a premium solution.",
    },
    {
      name: "Priya Sharma",
      rating: 5,
      date: "1 month ago",
      comment:
        "I've tried many similar products but this one stands out. The attention to detail is impressive and the performance is consistently reliable.",
    },
    {
      name: "Mohammad Ali",
      rating: 4,
      date: "3 weeks ago",
      comment:
        "Great product overall. Shipping was fast and the quality is as advertised. Only giving 4 stars because the instructions could be clearer.",
    },
    {
      name: "Sarah Johnson",
      rating: 5,
      date: "2 months ago",
      comment:
        "Absolutely love this! It's made such a difference in my daily routine. The design is beautiful and functionality is perfect.",
    },
    {
      name: "Rahul Patel",
      rating: 5,
      date: "3 months ago",
      comment:
        "Best purchase I've made this year! The product is durable, well-designed and performs exactly as described. Customer service was also excellent.",
    },
    {
      name: "Lisa Wong",
      rating: 4,
      date: "1 month ago",
      comment:
        "Very satisfied with my purchase. The product is high quality and the delivery was quick. Would buy from this store again.",
    },
  ];
});

// FAQ items
const faqs = [
  {
    label: "How long is the warranty period?",
    content:
      "Our product comes with a full 1-year warranty that covers all manufacturing defects and normal wear and tear. We stand behind the quality of our products.",
    icon: "i-heroicons-shield-check",
  },
  {
    label: "What payment methods do you accept?",
    content:
      "We accept all major credit cards, mobile banking, bKash, Nagad, and bank transfers. All payments are processed securely.",
    icon: "i-heroicons-credit-card",
  },

  {
    label: "How long does delivery take?",
    content:
      "Delivery within Dhaka typically takes 2-3 business days. For locations outside Dhaka, please allow 3-5 business days for your order to arrive.",
    icon: "i-heroicons-truck",
  },
  {
    label: "Is this product suitable for commercial use?",
    content:
      "Yes, our product is designed for both personal and commercial use. The durable construction ensures it can withstand heavy usage in commercial settings.",
    icon: "i-heroicons-building-storefront",
  },
];
</script>

<style scoped>
.product-sales-funnel {
  max-width: 1200px;
  margin: 0 auto;
}

.benefit-card {
  @apply bg-white dark:bg-slate-800 p-6 rounded-xl shadow-md text-center;
}

.icon-container {
  @apply w-16 h-16 mx-auto bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mb-4;
}

.feature-item {
  @apply flex items-center gap-2 bg-white dark:bg-slate-800 p-3 rounded-lg shadow-sm;
}

.stars-background,
.stars-foreground {
  @apply flex;
}

.rating-stars {
  @apply relative inline-flex;
}

.stars-foreground {
  @apply absolute top-0 left-0 overflow-hidden;
}

/* Add some subtle animations */
@keyframes pulse-glow {
  0%,
  100% {
    box-shadow: 0 0 8px rgba(79, 70, 229, 0.6);
  }
  50% {
    box-shadow: 0 0 16px rgba(79, 70, 229, 0.8);
  }
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}
</style>
