<template>
  <div class="min-h-screen bg-slate-50 dark:bg-slate-900">
    <!-- Banner Slider Section with UContainer -->
    <UContainer class="py-4">
      <div
        class="relative overflow-hidden banner-section mb-6 rounded-xl shadow-lg"
      >
        <div class="banner-slider relative">
          <!-- Slides Container -->
          <div
            class="flex transition-transform duration-500 ease-out"
            :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
          >
            <div
              v-for="(slide, index) in bannerSlides"
              :key="index"
              class="w-full flex-shrink-0 relative"
            >
              <div class="relative w-full h-52 sm:h-64 md:h-80 overflow-hidden">
                <!-- Banner Image -->
                <img
                  :src="slide.image"
                  :alt="slide.title"
                  class="absolute inset-0 w-full h-full object-cover transform scale-105 transition-transform duration-10000"
                  :class="{ 'animate-ken-burns': currentSlide === index }"
                />

                <!-- Gradient Overlay -->
                <div
                  class="absolute inset-0 bg-gradient-to-r from-slate-900/80 to-transparent"
                ></div>

                <!-- Content -->
                <div class="absolute inset-0 flex items-center">
                  <div class="container mx-auto px-2 md:px-8">
                    <div
                      class="max-w-md mx-auto md:mx-0 slide-content"
                      :class="{ active: currentSlide === index }"
                    >
                      <h2
                        class="text-white text-2xl md:text-3xl font-bold mb-2 transform translate-y-8 opacity-0 transition-all duration-500 delay-100"
                      >
                        {{ slide.title }}
                      </h2>
                      <p
                        class="text-white/80 mb-4 max-w-md transform translate-y-8 opacity-0 transition-all duration-500 delay-200"
                      >
                        {{ slide.description }}
                      </p>
                      <UButton
                        color="emerald"
                        :to="slide.link"
                        class="transform translate-y-8 opacity-0 transition-all duration-500 delay-300 shadow-lg"
                      >
                        {{ slide.buttonText }}
                        <template #trailing>
                          <UIcon name="i-heroicons-arrow-right" />
                        </template>
                      </UButton>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Banner Controls -->
          <div
            class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2 z-10"
          >
            <button
              v-for="(_, index) in bannerSlides"
              :key="index"
              @click="goToSlide(index)"
              class="w-2.5 h-2.5 rounded-full transition-all duration-300"
              :class="
                currentSlide === index
                  ? 'bg-emerald-500 w-6'
                  : 'bg-white/50 hover:bg-white/70'
              "
            ></button>
          </div>

          <!-- Navigation Arrows -->
          <button
            @click="prevSlide"
            class="absolute left-2 top-1/2 transform -translate-y-1/2 bg-black/20 hover:bg-emerald-500 text-white p-2 rounded-full backdrop-blur-sm transition-all duration-300"
          >
            <UIcon name="i-heroicons-chevron-left" class="w-5 h-5" />
          </button>
          <button
            @click="nextSlide"
            class="absolute right-2 top-1/2 transform -translate-y-1/2 bg-black/20 hover:bg-emerald-500 text-white p-2 rounded-full backdrop-blur-sm transition-all duration-300"
          >
            <UIcon name="i-heroicons-chevron-right" class="w-5 h-5" />
          </button>
        </div>
      </div>
    </UContainer>

    <UContainer>
      <!-- Search Bar -->
      <div class="mb-6 sm:mb-8">
        <div class="relative max-w-2xl mx-auto">
          <div class="relative">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search for posts..."
              class="w-full py-3 px-5 pl-12 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-sm focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all duration-300"
              @input="debouncedSearch"
              @keyup.enter="search"
            />
            <UIcon
              name="i-heroicons-magnifying-glass"
              class="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5"
            />
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="absolute right-4 top-1/2 transform -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
            >
              <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      <!-- Mobile Categories (single row with horizontal scrolling) -->
      <div class="lg:hidden mb-4">
        <h3
          class="text-sm font-medium text-slate-500 dark:text-slate-400 mb-3 px-1"
        >
          Categories
        </h3>

        <!-- Single row of categories with horizontal scrolling -->
        <div class="overflow-x-auto hide-scrollbar relative">
          <div class="flex space-x-2 py-1 snap-x">
            <!-- All Categories button -->
            <button
              @click="clearCategoryFilter"
              class="flex-shrink-0 w-[24%] max-w-[24%] snap-start bg-white dark:bg-slate-800/80 p-2 rounded-lg border border-dashed transition-all duration-300 hover:bg-emerald-50 dark:hover:bg-emerald-900/20"
              :class="{
                'border-emerald-200 dark:border-emerald-800/30 bg-emerald-50 dark:bg-emerald-900/20':
                  selectedCategory === null,
                'border-slate-200 dark:border-slate-700':
                  selectedCategory !== null,
              }"
            >
              <div class="flex flex-col items-center text-center">
                <div
                  class="w-10 h-10 rounded-lg border border-dashed border-slate-200 dark:border-slate-700 overflow-hidden mb-2 flex items-center justify-center"
                >
                  <UIcon
                    name="i-heroicons-squares-2x2"
                    class="w-5 h-5 text-emerald-500"
                  />
                </div>
                <div
                  class="font-medium text-slate-800 dark:text-white text-xs truncate w-full"
                >
                  All
                </div>
                <div class="text-xs text-slate-500 dark:text-slate-400">
                  {{ getTotalPostsCount() }}
                </div>
              </div>
            </button>

            <!-- All categories in a single row -->
            <button
              v-for="category in categories"
              :key="category.id"
              @click="filterByCategory(category.id)"
              class="flex-shrink-0 w-[24%] max-w-[24%] snap-start bg-white dark:bg-slate-800/80 p-2 rounded-lg border border-dashed transition-all duration-300 hover:bg-emerald-50 dark:hover:bg-emerald-900/20"
              :class="{
                'border-emerald-200 dark:border-emerald-800/30 bg-emerald-50 dark:bg-emerald-900/20':
                  selectedCategory === category.id,
                'border-slate-200 dark:border-slate-700':
                  selectedCategory !== category.id,
              }"
            >
              <div class="flex flex-col items-center text-center">
                <div
                  class="w-10 h-10 rounded-lg border border-dashed border-slate-200 dark:border-slate-700 overflow-hidden mb-2"
                >
                  <img
                    :src="category.image || '/images/category-placeholder.jpg'"
                    :alt="category.title"
                    class="w-full h-full object-cover"
                  />
                </div>
                <div
                  class="font-medium text-slate-800 dark:text-white text-xs truncate w-full"
                >
                  {{ category.title }}
                </div>
                <div class="text-xs text-slate-500 dark:text-slate-400">
                  {{ getCategoryCount(category.id) }}
                </div>
              </div>
            </button>
          </div>
        </div>
      </div>

      <div class="flex flex-col lg:flex-row gap-6">
        <!-- Desktop Categories Sidebar -->
        <div class="hidden lg:block w-64 flex-shrink-0">
          <div
            class="bg-white dark:bg-slate-800 rounded-xl p-4 shadow-sm border border-slate-200 dark:border-slate-700 sticky top-24"
          >
            <div class="flex items-center mb-5">
              <div class="h-5 w-1 bg-emerald-500 rounded-full mr-2"></div>
              <h3 class="font-semibold text-slate-900 dark:text-white">
                Categories
              </h3>
            </div>

            <div
              class="space-y-1.5 max-h-[calc(100vh-200px)] overflow-y-auto pr-2 scrollbar-thin"
            >
              <button
                @click="clearCategoryFilter"
                class="w-full text-left py-2 px-3 rounded-lg transition-all duration-200 flex items-center justify-between"
                :class="
                  selectedCategory === null
                    ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-medium'
                    : 'hover:bg-slate-100 dark:hover:bg-slate-700/50 text-slate-700 dark:text-slate-300'
                "
              >
                <div class="flex items-center">
                  <UIcon name="i-heroicons-squares-2x2" class="w-5 h-5 mr-3" />
                  All Categories
                </div>
                <span
                  class="text-xs px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400"
                >
                  {{ getTotalPostsCount() }}
                </span>
              </button>

              <button
                v-for="category in categories"
                :key="category.id"
                @click="filterByCategory(category.id)"
                class="w-full text-left py-2 px-3 rounded-lg transition-all duration-200 flex items-center justify-between group"
                :class="
                  selectedCategory === category.id
                    ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-medium'
                    : 'hover:bg-slate-100 dark:hover:bg-slate-700/50 text-slate-700 dark:text-slate-300'
                "
              >
                <div class="flex items-center">
                  <div class="w-5 h-5 mr-3 flex items-center justify-center">
                    <img
                      :src="
                        category.image || '/images/category-placeholder.jpg'
                      "
                      :alt="category.title"
                      class="w-full h-full object-cover rounded transform transition-transform duration-300 group-hover:scale-110"
                    />
                  </div>
                  {{ category.title }}
                </div>
                <span
                  class="text-xs px-2 py-0.5 rounded-full"
                  :class="
                    selectedCategory === category.id
                      ? 'bg-emerald-100 dark:bg-emerald-800/50 text-emerald-700 dark:text-emerald-400'
                      : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400'
                  "
                >
                  {{ getCategoryCount(category.id) }}
                </span>
              </button>
            </div>

            <!-- Simplified Sort options -->
            <div
              class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700"
            >
              <h3
                class="text-sm font-medium text-slate-600 dark:text-slate-400 mb-4 flex items-center"
              >
                <UIcon
                  name="i-heroicons-arrow-up-down"
                  class="w-4 h-4 mr-2 text-emerald-500"
                />
                Sort by
              </h3>

              <div class="flex flex-col gap-2.5">
                <button
                  @click="
                    sortBy = 'newest';
                    sortPosts();
                  "
                  class="flex items-center justify-between p-3 rounded-lg transition-all duration-200"
                  :class="
                    sortBy === 'newest'
                      ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400'
                      : 'hover:bg-slate-100 dark:hover:bg-slate-700/50 text-slate-700 dark:text-slate-300'
                  "
                >
                  <div class="flex items-center">
                    <UIcon
                      name="i-heroicons-clock"
                      class="w-4 h-4 mr-2.5"
                      :class="sortBy === 'newest' ? 'text-emerald-500' : ''"
                    />
                    <span>Newest First</span>
                  </div>
                  <div v-if="sortBy === 'newest'" class="flex-shrink-0">
                    <UIcon
                      name="i-heroicons-check"
                      class="w-5 h-5 text-emerald-500"
                    />
                  </div>
                </button>

                <button
                  @click="
                    sortBy = 'oldest';
                    sortPosts();
                  "
                  class="flex items-center justify-between p-3 rounded-lg transition-all duration-200"
                  :class="
                    sortBy === 'oldest'
                      ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400'
                      : 'hover:bg-slate-100 dark:hover:bg-slate-700/50 text-slate-700 dark:text-slate-300'
                  "
                >
                  <div class="flex items-center">
                    <UIcon
                      name="i-heroicons-clock-rewind"
                      class="w-4 h-4 mr-2.5"
                      :class="sortBy === 'oldest' ? 'text-emerald-500' : ''"
                    />
                    <span>Oldest First</span>
                  </div>
                  <div v-if="sortBy === 'oldest'" class="flex-shrink-0">
                    <UIcon
                      name="i-heroicons-check"
                      class="w-5 h-5 text-emerald-500"
                    />
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Main Content - Posts -->
        <div class="flex-1">
          <!-- Status Bar -->
          <div
            class="mb-6 flex items-center justify-between bg-white dark:bg-slate-800 rounded-xl p-3 shadow-sm border border-slate-200 dark:border-slate-700"
          >
            <div class="flex items-center">
              <UIcon
                name="i-heroicons-document-text"
                class="w-5 h-5 text-emerald-500 mr-2"
              />
              <h2 class="font-medium text-slate-800 dark:text-white">
                {{ filteredPosts.length }}
                {{ filteredPosts.length === 1 ? "Post" : "Posts" }}
              </h2>

              <div
                v-if="selectedCategory !== null"
                class="ml-3 flex items-center"
              >
                <div
                  class="w-1 h-1 rounded-full bg-slate-300 dark:bg-slate-600 mx-2"
                ></div>
                <UBadge
                  color="emerald"
                  variant="soft"
                  class="flex items-center"
                >
                  {{ getCategoryName(selectedCategory) }}
                  <button
                    @click="clearCategoryFilter"
                    class="ml-1 text-emerald-600 dark:text-emerald-400 hover:text-emerald-800 dark:hover:text-emerald-300"
                  >
                    <UIcon name="i-heroicons-x-mark" class="w-3.5 h-3.5" />
                  </button>
                </UBadge>
              </div>
            </div>

            <!-- Mobile Sort -->
            <div class="lg:hidden">
              <UButton
                color="gray"
                variant="ghost"
                icon="i-heroicons-adjustments-horizontal"
                @click="showMobileFilters = !showMobileFilters"
              >
                Sort
              </UButton>
            </div>
          </div>

          <!-- Mobile Sort Options (Modal) -->
          <UModal v-model="showMobileFilters" class="p-4">
            <div class="bg-white dark:bg-slate-800 rounded-xl p-5">
              <h3
                class="text-lg font-semibold text-slate-900 dark:text-white mb-4"
              >
                Sort Options
              </h3>
              <URadioGroup
                v-model="sortBy"
                :options="sortOptions"
                @update:modelValue="sortPosts"
              />
              <div class="mt-6 flex justify-end">
                <UButton @click="showMobileFilters = false" color="emerald"
                  >Apply</UButton
                >
              </div>
            </div>
          </UModal>

          <!-- Loading State -->
          <div
            v-if="isLoading"
            class="flex flex-col items-center justify-center py-32"
          >
            <div class="w-16 h-16 relative">
              <div
                class="absolute inset-0 rounded-full border-4 border-slate-200 dark:border-slate-700"
              ></div>
              <div
                class="absolute inset-0 rounded-full border-4 border-t-emerald-500 animate-spin"
              ></div>
            </div>
            <p class="mt-6 text-slate-500 dark:text-slate-400">
              Loading amazing posts...
            </p>
          </div>

          <!-- No Results State -->
          <div
            v-else-if="filteredPosts.length === 0"
            class="flex flex-col items-center justify-center py-32"
          >
            <div
              class="w-20 h-20 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mb-6"
            >
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="w-10 h-10 text-slate-400"
              />
            </div>
            <h3
              class="text-xl font-semibold text-slate-900 dark:text-white mb-2"
            >
              No posts found
            </h3>
            <p
              class="text-slate-500 dark:text-slate-400 mb-6 text-center max-w-md"
            >
              We couldn't find any posts matching your criteria. Try adjusting
              your filters or search terms.
            </p>
            <UButton color="emerald" @click="resetFilters">
              Reset Filters
            </UButton>
          </div>

          <!-- Posts Grid -->
          <div v-else>
            <!-- Desktop Grid (4 columns) -->
            <div class="hidden lg:grid lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <NuxtLink
                v-for="post in filteredPosts"
                :key="post.id"
                :to="`/post/${post.id}`"
                class="post-card group bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-sm hover:shadow-lg transition-all duration-300 border border-slate-200 dark:border-slate-700 relative"
              >
                <!-- Premium Badge (if post is premium) -->
                <div v-if="post.is_premium" class="absolute top-3 right-3 z-10">
                  <div
                    class="bg-gradient-to-r from-amber-500 to-yellow-500 text-white text-xs px-2 py-1 rounded-full shadow-lg flex items-center"
                  >
                    <UIcon name="i-heroicons-star" class="w-3 h-3 mr-1" />
                    Premium
                  </div>
                </div>

                <!-- Post Thumbnail -->
                <div class="aspect-[4/3] relative overflow-hidden">
                  <img
                    :src="post.thumbnail || '/images/placeholder.jpg'"
                    :alt="post.title"
                    class="w-full h-full object-cover transform transition-transform duration-700 ease-out"
                    :class="{ 'group-hover:scale-105': true }"
                  />

                  <!-- Category Badge -->
                  <div class="absolute bottom-3 left-3">
                    <UBadge
                      color="white"
                      class="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm text-slate-800 dark:text-white shadow-md"
                    >
                      {{
                        getCategoryName(post.category_id || post.category?.id)
                      }}
                    </UBadge>
                  </div>
                </div>

                <div class="p-4">
                  <!-- Post Title -->
                  <h3
                    class="font-medium text-slate-900 dark:text-white text-base mb-1 line-clamp-2 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors duration-300"
                  >
                    {{ post.title }}
                  </h3>

                  <!-- Post Description -->
                  <p
                    class="text-slate-600 dark:text-slate-400 text-sm line-clamp-2 mb-3"
                  >
                    {{ post.description || "No description available" }}
                  </p>

                  <!-- Post Footer -->
                  <div
                    class="flex items-center justify-between text-xs text-slate-500 dark:text-slate-500 border-t border-slate-100 dark:border-slate-700 pt-3"
                  >
                    <!-- Author Info -->
                    <div class="flex items-center">
                      <UAvatar
                        :src="
                          post.user?.image ||
                          post.user?.avatar ||
                          '/images/avatar-placeholder.jpg'
                        "
                        :alt="getUserName(post)"
                        size="xs"
                        class="mr-2"
                      />
                      <span class="truncate max-w-[80px]">
                        {{ getUserName(post) }}
                      </span>
                    </div>

                    <!-- Date -->
                    <div class="flex items-center">
                      <UIcon name="i-heroicons-clock" class="w-3 h-3 mr-1" />
                      {{ formatDate(post.created_at) }}
                    </div>
                  </div>
                </div>
              </NuxtLink>
            </div>

            <!-- Mobile Post Cards (1 column) -->
            <div class="lg:hidden space-y-6">
              <NuxtLink
                v-for="post in filteredPosts"
                :key="post.id"
                :to="`/post/${post.id}`"
                class="block"
              >
                <div
                  class="bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 border border-slate-200 dark:border-slate-700 flex flex-col sm:flex-row h-full relative"
                >
                  <!-- Premium Badge -->
                  <div
                    v-if="post.is_premium"
                    class="absolute top-3 right-3 z-10"
                  >
                    <div
                      class="bg-gradient-to-r from-amber-500 to-yellow-500 text-white text-xs px-2 py-1 rounded-full shadow-lg flex items-center"
                    >
                      <UIcon name="i-heroicons-star" class="w-3 h-3 mr-1" />
                      Premium
                    </div>
                  </div>

                  <!-- Post Thumbnail -->
                  <div
                    class="sm:w-1/3 aspect-video sm:aspect-square relative overflow-hidden"
                  >
                    <img
                      :src="post.thumbnail || '/images/placeholder.jpg'"
                      :alt="post.title"
                      class="w-full h-full object-cover"
                    />

                    <!-- Category Badge -->
                    <div class="absolute bottom-3 left-3">
                      <UBadge
                        color="white"
                        class="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm text-slate-800 dark:text-white shadow-md"
                      >
                        {{
                          getCategoryName(post.category_id || post.category?.id)
                        }}
                      </UBadge>
                    </div>
                  </div>

                  <!-- Post Content -->
                  <div class="p-4 sm:w-2/3 flex flex-col justify-between">
                    <div>
                      <h3
                        class="font-medium text-slate-900 dark:text-white text-base mb-2"
                      >
                        {{ post.title }}
                      </h3>
                      <p
                        class="text-slate-600 dark:text-slate-400 text-sm line-clamp-2 mb-4"
                      >
                        {{ post.description || "No description available" }}
                      </p>
                    </div>

                    <!-- Post Footer -->
                    <div
                      class="flex items-center justify-between text-xs text-slate-500 dark:text-slate-500 border-t border-slate-100 dark:border-slate-700 pt-3"
                    >
                      <!-- Author Info -->
                      <div class="flex items-center">
                        <UAvatar
                          :src="
                            post.user?.image ||
                            post.user?.avatar ||
                            '/images/avatar-placeholder.jpg'
                          "
                          :alt="getUserName(post)"
                          size="xs"
                          class="mr-2"
                        />
                        <span>{{ getUserName(post) }}</span>
                      </div>

                      <!-- Date -->
                      <div class="flex items-center">
                        <UIcon name="i-heroicons-clock" class="w-3 h-3 mr-1" />
                        {{ formatDate(post.created_at) }}
                      </div>
                    </div>
                  </div>
                </div>
              </NuxtLink>
            </div>

            <!-- Load More Button -->
            <div v-if="hasMorePosts" class="my-10 text-center">
              <UButton
                color="emerald"
                variant="soft"
                size="lg"
                @click="loadMorePosts"
                :loading="isLoadingMore"
                class="px-6 shadow-sm hover:shadow-md"
              >
                <span v-if="!isLoadingMore">Load More Posts</span>
                <span v-else>Loading...</span>
              </UButton>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from "vue";
const { get } = useApi();
const route = useRoute();
const router = useRouter();

// Define page meta
definePageMeta({
  layout: "default",
});

// State
const isLoading = ref(true);
const isLoadingMore = ref(false);
const posts = ref([]);
const categories = ref([]);
const selectedCategory = ref(null);
const searchQuery = ref("");
const currentSlide = ref(0);
const slideInterval = ref(null);
const showMobileFilters = ref(false);
const sortBy = ref("newest");
const currentPage = ref(1);
const totalPages = ref(1);
const hasMorePosts = ref(true);
const postsPerPage = 20;

// Simplified sort options
const sortOptions = [
  { label: "Newest First", value: "newest" },
  { label: "Oldest First", value: "oldest" },
];

// Banner slides data - in a real app, these would come from the API
const bannerSlides = ref([
  {
    title: "Discover Amazing Deals",
    description:
      "Find the best offers from our trusted sellers and service providers.",
    image: "/images/banners/banner-1.jpg",
    link: "/promotions",
    buttonText: "Explore Now",
  },
  {
    title: "Join Our Community",
    description:
      "Connect with thousands of users and find exactly what you need.",
    image: "/images/banners/banner-2.jpg",
    link: "/register",
    buttonText: "Sign Up",
  },
  {
    title: "Premium Listings",
    description:
      "Exclusive offers and premium content from our verified partners.",
    image: "/images/banners/banner-3.jpg",
    link: "/premium",
    buttonText: "Go Premium",
  },
]);

// Filtered posts based on category and search
const filteredPosts = computed(() => {
  console.log("Recalculating filtered posts");
  console.log("Total posts:", posts.value.length);
  console.log("Selected category:", selectedCategory.value);

  let filtered = [...posts.value];

  // Filter by category
  if (selectedCategory.value !== null) {
    filtered = filtered.filter((post) => {
      // Check for category_id directly
      if (post.category_id === selectedCategory.value) return true;

      // Check for category.id
      if (post.category && post.category.id === selectedCategory.value)
        return true;

      // Check for string comparison
      if (String(post.category_id) === String(selectedCategory.value))
        return true;

      return false;
    });
  }

  // Filter by search
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(
      (post) =>
        post.title.toLowerCase().includes(query) ||
        (post.description && post.description.toLowerCase().includes(query))
    );
  }

  console.log("Filtered posts:", filtered.length);
  return filtered;
});

// Fetch posts and categories from the API
const fetchData = async () => {
  try {
    isLoading.value = true;
    console.log("Fetching data...");

    // Fetch from the actual API endpoints
    const [postsResponse, categoriesResponse] = await Promise.all([
      get("/classified-posts/"),
      get("/classified-categories-all/"),
    ]);

    console.log("API responses received");
    console.log("Posts response:", postsResponse?.data?.length || 0, "items");
    console.log(
      "Categories response:",
      categoriesResponse?.data?.length || 0,
      "items"
    );

    // Process and store the responses
    posts.value = postsResponse.data.results || postsResponse.data || [];
    categories.value = categoriesResponse.data || [];

    console.log("Processed data:");
    console.log("Posts:", posts.value.length);
    console.log("Categories:", categories.value.length);

    // Initial state - ensure no category is selected by default
    selectedCategory.value = null;

    // Set pagination data if available
    if (postsResponse.data.count) {
      totalPages.value = Math.ceil(postsResponse.data.count / postsPerPage);
      hasMorePosts.value = currentPage.value < totalPages.value;
    }

    // Log filtered posts to confirm they're working
    console.log("Initial filtered posts:", filteredPosts.value.length);

    // Initial sort
    sortPosts();
  } catch (error) {
    console.error("Error fetching data:", error);
    // Handle the error appropriately
  } finally {
    isLoading.value = false;
  }
};

// Helper function to get category name by ID
const getCategoryName = (categoryId) => {
  if (!categoryId) return "Uncategorized";

  // Try direct lookup first
  const directCategory = categories.value.find((c) => c.id === categoryId);
  if (directCategory) return directCategory.title;

  // If that fails, try different ways categories might be referenced
  const alternateCategory = categories.value.find(
    (c) =>
      String(c.id) === String(categoryId) || // String comparison
      c.category_id === categoryId || // Alternate field
      c.slug === categoryId // Possibly using slug
  );

  return alternateCategory ? alternateCategory.title : "Uncategorized";
};

// Helper function to get post count by category
const getCategoryCount = (categoryId) => {
  return posts.value.filter((post) => post.category_id === categoryId).length;
};

// Get total posts count
const getTotalPostsCount = () => {
  return posts.value.length;
};

// Format date
const formatDate = (dateString) => {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays === 0) {
    return "Today";
  } else if (diffDays === 1) {
    return "Yesterday";
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else if (diffDays < 30) {
    return `${Math.floor(diffDays / 7)} weeks ago`;
  } else {
    return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  }
};

// Filter posts by category
const filterByCategory = (categoryId) => {
  console.log("Filtering by category:", categoryId);
  selectedCategory.value = categoryId;
};

// Clear category filter
const clearCategoryFilter = () => {
  console.log("Clearing category filter");
  selectedCategory.value = null;
};

// Reset all filters
const resetFilters = () => {
  selectedCategory.value = null;
  searchQuery.value = "";
};

// Sort posts
const sortPosts = () => {
  // In a real application, you'd typically send this as a sort parameter to the API
  // For client-side sorting:
  switch (sortBy.value) {
    case "newest":
      posts.value.sort(
        (a, b) => new Date(b.created_at) - new Date(a.created_at)
      );
      break;
    case "oldest":
      posts.value.sort(
        (a, b) => new Date(a.created_at) - new Date(b.created_at)
      );
      break;
  }
};

// Load more posts
const loadMorePosts = async () => {
  if (currentPage.value >= totalPages.value) {
    hasMorePosts.value = false;
    return;
  }

  isLoadingMore.value = true;

  try {
    const nextPage = currentPage.value + 1;
    const response = await get(`/classified-posts/?page=${nextPage}`);

    const newPosts = response.data.results || response.data;

    if (newPosts.length === 0) {
      hasMorePosts.value = false;
    } else {
      // Add new posts to the existing list
      posts.value = [...posts.value, ...newPosts];
      currentPage.value = nextPage;
      hasMorePosts.value = currentPage.value < totalPages.value;
    }
  } catch (error) {
    console.error("Error loading more posts:", error);
  } finally {
    isLoadingMore.value = false;
  }
};

// Search functionality
const search = () => {
  // In a real app, this might trigger an API call with search parameters
  console.log("Searching for:", searchQuery.value);
};

// Create a custom debounce function implementation
function debounce(fn, delay) {
  let timeoutId;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      fn.apply(this, args);
    }, delay);
  };
}

// Create the debounced search function
const debouncedSearch = debounce(() => {
  search();
}, 500);

// Clear search
const clearSearch = () => {
  searchQuery.value = "";
  search();
};

// Banner slider controls
const nextSlide = () => {
  currentSlide.value = (currentSlide.value + 1) % bannerSlides.value.length;
  resetSlideInterval();
};

const prevSlide = () => {
  currentSlide.value =
    (currentSlide.value - 1 + bannerSlides.value.length) %
    bannerSlides.value.length;
  resetSlideInterval();
};

const goToSlide = (index) => {
  currentSlide.value = index;
  resetSlideInterval();
};

const resetSlideInterval = () => {
  clearInterval(slideInterval.value);
  startSlideInterval();
};

const startSlideInterval = () => {
  slideInterval.value = setInterval(() => {
    nextSlide();
  }, 5000);
};

// Initialize data and slider on component mount
onMounted(() => {
  fetchData();
  startSlideInterval();
});

// Cleanup on component unmount
onUnmounted(() => {
  clearInterval(slideInterval.value);
});

// Watch sort option changes
watch(sortBy, () => {
  sortPosts();
});

// Helper function to get user name
const getUserName = (post) => {
  if (!post) return "Anonymous";

  // Try all possible user name fields in order of preference
  return (
    post.user?.first_name ||
    post.user?.name ||
    post.user?.username ||
    post.author?.first_name ||
    post.author?.name ||
    post.author?.username ||
    post.created_by ||
    "Anonymous"
  );
};
</script>

<style scoped>
/* Banner Slider Animation */
.slide-content.active h2,
.slide-content.active p,
.slide-content.active button {
  transform: translateY(0);
  opacity: 1;
}

/* Ken Burns effect */
@keyframes kenBurns {
  from {
    transform: scale(1.05);
  }
  to {
    transform: scale(1.15);
  }
}

.animate-ken-burns {
  animation: kenBurns 10s ease-out forwards;
}

/* Premium card animations */
.post-card {
  transition: all 0.3s cubic-bezier(0.22, 1, 0.36, 1);
}

.post-card:hover {
  transform: translateY(-5px);
}

/* Custom scrollbar */
.scrollbar-thin::-webkit-scrollbar {
  width: 4px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(148, 163, 184, 0.3);
  border-radius: 9999px;
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(148, 163, 184, 0.2);
}

.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background-color: rgba(16, 185, 129, 0.5);
}

/* Mobile categories scrolling */
.mobile-categories-row {
  -webkit-overflow-scrolling: touch;
  scroll-behavior: smooth;
  scrollbar-width: none; /* Firefox */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Edge */
}

.hide-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
  cursor: grab;
}

.hide-scrollbar:active {
  cursor: grabbing;
}

/* Add highlight indicator to show there's more content */
.hide-scrollbar::after {
  content: "";
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  width: 30px;
  background: linear-gradient(to right, transparent, rgba(241, 245, 249, 0.5));
  pointer-events: none;
}

.dark .hide-scrollbar::after {
  background: linear-gradient(to right, transparent, rgba(15, 23, 42, 0.5));
}

/* Responsive adjustments */
@media (max-width: 640px) {
  .banner-slider {
    height: auto;
  }
}
</style>
