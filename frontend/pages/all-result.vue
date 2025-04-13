<template>
  <div class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90">
    <!-- Banner Slider Section -->
    <div class="relative overflow-hidden mt-4 mb-8">
      <UContainer class="!px-0">
        <div class="carousel-container rounded-md overflow-hidden shadow-md relative">
          <div
            class="carousel-slides flex transition-transform duration-700 ease-in-out"
            :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
          >
            <div
              v-for="(slide, index) in bannerSlides"
              :key="index"
              class="w-full flex-shrink-0 relative"
            >
              <div class="relative h-64 sm:h-72 md:h-80">
                <img
                  :src="slide.image"
                  :alt="slide.title"
                  class="w-full h-full object-cover"
                />
                <div
                  class="absolute inset-0 bg-gradient-to-r from-black/70 via-black/40 to-transparent flex items-center"
                >
                  <div class="px-6 sm:px-10 max-w-2xl">
                    <div class="w-12 h-1 bg-emerald-400 mb-4 rounded-full"></div>
                    <h2 class="text-2xl sm:text-3xl font-bold text-white mb-2">
                      {{ slide.title }}
                    </h2>
                    <p class="text-white/80 text-sm sm:text-base mb-4">
                      {{ slide.description }}
                    </p>
                    <UButton
                      color="emerald"
                      :to="slide.link"
                      class="text-white font-medium"
                    >
                      {{ slide.buttonText }}
                    </UButton>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </UContainer>
    </div>

    <!-- Slider Categories for Mobile -->
    <div class="block lg:hidden mb-6">
      <UContainer>
        <div class="grid grid-cols-2 gap-4">
          <div
            v-for="category in categoriesWithCounts"
            :key="category.value"
            @click="selectCategory(category.value)"
            class="flex flex-col items-center justify-center p-4 bg-white dark:bg-gray-800 rounded-lg shadow-md border border-dashed border-gray-300 dark:border-gray-700 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 transition"
          >
            <img
              :src="category.image"
              :alt="category.label"
              class="w-12 h-12 object-cover rounded-full mb-2"
            />
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ category.label }}
            </span>
            <span
              class="mt-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded-full px-2 py-0.5"
            >
              {{ category.count }}
            </span>
          </div>
        </div>
      </UContainer>
    </div>

    <UContainer>
      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Categories Sidebar (Hidden on Mobile) -->
        <div class="hidden lg:block w-full lg:w-64 flex-shrink-0">
          <div
            class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-4 sticky top-24"
          >
            <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4">
              Categories
            </h3>
            <div class="space-y-2">
              <button
                v-for="category in categoriesWithCounts"
                :key="category.value"
                @click="selectCategory(category.value)"
                class="w-full text-left px-4 py-2 rounded-lg transition-colors flex items-center"
                :class="{
                  'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-300':
                    selectedCategory === category.value,
                  'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700':
                    selectedCategory !== category.value,
                }"
              >
                <img
                  :src="category.image"
                  :alt="category.label"
                  class="w-6 h-6 object-cover rounded-full mr-2"
                />
                {{ category.label }}
                <span
                  class="ml-auto bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 text-xs rounded-full px-2 py-0.5"
                >
                  {{ category.count }}
                </span>
              </button>
            </div>
          </div>
        </div>

        <!-- Posts Section -->
        <div class="flex-1">
          <div
            class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6"
          >
            <div
              v-for="post in filteredPosts"
              :key="post.id"
              class="bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300"
            >
              <img
                :src="post.image"
                :alt="post.title"
                class="w-full h-40 object-cover"
              />
              <div class="p-4">
                <h3
                  class="text-lg font-semibold text-gray-800 dark:text-white mb-2 line-clamp-2"
                >
                  {{ post.title }}
                </h3>
                <p
                  class="text-sm text-gray-600 dark:text-gray-400 mb-2 line-clamp-3"
                >
                  {{ post.description }}
                </p>
                <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
                  Contact: {{ post.contactNumber || "N/A" }}
                </p>
                <div class="flex items-center justify-between text-sm">
                  <span class="text-gray-500 dark:text-gray-400">
                    Posted by {{ post.user.firstName }} •
                    {{ timeAgo(post.createdAt) }}
                  </span>
                  <span class="text-emerald-500 font-bold">
                    ${{ post.price }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";
import { formatDistanceToNow } from "date-fns";

// Categories and Posts
const categories = ref([]);
const posts = ref([]);

// Fetch categories and posts dynamically
const loadData = async () => {
  categories.value = await fetchCategories();
  posts.value = await fetchPosts();
};
loadData();

// Filters
const selectedCategory = ref(null);

// Computed filtered posts
const filteredPosts = computed(() => {
  return posts.value.filter(
    (post) =>
      (!selectedCategory.value || post.category === selectedCategory.value)
  );
});

// Time ago function
const timeAgo = (date) => {
  return formatDistanceToNow(new Date(date), { addSuffix: true });
};
</script>

<style>
/* Truncate text after 3 lines */
.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
