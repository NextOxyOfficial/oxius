<template>
  <div
    class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90"
  >
    <!-- Hero Header with Animated Background -->
    <div
      class="relative overflow-hidden py-10 border-b border-slate-200 dark:border-slate-800"
    >
      <!-- Animated Background Elements -->
      <div class="absolute inset-0 z-0">
        <div
          class="absolute top-10 left-[10%] w-64 h-64 rounded-full bg-primary-300/10 dark:bg-primary-600/5 blur-3xl"
        ></div>
        <div
          class="absolute bottom-5 right-[15%] w-72 h-72 rounded-full bg-amber-300/10 dark:bg-amber-600/5 blur-3xl"
        ></div>
      </div>

      <UContainer class="relative z-10">
        <div class="max-w-3xl mx-auto text-center">
          <h1
            class="text-2xl sm:text-3xl md:text-4xl font-bold text-slate-900 dark:text-white mb-3 tracking-tight"
          >
            All Posts
          </h1>
          <p class="text-slate-600 dark:text-slate-300 mb-6 max-w-xl mx-auto">
            {{
              searchQuery
                ? `Showing results for "${searchQuery}"`
                : "Discover our extensive collection of high-quality posts"
            }}
          </p>

          <!-- Premium Search Bar -->
          <div class="relative max-w-2xl mx-auto">
            <div
              class="absolute inset-0 bg-gradient-to-r from-primary-500/20 via-transparent to-amber-500/20 blur-lg rounded-full opacity-50"
            ></div>
            <div class="relative flex">
              <input
                v-model="searchInput"
                type="text"
                placeholder="Search for anything..."
                class="w-full py-4 px-6 pl-12 rounded-l-xl border-0 bg-white dark:bg-slate-800/90 shadow-lg focus:ring-2 focus:ring-primary-500"
                @keyup.enter="performSearch"
              />
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="absolute left-4 top-1/2 transform -translate-y-1/2 text-slate-400 size-5"
              />
              <button
                @click="performSearch"
                class="bg-primary-600 hover:bg-primary-700 text-white px-6 rounded-r-xl font-medium transition-colors flex items-center justify-center"
              >
                Search
              </button>
            </div>
          </div>
        </div>
      </UContainer>
    </div>

    <UContainer class="py-10">
      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Categories Sidebar -->
        <div class="w-full lg:w-64 flex-shrink-0">
          <div
            class="bg-white dark:bg-slate-800/50 backdrop-blur-sm rounded-xl p-5 shadow-sm border border-slate-200/70 dark:border-slate-700/30 sticky top-24"
          >
            <div class="flex items-center mb-4">
              <div
                class="h-5 w-1.5 rounded-full bg-gradient-to-b from-primary-400 to-primary-600 mr-3"
              ></div>
              <h2 class="text-lg font-semibold text-slate-900 dark:text-white">
                Categories
              </h2>
            </div>

            <!-- Category List -->
            <div
              class="space-y-1.5 max-h-[60vh] overflow-y-auto pr-1 scrollbar-thin"
            >
              <button
                @click="clearCategoryFilter"
                class="w-full text-left px-3 py-2 rounded-lg transition-colors flex items-center"
                :class="
                  !selectedCategory
                    ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300 font-medium'
                    : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/30'
                "
              >
                <UIcon
                  name="i-heroicons-squares-2x2-mini"
                  class="mr-2 size-4"
                />
                All Categories
                <span
                  v-if="!selectedCategory"
                  class="ml-auto bg-primary-100 dark:bg-primary-800/30 text-primary-700 dark:text-primary-300 text-xs rounded-full px-2 py-0.5"
                >
                  {{ totalItems }}
                </span>
              </button>

              <button
                v-for="category in categories.filter((c) => c.value !== null)"
                :key="category.value"
                @click="() => selectCategory(category.value)"
                class="w-full text-left px-3 py-2 rounded-lg transition-colors flex items-center group"
                :class="
                  selectedCategory === category.value
                    ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300 font-medium'
                    : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/30'
                "
              >
                <UIcon
                  :name="getCategoryIcon(category.value)"
                  class="mr-2 size-4"
                />
                {{ category.label }}
                <span
                  v-if="selectedCategory === category.value"
                  class="ml-auto bg-primary-100 dark:bg-primary-800/30 text-primary-700 dark:text-primary-300 text-xs rounded-full px-2 py-0.5"
                >
                  {{ resultsCount }}
                </span>
              </button>
            </div>

            <!-- Sort By Section -->
            <div
              class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700/30"
            >
              <h3 class="font-medium text-slate-900 dark:text-white mb-3">
                Sort Results
              </h3>
              <USelect
                v-model="sortOption"
                :options="sortOptions"
                size="md"
                class="w-full"
                @update:modelValue="sortResults"
              />
            </div>
          </div>
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
                  color="primary"
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

            <!-- View Mode Toggle -->
            <UButtonGroup>
              <UButton
                :color="viewMode === 'grid' ? 'primary' : 'gray'"
                @click="viewMode = 'grid'"
                icon="i-heroicons-squares-2x2"
                variant="soft"
                size="sm"
                aria-label="Grid view"
              />
              <UButton
                :color="viewMode === 'list' ? 'primary' : 'gray'"
                @click="viewMode = 'list'"
                icon="i-heroicons-bars-3"
                variant="soft"
                size="sm"
                aria-label="List view"
              />
            </UButtonGroup>
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
                class="absolute top-0 left-0 w-16 h-16 rounded-full border-4 border-t-primary-500 animate-spin"
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
              color="primary"
              variant="soft"
              size="lg"
              @click="clearAllFilters"
            >
              Clear filters
            </UButton>
          </div>

          <!-- Results Grid with Staggered Animation -->
          <div v-else>
            <!-- Grid View - 6 cards per row on large screens -->
            <div
              v-if="viewMode === 'grid'"
              class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-5"
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
                  <UBadge
                    :color="getCategoryColor(item.category?.id)"
                    variant="soft"
                    class="absolute top-3 left-3"
                  >
                    {{ item.category?.title || "Uncategorized" }}
                  </UBadge>
                </div>

                <!-- Content -->
                <div class="p-4">
                  <h3
                    class="font-semibold text-slate-900 dark:text-white text-base mb-2 line-clamp-2 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors"
                  >
                    {{ item.title }}
                  </h3>
                  <p
                    class="text-slate-600 dark:text-slate-300 text-sm mb-4 line-clamp-2"
                  >
                    {{
                      item.instructions ||
                      item.description ||
                      "No description available"
                    }}
                  </p>

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
                      {{ formatDate(item.created_at) }}
                    </span>
                  </div>
                </div>
              </NuxtLink>
            </div>

            <!-- List View -->
            <div v-else class="space-y-4">
              <NuxtLink
                v-for="(item, index) in results"
                :key="item.id"
                :to="`/classified/${item.id}`"
                class="result-card flex flex-col sm:flex-row bg-white dark:bg-slate-800/90 rounded-xl overflow-hidden shadow-sm hover:shadow-md border border-slate-200/70 dark:border-slate-700/40 transition-all duration-300"
                :style="{ animationDelay: `${index * 40}ms` }"
              >
                <!-- Thumbnail -->
                <div class="sm:w-48 md:w-64 relative overflow-hidden">
                  <img
                    :src="
                      item.medias && item.medias.length > 0
                        ? item.medias[0].image
                        : '/images/placeholder.jpg'
                    "
                    :alt="item.title"
                    class="w-full h-full object-cover aspect-video sm:aspect-auto"
                  />

                  <!-- Category Badge -->
                  <UBadge
                    :color="getCategoryColor(item.category?.id)"
                    variant="soft"
                    class="absolute top-3 left-3"
                  >
                    {{ item.category?.title || "Uncategorized" }}
                  </UBadge>
                </div>

                <!-- Content -->
                <div class="flex-1 p-5">
                  <h3
                    class="font-semibold text-slate-900 dark:text-white text-lg mb-2 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors"
                  >
                    {{ item.title }}
                  </h3>
                  <p class="text-slate-600 dark:text-slate-300 text-sm mb-4">
                    {{
                      item.instructions ||
                      item.description ||
                      "No description available"
                    }}
                  </p>

                  <!-- Footer with metadata -->
                  <div
                    class="flex items-center justify-between pt-3 border-t border-slate-100 dark:border-slate-700/30"
                  >
                    <div class="flex items-center">
                      <UAvatar
                        :src="item.user?.image"
                        :alt="item.user?.username || 'Anonymous'"
                        size="sm"
                        class="mr-2"
                      />
                      <span class="text-sm text-slate-500 dark:text-slate-400">
                        {{ item.user?.username || "Anonymous" }}
                      </span>
                    </div>
                    <span class="text-xs text-slate-400 dark:text-slate-500">
                      {{ formatDate(item.created_at) }}
                    </span>
                  </div>
                </div>
              </NuxtLink>
            </div>
          </div>

          <!-- Enhanced Pagination -->
          <div class="mt-12 flex justify-center">
            <UPagination
              v-model="currentPage"
              :total="totalItems"
              :page-count="5"
              :items-per-page="itemsPerPage"
              :ui="{
                wrapper: 'flex items-center gap-1',
                base: 'rounded-lg transition-colors flex items-center justify-center',
                default: {
                  size: 'size-10',
                  inactive:
                    'bg-white dark:bg-slate-800 text-slate-500 hover:text-slate-900 dark:hover:text-white border border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600',
                  active:
                    'bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-800/30 text-primary-600 dark:text-primary-400 font-semibold',
                },
              }"
              @change="changePage"
            />
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from "vue";
const route = useRoute();
const router = useRouter();
const { get } = useApi();
const toast = useToast();

// State
const searchInput = ref("");
const searchQuery = ref("");
const selectedCategory = ref(null);
const sortOption = ref("newest");
const viewMode = ref("grid");
const isLoading = ref(true);
const results = ref([]);
const currentPage = ref(1);
const itemsPerPage = ref(18); // 3 rows of 6 items for desktop
const totalItems = ref(0);
const categories = ref([{ label: "All Categories", value: null }]);

const sortOptions = [
  { label: "Newest First", value: "newest" },
  { label: "Oldest First", value: "oldest" },
  { label: "Price: Low to High", value: "price_asc" },
  { label: "Price: High to Low", value: "price_desc" },
  { label: "Most Popular", value: "popular" },
];

// Icons for categories (pseudorandom based on category id)
const categoryIcons = [
  "i-heroicons-shopping-bag-mini",
  "i-heroicons-home-mini",
  "i-heroicons-wrench-screwdriver-mini",
  "i-heroicons-academic-cap-mini",
  "i-heroicons-briefcase-mini",
  "i-heroicons-building-office-mini",
  "i-heroicons-computer-desktop-mini",
  "i-heroicons-truck-mini",
];

// Fetch categories
async function fetchCategories() {
  try {
    const response = await get("/classified-categories-all/");
    if (response && response.data) {
      // Map API response to format needed for USelect
      const apiCategories = response.data.map((category) => ({
        label: category.title,
        value: category.id,
      }));

      // Keep "All Categories" option at the top
      categories.value = [
        { label: "All Categories", value: null },
        ...apiCategories,
      ];
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

// Computed properties
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

// Methods
function performSearch() {
  if (searchInput.value) {
    searchQuery.value = searchInput.value;
    currentPage.value = 1;
    fetchResults();

    // Update URL with search query
    router.push({
      path: route.path,
      query: {
        ...route.query,
        q: searchInput.value,
        page: 1,
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
      page: 1,
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

function changePage(page) {
  currentPage.value = page;
  fetchResults();

  // Update URL with page number
  router.push({
    path: route.path,
    query: {
      ...route.query,
      page,
    },
  });

  // Scroll to top
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function getCategoryColor(categoryId) {
  // Create a deterministic color based on category ID
  const colors = [
    "green",
    "blue",
    "purple",
    "orange",
    "red",
    "amber",
    "emerald",
  ];

  if (!categoryId) return "gray";

  // Use the string hash to pick a consistent color
  const hash = categoryId.split("").reduce((a, b) => {
    a = (a << 5) - a + b.charCodeAt(0);
    return a & a;
  }, 0);

  return colors[Math.abs(hash) % colors.length];
}

function getCategoryIcon(categoryId) {
  if (!categoryId) return "i-heroicons-squares-2x2-mini";

  // Use the string hash to pick a consistent icon
  const hash = categoryId.split("").reduce((a, b) => {
    a = (a << 5) - a + b.charCodeAt(0);
    return a & a;
  }, 0);

  return categoryIcons[Math.abs(hash) % categoryIcons.length];
}

function formatDate(dateString) {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat("en-US", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(date);
}

async function fetchResults() {
  isLoading.value = true;

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
  const { q, category, sort, page } = route.query;

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

  if (page) {
    currentPage.value = parseInt(page, 10);
  }

  // Fetch categories first, then fetch results
  await fetchCategories();
  fetchResults();
});

// Watch for route changes
watch(
  () => route.query,
  (newQuery) => {
    const { q, category, sort, page } = newQuery;

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

    if (page !== undefined && parseInt(page, 10) !== currentPage.value) {
      currentPage.value = parseInt(page, 10) || 1;
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
</style>
