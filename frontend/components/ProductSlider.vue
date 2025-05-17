<template>
  <div class="relative product-slider-container my-8">
    <!-- Section Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-2">
        <div class="p-1.5 rounded bg-primary/10 text-primary">
          <UIcon :name="icon" class="w-5 h-5" />
        </div>
        <h2 class="text-xl font-semibold text-gray-700 dark:text-white">
          {{ title }}
        </h2>
        <UBadge color="primary" variant="subtle" class="ml-2">
          {{ products.length }} Products
        </UBadge>
      </div>

      <!-- Action Link -->
      <NuxtLink
        :to="viewAllLink"
        class="group inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-gradient-to-r hover:from-primary-50 hover:to-blue-50 dark:hover:from-primary-900/20 dark:hover:to-blue-900/20 hover:border-primary-200 dark:hover:border-primary-800/30 transition-all duration-300 shadow-sm hover:shadow text-sm font-medium text-slate-700 dark:text-slate-200"
      >
        <span>{{ viewAllLabel }}</span>
        <div
          class="relative overflow-hidden w-4 h-4 rounded-full bg-gradient-to-r from-primary-500 to-blue-500 flex items-center justify-center transform transition-transform group-hover:scale-110"
        >
          <UIcon name="i-heroicons-arrow-right" class="w-3 h-3 text-white" />
        </div>
      </NuxtLink>
    </div>

    <!-- Slider Container -->
    <div class="relative group">
      <!-- Shadow Indicators -->
      <div
        class="absolute left-0 top-0 bottom-0 w-12 bg-gradient-to-r from-white dark:from-slate-900 to-transparent z-10 pointer-events-none transition-opacity duration-300"
        :class="{
          'opacity-0': scrollPosition <= 0,
          'opacity-100': scrollPosition > 0,
        }"
      ></div>
      <div
        class="absolute right-0 top-0 bottom-0 w-12 bg-gradient-to-l from-white dark:from-slate-900 to-transparent z-10 pointer-events-none transition-opacity duration-300"
        :class="{
          'opacity-0': scrollPosition >= maxScroll,
          'opacity-100': scrollPosition < maxScroll,
        }"
      ></div>

      <!-- Slider Area -->
      <div
        ref="sliderContainer"
        class="overflow-x-auto scrollbar-hide scroll-smooth"
        @scroll="updateScrollPosition"
      >
        <div class="flex gap-4 pb-4 pt-1 px-1">
          <!-- Product Cards -->
          <div
            v-for="(product, index) in products"
            :key="product.id"
            class="product-card flex-shrink-0 w-[220px] transition-all duration-300"
            :style="{ '--delay': `${index * 50}ms` }"
          >
            <div
              class="bg-white dark:bg-slate-800 h-full rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 hover:border-primary-200 dark:hover:border-primary-700/50 shadow-sm hover:shadow-sm transition-all duration-300 flex flex-col"
            >
              <!-- Product Image Area -->
              <div class="aspect-square relative overflow-hidden group">
                <!-- Badges -->
                <div class="absolute top-2 left-2 z-10 flex flex-col gap-1">
                  <div
                    v-if="product.discount"
                    class="px-1.5 py-0.5 bg-red-500 text-white text-xs font-medium rounded-md"
                  >
                    -{{ product.discount }}%
                  </div>
                  <div
                    v-if="product.isBestSeller"
                    class="px-1.5 py-0.5 bg-amber-500 text-white text-xs font-medium rounded-md"
                  >
                    Best Seller
                  </div>
                </div>

                <div
                  v-if="product.stock <= 5 && product.stock > 0"
                  class="absolute top-2 right-2 z-10 px-1.5 py-0.5 bg-primary-500 text-white text-xs font-medium rounded-md"
                >
                  Only {{ product.stock }} left
                </div>

                <!-- Product Image -->
                <img
                  :src="product.image"
                  :alt="product.name"
                  class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                  @load="imageLoaded = true"
                />

                <!-- Quick View Overlay -->
                <div
                  class="absolute inset-0 bg-black/0 group-hover:bg-black/20 flex flex-col items-center justify-center gap-2 transition-all duration-300 opacity-0 group-hover:opacity-100"
                >
                  <button
                    class="w-32 py-1.5 bg-white/90 dark:bg-slate-800/90 text-sm font-medium text-gray-700 dark:text-white rounded-md shadow-sm transform transition-all hover:scale-105"
                    @click="openProductModal(product)"
                  >
                    <UIcon name="i-heroicons-eye" class="w-3.5 h-3.5 mr-1" />
                    Quick View
                  </button>

                  <button
                    class="w-32 py-1.5 bg-primary/90 text-sm font-medium text-white rounded-md shadow-sm transform transition-all hover:scale-105"
                    @click="addToCart(product)"
                  >
                    <UIcon
                      name="i-heroicons-shopping-cart"
                      class="w-3.5 h-3.5 mr-1"
                    />
                    Add to Cart
                  </button>
                </div>
              </div>

              <!-- Product Info -->
              <div class="p-3 flex flex-col flex-grow">
                <!-- Title -->
                <h3
                  class="font-medium text-gray-700 dark:text-white text-sm mb-1 line-clamp-2 flex-grow"
                >
                  {{ product.name }}
                </h3>

                <!-- Rating -->
                <div class="flex items-center gap-1 mb-2">
                  <div class="flex">
                    <UIcon
                      v-for="n in 5"
                      :key="n"
                      :name="
                        n <= Math.floor(product.rating)
                          ? 'i-heroicons-star-solid'
                          : 'i-heroicons-star'
                      "
                      class="w-3 h-3"
                      :class="
                        n <= Math.floor(product.rating)
                          ? 'text-yellow-400'
                          : 'text-gray-300'
                      "
                    />
                  </div>
                  <span class="text-xs text-slate-500 dark:text-slate-400"
                    >({{ product.reviews?.length || 0 }})</span
                  >
                </div>

                <!-- Price and Action -->
                <div class="flex items-center justify-between">
                  <div class="flex items-baseline gap-1">
                    <span class="font-semibold text-gray-700 dark:text-white"
                      >৳{{ product.price }}</span
                    >
                    <span
                      v-if="product.oldPrice"
                      class="text-xs text-slate-400 line-through"
                      >৳{{ product.oldPrice }}</span
                    >
                  </div>

                  <!-- Mobile Add to Cart -->
                  <button
                    class="p-1.5 rounded-full bg-primary-100 dark:bg-primary-900/30 text-primary dark:text-primary-400 hover:bg-primary-200 dark:hover:bg-primary-800/30 transition-colors"
                    @click.stop="addToCart(product)"
                  >
                    <UIcon
                      name="i-heroicons-shopping-cart"
                      class="w-3.5 h-3.5"
                    />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Navigation Buttons -->
    <button
      class="absolute top-1/2 -translate-y-1/2 -left-4 z-20 w-8 h-8 rounded-full bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 shadow-sm hover:shadow-sm flex items-center justify-center text-gray-500 dark:text-slate-300 hover:text-primary dark:hover:text-primary disabled:opacity-40 disabled:cursor-not-allowed transition-all duration-200"
      :disabled="scrollPosition <= 0"
      @click="scrollLeft"
    >
      <UIcon name="i-heroicons-chevron-left" class="w-5 h-5" />
    </button>

    <button
      class="absolute top-1/2 -translate-y-1/2 -right-4 z-20 w-8 h-8 rounded-full bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 shadow-sm hover:shadow-sm flex items-center justify-center text-gray-500 dark:text-slate-300 hover:text-primary dark:hover:text-primary disabled:opacity-40 disabled:cursor-not-allowed transition-all duration-200"
      :disabled="scrollPosition >= maxScroll"
      @click="scrollRight"
    >
      <UIcon name="i-heroicons-chevron-right" class="w-5 h-5" />
    </button>

    <!-- Product Modal -->
    <UModal
      v-model="isModalOpen"
      :ui="{ width: 'w-full max-w-4xl' }"
      @close="resetModal"
    >
      <UCard v-if="selectedProduct" class="p-0">
        <!-- Modal Header -->
        <template #header>
          <div
            class="relative bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 px-5 py-4 border-b border-slate-200 dark:border-slate-700"
          >
            <div class="flex justify-between items-center">
              <h3 class="text-xl font-medium text-gray-700 dark:text-white">
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
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Left: Product Image -->
            <div>
              <div
                class="relative pt-[100%] bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden"
              >
                <img
                  :src="selectedProduct.image"
                  :alt="selectedProduct.name"
                  class="absolute inset-0 w-full h-full object-contain"
                />

                <!-- Discount Badge -->
                <div
                  v-if="selectedProduct.discount"
                  class="absolute top-2 left-2 px-2 py-1 bg-red-500 text-white text-xs font-semibold rounded-md"
                >
                  -{{ selectedProduct.discount }}% OFF
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
                  class="text-xl font-medium text-gray-700 dark:text-white mb-2"
                >
                  {{ selectedProduct.name }}
                </h2>

                <!-- Rating -->
                <div class="flex items-center gap-2 mb-3">
                  <div class="flex">
                    <UIcon
                      v-for="n in 5"
                      :key="n"
                      :name="
                        n <= Math.floor(selectedProduct.rating)
                          ? 'i-heroicons-star-solid'
                          : 'i-heroicons-star'
                      "
                      class="w-4 h-4"
                      :class="
                        n <= Math.floor(selectedProduct.rating)
                          ? 'text-yellow-400'
                          : 'text-gray-300'
                      "
                    />
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
                    class="text-xl font-semibold text-gray-700 dark:text-white"
                  >
                    ৳{{ selectedProduct.price }}
                  </span>
                  <span
                    v-if="selectedProduct.oldPrice"
                    class="text-sm text-slate-400 line-through"
                  >
                    ৳{{ selectedProduct.oldPrice }}
                  </span>
                  <span
                    v-if="selectedProduct.discount"
                    class="px-2 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-sm font-medium rounded-full"
                  >
                    Save ৳{{
                      calculateSavings(
                        selectedProduct.price,
                        selectedProduct.oldPrice
                      )
                    }}
                  </span>
                </div>

                <!-- Description -->
                <p class="text-sm text-gray-500 dark:text-slate-300 mb-4">
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

                  <UButton
                    color="primary"
                    size="lg"
                    class="flex-1 relative overflow-hidden group"
                    @click="addSelectedToCart"
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

                      <!-- Button text -->
                      <span class="text-base">Add to Cart</span>
                    </div>
                  </UButton>
                </div>

                <!-- Product Meta -->
                <div class="text-sm">
                  <div class="flex items-center gap-2 mb-1.5">
                    <UIcon
                      name="i-heroicons-check-circle"
                      class="w-4 h-4 text-green-500"
                    />
                    <span class="text-gray-500 dark:text-slate-300">
                      {{
                        selectedProduct.stock > 0 ? "In stock" : "Out of stock"
                      }}
                      <span
                        v-if="
                          selectedProduct.stock <= 5 &&
                          selectedProduct.stock > 0
                        "
                        class="text-amber-600"
                      >
                        (Only {{ selectedProduct.stock }} left)
                      </span>
                    </span>
                  </div>
                  <div class="flex items-center gap-2">
                    <UIcon
                      name="i-heroicons-truck"
                      class="w-4 h-4 text-slate-400"
                    />
                    <span class="text-gray-500 dark:text-slate-300">
                      Free shipping on orders over ৳5,000
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Reviews Section -->
          <div class="mt-8">
            <UTabs
              :items="[
                { label: 'Reviews', icon: 'i-heroicons-chat-bubble-bottom' },
              ]"
            >
              <template #reviews>
                <div class="pt-4">
                  <h3
                    class="text-lg font-medium text-gray-700 dark:text-white mb-4"
                  >
                    Customer Reviews
                  </h3>
                  <div class="space-y-4">
                    <div
                      v-if="selectedProduct.reviews?.length"
                      class="max-h-60 overflow-y-auto pr-2"
                    >
                      <div
                        v-for="(review, i) in selectedProduct.reviews"
                        :key="i"
                        class="p-3 bg-white dark:bg-slate-800 rounded-lg shadow-sm mb-3"
                      >
                        <div class="flex justify-between mb-2">
                          <div class="flex items-center gap-2">
                            <div
                              class="w-8 h-8 bg-slate-200 dark:bg-slate-700 text-gray-500 dark:text-slate-300 rounded-full flex items-center justify-center"
                            >
                              <span class="font-medium text-sm">{{
                                review.name?.charAt(0)
                              }}</span>
                            </div>
                            <div>
                              <div
                                class="font-medium text-gray-700 dark:text-white"
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
                                  : 'text-gray-300'
                              "
                            />
                          </div>
                        </div>
                        <p class="text-sm text-gray-500 dark:text-slate-300">
                          {{ review.comment }}
                        </p>
                      </div>
                    </div>
                    <div
                      v-else
                      class="text-center py-8 text-slate-500 dark:text-slate-400"
                    >
                      No reviews yet. Be the first to review this product!
                    </div>
                  </div>
                </div>
              </template>
            </UTabs>
          </div>
        </div>
      </UCard>
    </UModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from "vue";

// Props
const props = defineProps({
  title: {
    type: String,
    default: "Featured Products",
  },
  icon: {
    type: String,
    default: "i-heroicons-fire",
  },
  products: {
    type: Array,
    required: true,
  },
  viewAllLink: {
    type: String,
    default: "/shop",
  },
  viewAllLabel: {
    type: String,
    default: "See All Products",
  },
});

// Emits
const emit = defineEmits(["add-to-cart"]);

// Refs for component state
const sliderContainer = ref(null);
const scrollPosition = ref(0);
const maxScroll = ref(0);
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);
const imageLoaded = ref(false);

// Update scroll position
function updateScrollPosition() {
  if (!sliderContainer.value) return;
  scrollPosition.value = sliderContainer.value.scrollLeft;
  maxScroll.value =
    sliderContainer.value.scrollWidth - sliderContainer.value.clientWidth;
}

// Scroll left by one product
function scrollLeft() {
  if (!sliderContainer.value) return;
  sliderContainer.value.scrollBy({
    left: -240, // approx width of product + gap
    behavior: "smooth",
  });
}

// Scroll right by one product
function scrollRight() {
  if (!sliderContainer.value) return;
  sliderContainer.value.scrollBy({
    left: 240, // approx width of product + gap
    behavior: "smooth",
  });
}

// Open product modal
function openProductModal(product) {
  selectedProduct.value = product;
  isModalOpen.value = true;
  quantity.value = 1;
}

// Reset modal state
function resetModal() {
  selectedProduct.value = null;
  quantity.value = 1;
}

// Add product to cart
function addToCart(product) {
  emit("add-to-cart", { product, quantity: 1 });
}

// Add selected product to cart with quantity
function addSelectedToCart() {
  if (selectedProduct.value) {
    emit("add-to-cart", {
      product: selectedProduct.value,
      quantity: quantity.value,
    });
    isModalOpen.value = false;
  }
}

// Calculate price savings
function calculateSavings(currentPrice, oldPrice) {
  const current = parseFloat(String(currentPrice).replace(/[^0-9.]/g, ""));
  const old = parseFloat(String(oldPrice).replace(/[^0-9.]/g, ""));
  return Math.floor(old - current).toLocaleString();
}

// Initialize component
onMounted(() => {
  updateScrollPosition();
  window.addEventListener("resize", updateScrollPosition);
});

// Clean up
onBeforeUnmount(() => {
  window.removeEventListener("resize", updateScrollPosition);
});

// Watch for product changes
watch(
  () => props.products.length,
  () => {
    setTimeout(updateScrollPosition, 100);
  }
);
</script>

<style scoped>
/* Hide scrollbar but allow scrolling */
.scrollbar-hide {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}
.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

/* Animate items on load with stagger */
.product-card {
  animation: fadeSlideIn 0.6s ease-out forwards;
  animation-delay: var(--delay);
  opacity: 0;
  transform: translateX(10px);
}

@keyframes fadeSlideIn {
  to {
    opacity: 1;
    transform: translateX(0);
  }
}
</style>
