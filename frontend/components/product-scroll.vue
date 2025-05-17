<template>
  <div class="relative product-slider-container my-8">
    <!-- Section Header -->
    <div class="flex items-center justify-between mb-6 px-3.5">
      <div class="flex items-center gap-2">
        <div
          class="p-1.5 rounded bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
        >
          <UIcon :name="icon" class="w-5 h-5" />
        </div>
        <h2 class="text-xl font-semibold text-gray-700 dark:text-white">
          {{ title }}
        </h2>
        <UBadge color="emerald" variant="subtle" class="ml-2">
          {{ products.length }} Products
        </UBadge>
      </div>

      <!-- See All Products Button -->
      <NuxtLink
        :to="viewAllLink"
        class="group inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-gradient-to-r hover:from-emerald-50 hover:to-blue-50 dark:hover:from-emerald-900/20 dark:hover:to-blue-900/20 hover:border-emerald-200 dark:hover:border-emerald-800/30 transition-all duration-300 shadow-sm hover:shadow text-sm font-medium text-slate-700 dark:text-slate-200"
      >
        <span>See All Products</span>
        <div
          class="relative overflow-hidden w-4 h-4 rounded-full bg-gradient-to-r from-emerald-500 to-blue-500 flex items-center justify-center transform transition-transform group-hover:scale-110"
        >
          <UIcon name="i-heroicons-arrow-right" class="w-3 h-3 text-white" />
        </div>
      </NuxtLink>
    </div>

    <!-- Slider Container with Shadow Indicators -->
    <div class="relative">
      <!-- Left Shadow Gradient (shows when scrollable left) -->
      <div
        class="absolute left-0 top-0 bottom-0 w-12 bg-gradient-to-r from-white dark:from-slate-900 to-transparent z-10 pointer-events-none transition-opacity duration-300"
        :class="{
          'opacity-0': scrollPosition <= 0,
          'opacity-100': scrollPosition > 0,
        }"
      ></div>

      <!-- Right Shadow Gradient (shows when scrollable right) -->
      <div
        class="absolute right-0 top-0 bottom-0 w-12 bg-gradient-to-l from-white dark:from-slate-900 to-transparent z-10 pointer-events-none transition-opacity duration-300"
        :class="{
          'opacity-0': scrollPosition >= maxScroll,
          'opacity-100': scrollPosition < maxScroll,
        }"
      ></div>

      <!-- Actual Slider -->
      <div
        ref="sliderContainer"
        class="overflow-x-auto scrollbar-hide scroll-smooth"
        @scroll="updateScrollPosition"
      >
        <div class="flex gap-4 pb-4 pt-1 px-1">
          <div
            v-for="(product, index) in products"
            :key="product.id"
            class="product-card flex-shrink-0 w-[220px] transition-all duration-300 transform"
            :style="{
              '--delay': `${index * 50}ms`,
            }"
          >
            <div
              class="bg-white dark:bg-slate-800 h-full rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 hover:border-emerald-200 dark:hover:border-emerald-700/50 shadow-sm hover:shadow-sm transition-all duration-300 flex flex-col"
            >
              <!-- Product Image -->
              <div class="aspect-square relative overflow-hidden group">
                <!-- Product Badges -->
                <div class="absolute top-2 left-2 z-10">
                  <div
                    v-if="product.discount"
                    class="px-1.5 py-0.5 bg-red-500 text-white text-xs font-medium rounded-sm"
                  >
                    -{{ product.discount }}%
                  </div>
                </div>

                <img
                  :src="product.image"
                  :alt="product.name"
                  class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                />

                <!-- Quick View Overlay -->
                <div
                  class="absolute inset-0 bg-black/0 group-hover:bg-black/20 flex items-center justify-center transition-all duration-300 opacity-0 group-hover:opacity-100"
                >
                  <button
                    class="px-2 py-1 bg-white/90 dark:bg-slate-800/90 text-xs font-medium text-gray-700 dark:text-white rounded-md shadow-sm transform transition-all hover:scale-105"
                    @click="$emit('view-product', product)"
                  >
                    Quick View
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

                <!-- Price -->
                <div class="flex items-center justify-between">
                  <div class="flex items-baseline gap-1.5">
                    <span class="font-semibold text-gray-700 dark:text-white"
                      >৳{{ product.price }}</span
                    >
                    <span
                      v-if="product.oldPrice"
                      class="text-xs text-slate-400 line-through"
                      >৳{{ product.oldPrice }}</span
                    >
                  </div>

                  <!-- Add to Cart -->
                  <button
                    class="p-1.5 rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-200 dark:hover:bg-emerald-800/30 transition-colors"
                    @click="$emit('add-to-cart', product)"
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
      class="absolute top-1/2 -translate-y-1/2 -left-4 z-20 w-8 h-8 rounded-full bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 shadow-sm hover:shadow-sm flex items-center justify-center text-gray-500 dark:text-slate-300 hover:text-gray-700 dark:hover:text-white disabled:opacity-40 disabled:cursor-not-allowed transition-all duration-200"
      :disabled="scrollPosition <= 0"
      @click="scrollLeft"
    >
      <UIcon name="i-heroicons-chevron-left" class="w-5 h-5" />
    </button>

    <button
      class="absolute top-1/2 -translate-y-1/2 -right-4 z-20 w-8 h-8 rounded-full bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 shadow-sm hover:shadow-sm flex items-center justify-center text-gray-500 dark:text-slate-300 hover:text-gray-700 dark:hover:text-white disabled:opacity-40 disabled:cursor-not-allowed transition-all duration-200"
      :disabled="scrollPosition >= maxScroll"
      @click="scrollRight"
    >
      <UIcon name="i-heroicons-chevron-right" class="w-5 h-5" />
    </button>
  </div>
</template>

<script setup>
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
});

// Emits
const emit = defineEmits(["view-product", "add-to-cart"]);

// Scroll handling
const sliderContainer = ref(null);
const scrollPosition = ref(0);
const maxScroll = ref(0);

// Update scroll position
function updateScrollPosition() {
  if (!sliderContainer.value) return;

  scrollPosition.value = sliderContainer.value.scrollLeft;
  maxScroll.value =
    sliderContainer.value.scrollWidth - sliderContainer.value.clientWidth;
}

// Scroll left by one item
function scrollLeft() {
  if (!sliderContainer.value) return;
  sliderContainer.value.scrollBy({
    left: -240, // approx width of item + gap
    behavior: "smooth",
  });
}

// Scroll right by one item
function scrollRight() {
  if (!sliderContainer.value) return;
  sliderContainer.value.scrollBy({
    left: 240, // approx width of item + gap
    behavior: "smooth",
  });
}

// Calculate max scroll width on mount and product changes
onMounted(() => {
  updateScrollPosition();

  // Recalculate on window resize
  window.addEventListener("resize", updateScrollPosition);

  // Clean up event listener
  onBeforeUnmount(() => {
    window.removeEventListener("resize", updateScrollPosition);
  });
});

// Update max scroll when products change
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
  transform: translateX(20px);
}

@keyframes fadeSlideIn {
  to {
    opacity: 1;
    transform: translateX(0);
  }
}
</style>
