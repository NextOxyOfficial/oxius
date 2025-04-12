<template>
  <UContainer>
    <div class="bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800/90 min-h-screen pb-16">
    <!-- Banner Slider -->
    <div class="relative overflow-hidden">
      <div class="relative h-96">
        <div
          v-for="(slide, index) in slides"
          :key="index"
          class="absolute inset-0 transition-opacity duration-1000 bg-cover bg-center flex items-center justify-center text-white"
          :class="{ 'opacity-100 z-10': currentSlide === index, 'opacity-0 z-0': currentSlide !== index }"
          :style="{ backgroundImage: `url(${slide.image})` }"
        >
          <div class="bg-emerald-700/70 p-6 rounded-lg">
            <h2 class="text-4xl font-bold">{{ slide.title }}</h2>
            <p class="mt-2 text-lg">{{ slide.description }}</p>
          </div>
        </div>
      </div>
      <!-- Slider Controls -->
      <button
        @click="prevSlide"
        class="absolute left-4 top-1/2 transform -translate-y-1/2 bg-emerald-500 text-white p-2 rounded-full hover:bg-emerald-600"
      >
        <UIcon name="i-heroicons-chevron-left" class="h-6 w-6" />
      </button>
      <button
        @click="nextSlide"
        class="absolute right-4 top-1/2 transform -translate-y-1/2 bg-emerald-500 text-white p-2 rounded-full hover:bg-emerald-600"
      >
        <UIcon name="i-heroicons-chevron-right" class="h-6 w-6" />
      </button>
      <!-- Slider Indicators -->
      <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
        <span
          v-for="(slide, index) in slides"
          :key="index"
          @click="goToSlide(index)"
          class="w-3 h-3 rounded-full cursor-pointer"
          :class="currentSlide === index ? 'bg-emerald-500' : 'bg-gray-300 dark:bg-gray-600'"
        ></span>
      </div>
    </div>

    <!-- Categories Section -->
    <UContainer>
      <div class="py-6">
        <h2 class="text-2xl font-bold text-gray-800 dark:text-white mb-4">Categories</h2>
        <div class="grid grid-cols-10 gap-4 overflow-x-auto">
          <div
            v-for="category in categories"
            :key="category.id"
            class="p-4 bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition cursor-pointer flex flex-col items-center"
            @click="selectCategory(category)"
          >
            <div
              class="w-16 h-16 flex items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-900 text-emerald-500 mb-2 shadow-md"
            >
              <UIcon :name="category.icon" class="w-8 h-8" />
            </div>
            <h3 class="text-sm font-medium text-gray-800 dark:text-white text-center">
              {{ category.name }}
            </h3>
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Search & Filter Section -->
    <UContainer>
      <div class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-4 shadow-sm mb-6">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-2 sm:gap-4">
          <!-- Search Bar -->
          <div class="relative md:col-span-2">
            <input
              v-model="searchTerm"
              type="text"
              class="block w-full pl-10 pr-3 py-2.5 bg-slate-50 dark:bg-slate-700/50 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-600 dark:text-slate-300 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500/20 transition duration-200"
              placeholder="Search products..."
            />
            <button
              v-if="searchTerm"
              @click="searchTerm = ''"
              class="absolute inset-y-0 right-0 pr-3 flex items-center"
            >
              <UIcon
                name="i-heroicons-x-mark"
                class="h-5 w-5 text-slate-400 hover:text-emerald-500 transition-colors"
              />
            </button>
          </div>

          <!-- Price Filter -->
          <div>
            <label class="block text-gray-700 dark:text-gray-300 mb-2">Price Range</label>
            <input
              type="range"
              v-model="priceRange"
              min="0"
              max="1000"
              step="10"
              class="w-full"
            />
            <div class="flex justify-between text-sm text-gray-500 dark:text-gray-400 mt-1">
              <span>${{ priceRange }}</span>
              <span>Max: $1000</span>
            </div>
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Product Grid Section -->
    <UContainer>
      <div class="py-6">
        <h2 class="text-2xl font-bold text-gray-800 dark:text-white mb-4">
          {{ selectedCategory ? selectedCategory.name : "All Products" }}
        </h2>
        <div
          :class="{
            'grid gap-4': true,
            'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5': viewMode === 'grid',
            'grid-cols-1': viewMode === 'list',
          }"
        >
          <div
            v-for="(product, index) in filteredProducts"
            :key="product.id"
            class="relative group"
            :style="{ animationDelay: `${index * 50}ms` }"
            :class="isNewlyLoaded(index) ? 'animate-fade-up' : ''"
          >
            <CommonProductCard :product="product" />
          </div>
        </div>
      </div>
    </UContainer>
  </div>
  </UContainer>

</template>

<script setup>
import { ref, computed, onMounted } from "vue";

// Initialize slides with default values
const slides = ref([
  { image: "/images/slide1.jpg", title: "Welcome to Adsy eShop", description: "Discover premium products." },
  { image: "/images/slide2.jpg", title: "Exclusive Deals", description: "Shop the best deals now." },
  { image: "/images/slide3.jpg", title: "New Arrivals", description: "Check out the latest products." },
]);

const currentSlide = ref(0);

const nextSlide = () => {
  if (slides.value.length > 0) {
    currentSlide.value = (currentSlide.value + 1) % slides.value.length;
  }
};

const prevSlide = () => {
  if (slides.value.length > 0) {
    currentSlide.value = (currentSlide.value - 1 + slides.value.length) % slides.value.length;
  }
};

const goToSlide = (index) => {
  if (slides.value.length > 0) {
    currentSlide.value = index;
  }
};

// Auto-slide every 5 seconds
onMounted(() => {
  setInterval(nextSlide, 5000);
});

// Categories
const categories = ref([
  { id: 1, name: "Electronics", icon: "i-heroicons-device-phone-mobile" },
  { id: 2, name: "Clothing", icon: "i-heroicons-shirt" },
  { id: 3, name: "Home", icon: "i-heroicons-home" },
  { id: 4, name: "Books", icon: "i-heroicons-book-open" },
  { id: 5, name: "Sports", icon: "i-heroicons-trophy" },
  { id: 6, name: "Beauty", icon: "i-heroicons-sparkles" },
  { id: 7, name: "Toys", icon: "i-heroicons-puzzle-piece" },
  { id: 8, name: "Automotive", icon: "i-heroicons-truck" },
  { id: 9, name: "Health", icon: "i-heroicons-heart" },
  { id: 10, name: "Gadgets", icon: "i-heroicons-cpu-chip" },
]);

const searchTerm = ref("");
const priceRange = ref(500); // Default price range
const selectedCategory = ref(null);
const displayedProducts = ref([
  // Example products
  { id: 1, name: "Product 1", price: 300 },
  { id: 2, name: "Product 2", price: 700 },
  { id: 3, name: "Product 3", price: 200 },
]);

const filteredProducts = computed(() => {
  return displayedProducts.value.filter(
    (product) =>
      product.price <= priceRange.value &&
      (!searchTerm.value || product.name.toLowerCase().includes(searchTerm.value.toLowerCase()))
  );
});

const isNewlyLoaded = (index) => {
  return index < 10; // Example logic for animation
};

const selectCategory = (category) => {
  selectedCategory.value = category;
};
</script>

<style>
/* Animation for newly loaded products */
@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-up {
  animation: fadeUp 0.5s ease-out forwards;
}
</style>