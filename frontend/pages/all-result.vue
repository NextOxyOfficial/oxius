<template>
  <div
    class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90"
  >
    <!-- Banner Slider Section with UContainer -->
    <div class="relative overflow-hidden mt-4 mb-8">
      <UContainer class="!px-0">
        <div
          class="carousel-container rounded-md overflow-hidden shadow-md relative"
        >
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
                    <div
                      class="w-12 h-1 bg-emerald-400 mb-4 rounded-full"
                    ></div>
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

          <!-- Banner Controls -->
          <div
            class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2"
          >
            <button
              v-for="(_, index) in bannerSlides"
              :key="index"
              @click="goToSlide(index)"
              class="w-2.5 h-2.5 rounded-full transition-all duration-300"
              :class="
                currentSlide === index
                  ? 'bg-emerald-400 scale-110'
                  : 'bg-white/50 hover:bg-white/70'
              "
            ></button>
          </div>

          <button
            @click="prevSlide"
            class="absolute left-3 top-1/2 transform -translate-y-1/2 bg-black/20 hover:bg-black/40 text-white rounded-full p-2 backdrop-blur-sm"
          >
            <UIcon name="i-heroicons-chevron-left" />
          </button>
          <button
            @click="nextSlide"
            class="absolute right-3 top-1/2 transform -translate-y-1/2 bg-black/20 hover:bg-black/40 text-white rounded-full p-2 backdrop-blur-sm"
          >
            <UIcon name="i-heroicons-chevron-right" />
          </button>
        </div>
      </UContainer>
    </div>

    <UContainer>
      <!-- Compact Search Bar -->
      <div class="mb-8 relative">
        <div class="max-w-2xl mx-auto relative">
          <input
            v-model="searchInput"
            type="text"
            placeholder="Search posts..."
            class="w-full py-3 px-5 pl-10 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-sm focus:ring-2 focus:ring-emerald-500"
            @input="debouncedSearch"
            @keyup.enter="performSearch"
          />
          <UIcon
            name="i-heroicons-magnifying-glass"
            class="absolute left-3.5 top-1/2 transform -translate-y-1/2 text-slate-400 size-4"
          />
          <button
            v-if="searchInput"
            @click="clearSearch"
            class="absolute right-3.5 top-1/2 transform -translate-y-1/2 text-slate-400 hover:text-slate-600"
          >
            <UIcon name="i-heroicons-x-mark" class="size-4" />
          </button>
        </div>

        <!-- Search Results Dropdown -->
        <div
          v-if="showSearchResults && searchResults.length > 0"
          class="absolute mt-1 w-full max-w-2xl bg-white dark:bg-slate-800 rounded-lg shadow-lg border border-slate-200 dark:border-slate-700 z-10 max-h-80 overflow-y-auto mx-auto left-0 right-0 search-dropdown"
          style="margin-left: auto; margin-right: auto"
        >
          <div class="p-2">
            <div class="text-xs text-slate-500 dark:text-slate-400 mb-1 px-2">
              Search results
            </div>
            <NuxtLink
              v-for="result in searchResults.slice(0, 5)"
              :key="result.id"
              :to="`/classified/${result.id}`"
              class="block p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-md"
              @click="showSearchResults = false"
            >
              <div class="font-medium text-slate-900 dark:text-white">
                {{ result.title }}
              </div>
              <div
                class="text-xs text-slate-500 dark:text-slate-400 line-clamp-1"
                v-html="result.description || 'No description'"
              ></div>
            </NuxtLink>

            <div
              v-if="searchResults.length > 5"
              class="mt-1 p-2 text-center text-sm text-emerald-600 dark:text-emerald-400 border-t border-slate-100 dark:border-slate-700"
            >
              <button
                @click="performSearch"
                class="font-medium hover:underline"
              >
                View all {{ searchResults.length }} results
              </button>
            </div>
          </div>
        </div>
      </div>

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

      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Categories Sidebar -->
        <div class="hidden lg:block w-full lg:w-64 flex-shrink-0">
          <!-- Sidebar content -->
        </div>

        <!-- Main Content Area -->
        <div class="flex-1">
          <!-- Filter Summary Bar -->
          <div
            class="bg-white dark:bg-slate-800/50 backdrop-blur-sm rounded-xl p-4 shadow-sm border border-slate-200/70 dark:border-slate-700/30 mb-6 flex flex-wrap items-center justify-between gap-3"
          >
            <div class="flex items-center">
              <h2
                class="text-base font-semibold text-slate-900 dark:text-white"
              >
                {{ resultsCount }} {{ resultsCount === 1 ? "Post" : "Posts" }}
              </h2>

              <div
                v-if="activeFilters.length > 0"
                class="flex items-center ml-4"
              >
                <div
                  class="bg-slate-100 dark:bg-slate-700/50 rounded-full h-1 w-1 mx-2"
                ></div>
                <UBadge
                  v-for="filter in activeFilters"
                  :key="filter.id"
                  color="emerald"
                  variant="soft"
                  class="ml-2 px-2.5 py-1 cursor-pointer"
                  @click="removeFilter(filter.id)"
                >
                  {{ filter.label }}
                  <UIcon name="i-heroicons-x-mark" class="ml-1.5 size-3" />
                </UBadge>

                <button
                  @click="clearAllFilters"
                  class="text-xs text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 ml-2 underline underline-offset-2"
                >
                  Clear all
                </button>
              </div>
            </div>
          </div>

          <!-- Loading State with Premium Animation -->
          <div
            v-if="isLoading"
            class="flex flex-col items-center justify-center py-32"
          >
            <div class="relative w-16 h-16">
              <div
                class="w-16 h-16 rounded-full border-4 border-slate-200 dark:border-slate-700"
              ></div>
              <div
                class="absolute top-0 left-0 w-16 h-16 rounded-full border-4 border-t-emerald-500 animate-spin"
              ></div>
            </div>
            <p class="mt-6 text-slate-500 dark:text-slate-400 font-medium">
              Loading posts...
            </p>
          </div>

          <!-- No Results State -->
          <div
            v-else-if="results.length === 0"
            class="flex flex-col items-center justify-center py-32"
          >
            <div
              class="w-20 h-20 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mb-4"
            >
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="size-10 text-slate-400"
              />
            </div>
            <h3
              class="text-xl font-semibold text-slate-900 dark:text-white mb-2"
            >
              No posts found
            </h3>
            <p
              class="text-slate-500 dark:text-slate-400 max-w-md text-center mb-6"
            >
              We couldn't find any posts matching your criteria. Try adjusting
              your filters or search terms.
            </p>
            <UButton
              color="emerald"
              variant="soft"
              size="lg"
              @click="clearAllFilters"
            >
              Clear filters
            </UButton>
          </div>
          <!-- Results Grid with 4 items per row -->
          <div v-else>
            <div
              class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5"
            >
              <NuxtLink
                v-for="(item, index) in results"
                :key="item.id"
                :to="`/classified/${item.id}`"
                class="result-card group bg-white dark:bg-slate-800/90 rounded-xl overflow-hidden shadow-sm hover:shadow-md border border-slate-200/70 dark:border-slate-700/40 transition-all duration-300"
                :style="{ animationDelay: `${index * 40}ms` }"
              >
                <!-- Thumbnail with hover effect -->
                <div class="relative overflow-hidden aspect-video">
                  <img
                    :src="
                      item.medias && item.medias.length > 0
                        ? item.medias[0].image
                        : '/images/placeholder.jpg'
                    "
                    :alt="item.title"
                    class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
                  />
                  <div
                    class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  ></div>

                  <!-- Category Badge -->
                  <div class="absolute top-3 right-3">
                    <UBadge color="emerald" variant="solid" class="shadow-sm">
                      <div class="flex items-center">
                        <UIcon
                          :name="getCategoryIcon(item.category?.id)"
                          class="size-3.5 mr-1"
                        />
                        <span>{{
                          item.category?.title || "Uncategorized"
                        }}</span>
                      </div>
                    </UBadge>
                  </div>
                </div>

                <!-- Content -->
                <div class="p-4">
                  <h3
                    class="font-semibold text-slate-900 dark:text-white text-base mb-2 line-clamp-2 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors"
                  >
                    {{ item.title }}
                  </h3>
                  <!-- Using v-html for description -->
                  <p
                    class="text-slate-600 dark:text-slate-300 text-sm mb-4 line-clamp-2"
                    v-html="
                      item.instructions ||
                      item.description ||
                      'No description available'
                    "
                  ></p>

                  <!-- Footer with metadata -->
                  <div
                    class="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-700/30"
                  >
                    <div class="flex items-center">
                      <UAvatar
                        :src="item.user?.image"
                        :alt="item.user?.username || 'Anonymous'"
                        size="xs"
                        class="mr-2"
                      />
                      <span
                        class="text-xs text-slate-500 dark:text-slate-400 truncate max-w-[100px]"
                      >
                        {{ item.user?.username || "Anonymous" }}
                      </span>
                    </div>
                    <span class="text-xs text-slate-400 dark:text-slate-500">
                      {{ timeAgo(item.created_at) }}
                    </span>
                  </div>
                </div>
              </NuxtLink>
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

            <!-- Load More Button instead of pagination -->
            <div class="mt-12 flex justify-center" v-if="hasMoreItems">
              <UButton
                color="emerald"
                variant="outline"
                @click="loadMore"
                :loading="isLoadingMore"
                size="lg"
                class="min-w-40"
              >
                Load More
              </UButton>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onBeforeUnmount } from "vue";
import { formatDistanceToNow } from "date-fns";

const timeAgo = (date) => {
  return formatDistanceToNow(new Date(date), { addSuffix: true });
};

const route = useRoute();
const router = useRouter();
const { get } = useApi();
const toast = useToast();

// State
const searchInput = ref("");
const searchQuery = ref("");
const selectedCategory = ref(null);
const sortOption = ref("newest");
const isLoading = ref(true);
const isLoadingMore = ref(false);
const results = ref([]);
const currentPage = ref(1);
const itemsPerPage = ref(16); // 4 rows of 4 items
const totalItems = ref(0);
const categories = ref([
  {
    label: "All Categories",
    value: null,
    image: null,
  },
]);
const categoryCounts = ref({});
const searchResults = ref([]);
const showSearchResults = ref(false);

// Banner Slider State
const currentSlide = ref(0);
const intervalId = ref(null);
const bannerSlides = ref([
  {
    image: "/images/banners/classified-banner-1.jpg",
    title: "Find What You Need",
    description:
      "Explore our marketplace for the best deals on thousands of items",
    link: "/all-result",
    buttonText: "Browse All",
  },
  {
    image: "/images/banners/classified-banner-2.jpg",
    title: "Post Your Items",
    description:
      "List your items for free and reach thousands of potential buyers",
    link: "/create-classified",
    buttonText: "Get Started",
  },
  {
    image: "/images/banners/classified-banner-3.jpg",
    title: "Local Services",
    description: "Find reliable local service providers for all your needs",
    link: "/all-result?category=services",
    buttonText: "Find Services",
  },
]);

// Sort options
const sortOptions = [
  { label: "Newest First", value: "newest" },
  { label: "Oldest First", value: "oldest" },
  { label: "Price: Low to High", value: "price_asc" },
  { label: "Price: High to Low", value: "price_desc" },
  { label: "Most Popular", value: "popular" },
];

// Icons for categories (pseudorandom based on category id)
const categoryIcons = [
  "i-heroicons-shopping-bag",
  "i-heroicons-home",
  "i-heroicons-wrench-screwdriver",
  "i-heroicons-academic-cap",
  "i-heroicons-briefcase",
  "i-heroicons-building-office",
  "i-heroicons-computer-desktop",
  "i-heroicons-truck",
];

// Computed properties
const hasMoreItems = computed(() => {
  return results.value.length < totalItems.value;
});

const categoriesWithCounts = computed(() => {
  return categories.value
    .filter((cat) => cat.value !== null)
    .map((category) => ({
      ...category,
      count: categoryCounts.value[category.value] || 0,
    }));
});

const activeFilters = computed(() => {
  const filters = [];

  if (searchQuery.value) {
    filters.push({
      id: "search",
      label: `Search: ${searchQuery.value}`,
    });
  }

  if (selectedCategory.value) {
    const category = categories.value.find(
      (c) => c.value === selectedCategory.value
    );
    if (category) {
      filters.push({
        id: "category",
        label: `Category: ${category.label}`,
      });
    }
  }

  if (sortOption.value && sortOption.value !== "newest") {
    const sort = sortOptions.find((s) => s.value === sortOption.value);
    if (sort) {
      filters.push({
        id: "sort",
        label: `Sort: ${sort.label}`,
      });
    }
  }

  return filters;
});

const resultsCount = computed(() => results.value.length);

// Banner methods
function nextSlide() {
  currentSlide.value = (currentSlide.value + 1) % bannerSlides.value.length;
  resetSliderInterval();
}

function prevSlide() {
  currentSlide.value =
    (currentSlide.value - 1 + bannerSlides.value.length) %
    bannerSlides.value.length;
  resetSliderInterval();
}

function goToSlide(index) {
  currentSlide.value = index;
  resetSliderInterval();
}

function startSliderInterval() {
  intervalId.value = setInterval(() => {
    nextSlide();
  }, 5000);
}

function resetSliderInterval() {
  clearInterval(intervalId.value);
  startSliderInterval();
}

// Methods for search and filtering
let searchTimeout = null;
function debouncedSearch() {
  showSearchResults.value = !!searchInput.value;

  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    if (searchInput.value) {
      fetchSearchResults();
    } else {
      searchResults.value = [];
      showSearchResults.value = false;
    }
  }, 300);
}

function clearSearch() {
  searchInput.value = "";
  searchQuery.value = "";
  searchResults.value = [];
  showSearchResults.value = false;
  fetchResults();
}

async function fetchSearchResults() {
  try {
    const params = new URLSearchParams();
    params.append("title", searchInput.value);
    params.append("is_approved", "true");
    params.append("status", "active");
    params.append("page_size", "10");

    const response = await get(`/classified-posts/?${params.toString()}`);

    if (response && response.data && response.data.results) {
      searchResults.value = response.data.results;
    }
  } catch (error) {
    console.error("Error fetching search results:", error);
    searchResults.value = [];
  }
}

function performSearch() {
  if (searchInput.value) {
    searchQuery.value = searchInput.value;
    currentPage.value = 1;
    showSearchResults.value = false;
    fetchResults();

    // Update URL with search query
    router.push({
      path: route.path,
      query: {
        ...route.query,
        q: searchInput.value,
      },
    });
  }
}

function selectCategory(categoryId) {
  selectedCategory.value = categoryId;
  currentPage.value = 1;
  fetchResults();

  // Update URL with category
  router.push({
    path: route.path,
    query: {
      ...route.query,
      category: categoryId,
    },
  });
}

function clearCategoryFilter() {
  selectedCategory.value = null;
  currentPage.value = 1;
  fetchResults();

  // Update URL
  const query = { ...route.query };
  delete query.category;

  router.push({
    path: route.path,
    query,
  });
}

function sortResults() {
  fetchResults();

  // Update URL with sort option
  router.push({
    path: route.path,
    query: {
      ...route.query,
      sort: sortOption.value,
    },
  });
}

function removeFilter(filterId) {
  if (filterId === "search") {
    searchQuery.value = "";
    searchInput.value = "";
  } else if (filterId === "category") {
    selectedCategory.value = null;
  } else if (filterId === "sort") {
    sortOption.value = "newest";
  }

  fetchResults();

  // Update URL
  const query = { ...route.query };
  if (filterId === "search") delete query.q;
  if (filterId === "category") delete query.category;
  if (filterId === "sort") delete query.sort;

  router.push({
    path: route.path,
    query,
  });
}

function clearAllFilters() {
  searchQuery.value = "";
  searchInput.value = "";
  selectedCategory.value = null;
  sortOption.value = "newest";
  currentPage.value = 1;

  fetchResults();

  // Reset URL
  router.push({ path: route.path });
}

// Load more items function instead of pagination
async function loadMore() {
  if (isLoadingMore.value) return;

  isLoadingMore.value = true;

  try {
    currentPage.value += 1;

    // Build query parameters
    let endpoint = "/classified-posts/";
    const params = new URLSearchParams();

    // Add pagination
    params.append("page", currentPage.value);
    params.append("page_size", itemsPerPage.value);

    // Only show approved posts
    params.append("is_approved", "true");
    params.append("status", "active");

    // Add search if present
    if (searchQuery.value) {
      params.append("title", searchQuery.value);
    }

    // Change endpoint if category filtering is needed
    if (selectedCategory.value) {
      endpoint = "/classified-posts/filter/";
      params.append("category", selectedCategory.value);
    }

    // Add sorting
    if (sortOption.value) {
      // Map frontend sort options to backend options
      const sortMapping = {
        newest: "-created_at",
        oldest: "created_at",
        price_asc: "price",
        price_desc: "-price",
        popular: "-view_count",
      };

      const backendSort = sortMapping[sortOption.value] || "-created_at";
      params.append("ordering", backendSort);
    }

    // Make the API call
    const response = await get(`${endpoint}?${params.toString()}`);

    if (response && response.data) {
      if (response.data.results) {
        // Append to existing results
        results.value = [...results.value, ...response.data.results];
        totalItems.value = response.data.count;
      } else if (Array.isArray(response.data)) {
        // Handle array response
        results.value = [...results.value, ...response.data];
        totalItems.value = results.value.length;
      }
    }
  } catch (error) {
    console.error("Error loading more posts:", error);
    toast.add({
      title: "Error loading more posts",
      description: error.message || "Failed to load more posts",
      color: "red",
    });
  } finally {
    isLoadingMore.value = false;
  }
}

function getCategoryColor(categoryId) {
  // Create a deterministic color based on category ID
  const colors = [
    "green",
    "emerald",
    "teal",
    "cyan",
    "blue",
    "indigo",
    "violet",
  ];

  if (!categoryId) return "gray";

  // Use the string hash to pick a consistent color
  const hash = categoryId.split("").reduce((a, b) => {
    a = (a << 5) - a + b.charCodeAt(0);
    return a & a;
  }, 0);

  return colors[Math.abs(hash) % colors.length];
}

// Modified function to get category icon or image
function getCategoryIcon(categoryId) {
  // First check if we have this category with an image
  const category = categories.value.find((c) => c.value === categoryId);

  // If we have a category with an image, return that
  if (category && category.image) {
    return category.image;
  }

  // Fallback to default icons
  if (!categoryId) return "i-heroicons-squares-2x2";

  // Use the string hash to pick a consistent icon
  const hash = String(categoryId)
    .split("")
    .reduce((a, b) => {
      a = (a << 5) - a + b.charCodeAt(0);
      return a & a;
    }, 0);

  return categoryIcons[Math.abs(hash) % categoryIcons.length];
}

// New function to check if a value is a URL
function isImageUrl(value) {
  return (
    typeof value === "string" &&
    (value.startsWith("http://") || value.startsWith("https://"))
  );
}

function formatDate(dateString) {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat("en-US", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(date);
}

// Fetch category counts
async function fetchCategoryCounts() {
  try {
    const response = await get("/classified-categories-count/");
    if (response && response.data) {
      const countData = {};

      // Assuming response.data is an array of objects with id and count properties
      response.data.forEach((item) => {
        countData[item.id] = item.count;
      });

      categoryCounts.value = countData;
    }
  } catch (error) {
    console.error("Error fetching category counts:", error);
  }
}

// Fetch categories
async function fetchCategories() {
  try {
    const response = await get("/classified-categories-all/");
    if (response && response.data) {
      // Map API response to format needed with images
      const apiCategories = response.data.map((category) => ({
        label: category.title,
        value: category.id,
        image: category.image || null,
      }));

      // Keep "All Categories" option at the top
      categories.value = [
        { label: "All Categories", value: null, image: null },
        ...apiCategories,
      ];

      // Fetch category counts after fetching categories
      await fetchCategoryCounts();
    }
  } catch (error) {
    console.error("Error fetching categories:", error);
    toast.add({
      title: "Failed to load categories",
      description: error.message || "An unexpected error occurred",
      color: "red",
    });
  }
}

async function fetchResults() {
  isLoading.value = true;
  results.value = []; // Clear results when fetching new ones
  currentPage.value = 1; // Reset to first page

  try {
    // Build query parameters
    let endpoint = "/classified-posts/";
    const params = new URLSearchParams();

    // Add pagination
    params.append("page", currentPage.value);
    params.append("page_size", itemsPerPage.value);

    // Only show approved posts
    params.append("is_approved", "true");
    params.append("status", "active");

    // Add search if present
    if (searchQuery.value) {
      params.append("title", searchQuery.value);
    }

    // Change endpoint if category filtering is needed
    if (selectedCategory.value) {
      endpoint = "/classified-posts/filter/";
      params.append("category", selectedCategory.value);
    }

    // Add sorting
    if (sortOption.value) {
      // Map frontend sort options to backend options
      const sortMapping = {
        newest: "-created_at",
        oldest: "created_at",
        price_asc: "price",
        price_desc: "-price",
        popular: "-view_count", // Assuming there's a view_count field
      };

      const backendSort = sortMapping[sortOption.value] || "-created_at";
      params.append("ordering", backendSort);
    }

    // Make the API call
    const response = await get(`${endpoint}?${params.toString()}`);

    if (response && response.data) {
      if (response.data.results) {
        // Handle paginated response
        results.value = response.data.results;
        totalItems.value = response.data.count;
      } else if (Array.isArray(response.data)) {
        // Handle array response
        results.value = response.data;
        totalItems.value = response.data.length;
      } else {
        // Handle unexpected format
        results.value = [];
        totalItems.value = 0;
        console.error("Unexpected API response format:", response.data);
      }
    } else {
      results.value = [];
      totalItems.value = 0;
    }
  } catch (error) {
    console.error("Error fetching results:", error);
    results.value = [];
    totalItems.value = 0;

    toast.add({
      title: "Error loading posts",
      description: error.message || "Failed to load classified posts",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// Initialize from URL params and fetch data
onMounted(async () => {
  const { q, category, sort } = route.query;

  if (q) {
    searchInput.value = q;
    searchQuery.value = q;
  }

  if (category) {
    selectedCategory.value = category;
  }

  if (sort) {
    sortOption.value = sort;
  }

  // Start banner slider
  startSliderInterval();

  // Fetch categories first, then fetch results
  await fetchCategories();
  fetchResults();

  // Handle clicks outside search results dropdown
  window.addEventListener("click", (e) => {
    if (!e.target.closest(".search-dropdown") && showSearchResults.value) {
      showSearchResults.value = false;
    }
  });
});

// Cleanup on component unmount
onBeforeUnmount(() => {
  clearInterval(intervalId.value);
  window.removeEventListener("click", () => {});
});

// Watch for route changes
watch(
  () => route.query,
  (newQuery) => {
    const { q, category, sort } = newQuery;

    if (q !== undefined && q !== searchQuery.value) {
      searchInput.value = q || "";
      searchQuery.value = q || "";
    }

    if (category !== undefined && category !== selectedCategory.value) {
      selectedCategory.value = category || null;
    }

    if (sort !== undefined && sort !== sortOption.value) {
      sortOption.value = sort || "newest";
    }

    if (JSON.stringify(newQuery) !== JSON.stringify(route.query)) {
      fetchResults();
    }
  },
  { deep: true }
);
</script>

<style scoped>
.result-card {
  animation: fadeUp 0.5s ease-out forwards;
  opacity: 0;
}

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

/* Premium card hover effect */
.result-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05),
    0 8px 10px -6px rgba(0, 0, 0, 0.03);
}

/* Custom scrollbar styling */
.scrollbar-thin::-webkit-scrollbar {
  width: 4px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.3);
  border-radius: 6px;
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.15);
}

.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background-color: rgba(156, 163, 175, 0.5);
}

@media (prefers-reduced-motion: reduce) {
  .result-card {
    animation: none;
    opacity: 1;
  }

  .result-card:hover {
    transform: none;
  }
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
