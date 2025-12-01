<template>
  <div id="micro-gigs" class="min-h-screen bg-gradient-to-br from-gray-50 to-emerald-50/30">
    <UContainer class="py-6 md:py-10">
      <!-- Header Section -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center gap-2 bg-emerald-100 text-emerald-700 rounded-full px-4 py-1.5 mb-4">
          <UIcon name="i-heroicons-bolt" class="w-4 h-4" />
          <span class="text-sm font-medium">{{ $t("quick_earn") }}</span>
        </div>
        <h1 class="text-2xl md:text-3xl font-bold text-gray-900 mb-2">
          {{ $t("micro_gigs") }}
        </h1>
        <p class="text-gray-600 max-w-xl mx-auto">
          Complete simple tasks and earn money instantly. Choose from various categories below.
        </p>
      </div>

      <!-- Account Balance Card -->
      <AccountBalance v-if="user" :user="user" :isUser="true" class="mb-6" />

      <!-- Quick Actions Bar -->
      <div class="flex flex-wrap items-center justify-center gap-3 mb-8">
        <NuxtLink
          to="/mobile-recharge"
          class="inline-flex items-center gap-2 bg-white hover:bg-gray-50 border border-gray-200 rounded-xl px-4 py-2.5 transition-all hover:shadow-md"
        >
          <UIcon name="i-heroicons-device-phone-mobile" class="w-5 h-5 text-emerald-600" />
          <span class="font-medium text-gray-700">Mobile Recharge</span>
          <div class="flex -space-x-1">
            <NuxtImg
              v-for="operator in operators.slice(0, 4)"
              :key="operator.id"
              :src="operator.icon"
              :title="operator.title"
              class="w-5 h-5 rounded-full border border-white"
            />
          </div>
        </NuxtLink>
        <NuxtLink
          to="/post-gig"
          class="inline-flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl px-4 py-2.5 transition-all hover:shadow-md"
        >
          <UIcon name="i-heroicons-plus" class="w-5 h-5" />
          <span class="font-medium">Post a Gig</span>
        </NuxtLink>
      </div>

      <!-- Main Content -->
      <div class="flex flex-col lg:flex-row gap-6">
        <!-- Sidebar - Categories -->
        <div class="w-full lg:w-64 flex-shrink-0">
          <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden sticky top-20">
            <div class="p-4 bg-gradient-to-r from-emerald-500 to-teal-500 text-white">
              <h3 class="font-semibold flex items-center gap-2">
                <UIcon name="i-heroicons-squares-2x2" class="w-5 h-5" />
                Categories
              </h3>
            </div>
            <div class="p-2 max-h-[400px] overflow-y-auto">
              <!-- All Categories -->
              <button
                @click.prevent="selectAllCategories"
                class="w-full flex items-center justify-between p-3 rounded-xl transition-all"
                :class="!selectedCategory ? 'bg-emerald-50 text-emerald-700' : 'hover:bg-gray-50 text-gray-700'"
              >
                <span class="font-medium">{{ $t("all_category") }}</span>
                <UBadge color="emerald" variant="soft" size="xs">{{ totalGigs }}</UBadge>
              </button>
              
              <!-- Category List -->
              <button
                v-for="category in categoryArray"
                :key="category?.id"
                @click.prevent="selectCategory(category)"
                class="w-full flex items-center justify-between p-3 rounded-xl transition-all"
                :class="selectedCategory?.id === category.id ? 'bg-emerald-50 text-emerald-700' : 'hover:bg-gray-50 text-gray-700'"
              >
                <span class="capitalize truncate">{{ category.category }}</span>
                <UBadge :color="selectedCategory?.id === category.id ? 'emerald' : 'gray'" variant="soft" size="xs">
                  {{ category.active }}
                </UBadge>
              </button>
            </div>
          </div>
        </div>

        <!-- Main Content - Gigs List -->
        <div class="flex-1">
          <!-- Filter Bar -->
          <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-4">
            <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div class="flex items-center gap-3">
                <h2 class="font-semibold text-gray-900 flex items-center gap-2">
                  <UIcon name="i-heroicons-briefcase" class="w-5 h-5 text-emerald-600" />
                  {{ $t("available_gigs") }}
                </h2>
                <UBadge color="emerald" variant="soft">{{ totalGigs }} gigs</UBadge>
              </div>
              <div class="flex items-center gap-3">
                <USelectMenu
                  v-model="microGigsStatus"
                  :options="microGigsFilter"
                  @change="getMicroGigsByAvailability($event)"
                  placeholder="Filter"
                  value-attribute="value"
                  option-attribute="title"
                  size="sm"
                  class="w-36"
                  :ui="{ rounded: 'rounded-lg' }"
                />
              </div>
            </div>
          </div>

          <!-- Gigs Grid -->
          <div class="space-y-3">
            <div
              v-for="(gig, i) in paginatedGigs"
              :key="i"
              v-if="gig.user"
              class="bg-white rounded-xl shadow-sm border border-gray-100 hover:shadow-md hover:border-emerald-200 transition-all duration-200 overflow-hidden"
            >
              <div class="p-4">
                <div class="flex items-start gap-4">
                  <!-- Category Icon -->
                  <div class="flex-shrink-0">
                    <div class="w-14 h-14 rounded-xl bg-gradient-to-br from-emerald-100 to-teal-100 flex items-center justify-center overflow-hidden">
                      <NuxtImg
                        v-if="!errorIndex.includes(i) && gig.category_details?.image"
                        :src="gig.category_details?.image"
                        class="w-10 h-10 object-contain"
                        @error="handleImageError(i)"
                      />
                      <UIcon v-else name="i-heroicons-briefcase" class="w-6 h-6 text-emerald-600" />
                    </div>
                  </div>

                  <!-- Gig Details -->
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start justify-between gap-4">
                      <div class="flex-1 min-w-0">
                        <h3 class="font-semibold text-gray-900 mb-1 line-clamp-1">
                          {{ gig.title }}
                        </h3>
                        <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-gray-500">
                          <!-- Progress -->
                          <div class="flex items-center gap-1.5">
                            <UIcon name="i-heroicons-users" class="w-4 h-4" />
                            <span>
                              <span class="font-medium text-gray-700">{{ gig.filled_quantity }}</span>
                              <span class="text-gray-400">/</span>
                              <span class="text-emerald-600">{{ gig.required_quantity }}</span>
                            </span>
                          </div>
                          <!-- Date -->
                          <div class="flex items-center gap-1.5">
                            <UIcon name="i-heroicons-clock" class="w-4 h-4" />
                            <span>{{ formatDate(gig.created_at) }}</span>
                          </div>
                          <!-- Posted By -->
                          <div class="flex items-center gap-1.5">
                            <UIcon name="i-heroicons-user" class="w-4 h-4" />
                            <span>{{ gig.user.name?.slice(0, 8) }}***</span>
                          </div>
                        </div>
                      </div>

                      <!-- Price & Action (Desktop) -->
                      <div class="hidden sm:flex items-center gap-4">
                        <div class="text-right">
                          <div class="text-xs text-gray-500 mb-0.5">Earn</div>
                          <div class="text-xl font-bold text-emerald-600 flex items-center">
                            <span class="text-sm">৳</span>{{ gig.price }}
                          </div>
                        </div>
                        <UButton
                          v-if="user?.user && user?.user?.id !== gig.user.id"
                          :to="`/order/${gig.slug}/`"
                          color="primary"
                          size="md"
                          class="px-6"
                        >
                          <UIcon name="i-heroicons-currency-dollar" class="w-4 h-4 mr-1" />
                          Earn Now
                        </UButton>
                        <UButton
                          v-else-if="user?.user?.id === gig.user.id"
                          disabled
                          color="gray"
                          variant="soft"
                          size="md"
                        >
                          Your Gig
                        </UButton>
                        <UButton
                          v-else
                          to="/auth/login"
                          color="primary"
                          variant="outline"
                          size="md"
                          class="px-6"
                        >
                          Login to Earn
                        </UButton>
                      </div>
                    </div>

                    <!-- Progress Bar -->
                    <div class="mt-3">
                      <div class="flex items-center justify-between text-xs mb-1">
                        <span class="text-gray-500">Progress</span>
                        <span class="font-medium" :class="getProgressColor(gig)">
                          {{ Math.round((gig.filled_quantity / gig.required_quantity) * 100) }}%
                        </span>
                      </div>
                      <div class="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                        <div 
                          class="h-full rounded-full transition-all duration-300"
                          :class="getProgressBarColor(gig)"
                          :style="{ width: `${Math.min((gig.filled_quantity / gig.required_quantity) * 100, 100)}%` }"
                        ></div>
                      </div>
                    </div>

                    <!-- Mobile Price & Action -->
                    <div class="flex items-center justify-between mt-3 sm:hidden">
                      <div class="text-lg font-bold text-emerald-600 flex items-center">
                        <span class="text-sm">৳</span>{{ gig.price }}
                      </div>
                      <UButton
                        v-if="user?.user && user?.user?.id !== gig.user.id"
                        :to="`/order/${gig.slug}/`"
                        color="primary"
                        size="sm"
                      >
                        Earn Now
                      </UButton>
                      <UButton
                        v-else-if="user?.user?.id === gig.user.id"
                        disabled
                        color="gray"
                        variant="soft"
                        size="sm"
                      >
                        Your Gig
                      </UButton>
                      <UButton
                        v-else
                        to="/auth/login"
                        color="primary"
                        variant="outline"
                        size="sm"
                      >
                        Login
                      </UButton>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Professional Pagination Section -->
          <div v-if="microGigs?.length > 0" class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mt-4">
            <!-- Results Info -->
            <div class="flex flex-col sm:flex-row items-center justify-between gap-4 mb-4">
              <p class="text-sm text-gray-600">
                Showing <span class="font-medium text-gray-900">{{ startIndex + 1 }}</span> to 
                <span class="font-medium text-gray-900">{{ endIndex }}</span> of 
                <span class="font-medium text-gray-900">{{ totalGigs }}</span> gigs
              </p>
              
              <!-- Items per page selector -->
              <div class="flex items-center gap-2">
                <span class="text-sm text-gray-600">Show:</span>
                <USelectMenu
                  v-model="selectedItemsPerPage"
                  :options="itemsPerPageOptions"
                  size="sm"
                  class="w-20"
                  @change="handleItemsPerPageChange"
                />
              </div>
            </div>

            <!-- Pagination Controls -->
            <nav class="flex items-center justify-center gap-1" aria-label="Pagination">
              <!-- First Page -->
              <UButton
                :disabled="currentPage === 1"
                @click="goToPage(1)"
                size="sm"
                color="gray"
                variant="ghost"
                :ui="{ rounded: 'rounded-lg' }"
                class="hidden sm:flex"
              >
                <UIcon name="i-heroicons-chevron-double-left-20-solid" class="w-4 h-4" />
              </UButton>

              <!-- Previous -->
              <UButton
                :disabled="currentPage === 1"
                @click="goToPage(currentPage - 1)"
                size="sm"
                color="gray"
                variant="ghost"
                :ui="{ rounded: 'rounded-lg' }"
              >
                <UIcon name="i-heroicons-chevron-left-20-solid" class="w-4 h-4" />
                <span class="hidden sm:inline ml-1">Previous</span>
              </UButton>

              <!-- Page Numbers -->
              <div class="flex items-center gap-1">
                <!-- First page if not visible -->
                <template v-if="getVisiblePages()[0] > 1">
                  <UButton
                    @click="goToPage(1)"
                    size="sm"
                    color="gray"
                    variant="ghost"
                    :ui="{ rounded: 'rounded-lg' }"
                    class="w-9 justify-center"
                  >
                    1
                  </UButton>
                  <span v-if="getVisiblePages()[0] > 2" class="px-1 text-gray-400">...</span>
                </template>

                <!-- Visible page numbers -->
                <UButton
                  v-for="page in getVisiblePages()"
                  :key="page"
                  @click="goToPage(page)"
                  size="sm"
                  :color="page === currentPage ? 'primary' : 'gray'"
                  :variant="page === currentPage ? 'solid' : 'ghost'"
                  :ui="{ rounded: 'rounded-lg' }"
                  class="w-9 justify-center"
                >
                  {{ page }}
                </UButton>

                <!-- Last page if not visible -->
                <template v-if="getVisiblePages()[getVisiblePages().length - 1] < totalPages">
                  <span v-if="getVisiblePages()[getVisiblePages().length - 1] < totalPages - 1" class="px-1 text-gray-400">...</span>
                  <UButton
                    @click="goToPage(totalPages)"
                    size="sm"
                    color="gray"
                    variant="ghost"
                    :ui="{ rounded: 'rounded-lg' }"
                    class="w-9 justify-center"
                  >
                    {{ totalPages }}
                  </UButton>
                </template>
              </div>

              <!-- Next -->
              <UButton
                :disabled="currentPage === totalPages || totalPages === 0"
                @click="goToPage(currentPage + 1)"
                size="sm"
                color="gray"
                variant="ghost"
                :ui="{ rounded: 'rounded-lg' }"
              >
                <span class="hidden sm:inline mr-1">Next</span>
                <UIcon name="i-heroicons-chevron-right-20-solid" class="w-4 h-4" />
              </UButton>

              <!-- Last Page -->
              <UButton
                :disabled="currentPage === totalPages || totalPages === 0"
                @click="goToPage(totalPages)"
                size="sm"
                color="gray"
                variant="ghost"
                :ui="{ rounded: 'rounded-lg' }"
                class="hidden sm:flex"
              >
                <UIcon name="i-heroicons-chevron-double-right-20-solid" class="w-4 h-4" />
              </UButton>
            </nav>
          </div>

          <!-- Empty State -->
          <div v-else-if="!microGigs?.length" class="bg-white rounded-2xl shadow-sm border border-gray-100 py-16 text-center">
            <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
              <UIcon name="i-heroicons-briefcase" class="w-10 h-10 text-gray-300" />
            </div>
            <h3 class="text-lg font-semibold text-gray-900 mb-2">No Gigs Available</h3>
            <p class="text-gray-500 mb-6 max-w-sm mx-auto">There are no gigs available in this category right now. Check back later or try another category.</p>
            <UButton color="primary" @click="selectAllCategories">
              View All Categories
            </UButton>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const { t } = useI18n();
const { formatDate } = useUtils();
const isOpen = ref(false);
const { get, baseURL } = useApi();
const { user } = useAuth();
const services = ref([]);
const searchServices = ref([]);
const microGigs = ref([]);
const categoryArray = ref([]);
const selectedCategory = ref(null);
const title = ref(null);
const isLoading = ref(false);

// Pagination variables
const currentPage = ref(1);
const itemsPerPage = ref(10);
const selectedItemsPerPage = ref(10);
const itemsPerPageOptions = [10, 20, 30, 50];

// Computed properties for pagination
const totalGigs = computed(() => microGigs.value?.length || 0);
const totalPages = computed(() => Math.ceil(totalGigs.value / itemsPerPage.value) || 1);
const startIndex = computed(() => (currentPage.value - 1) * itemsPerPage.value);
const endIndex = computed(() =>
  Math.min(startIndex.value + itemsPerPage.value, totalGigs.value)
);

const paginatedGigs = computed(() => {
  return microGigs.value.slice(startIndex.value, endIndex.value);
});

// Function to go to specific page
function goToPage(page) {
  if (page < 1 || page > totalPages.value || page === currentPage.value) return;
  currentPage.value = page;
  // Scroll to top of gigs section
  document.getElementById("micro-gigs")?.scrollIntoView({ behavior: "smooth" });
}

// Helper function to get visible page numbers (show 5 pages max)
function getVisiblePages() {
  const pages = [];
  const total = totalPages.value;
  const current = currentPage.value;
  
  if (total <= 5) {
    // Show all pages if 5 or less
    for (let i = 1; i <= total; i++) {
      pages.push(i);
    }
  } else {
    // Smart pagination with ellipsis support
    let start = Math.max(1, current - 2);
    let end = Math.min(total, current + 2);
    
    // Adjust if at the beginning
    if (current <= 3) {
      start = 1;
      end = 5;
    }
    // Adjust if at the end
    if (current >= total - 2) {
      start = total - 4;
      end = total;
    }
    
    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
  }
  
  return pages;
}

// Handle items per page change
function handleItemsPerPageChange(value) {
  itemsPerPage.value = value;
  currentPage.value = 1; // Reset to first page
}

function resetPagination() {
  currentPage.value = 1;
}
const { data } = await get("/micro-gigs/");
microGigs.value = data;
const res = await get("/classified-categories/");
services.value = res.data;
const classifiedLatestPosts = ref([]);
const res2 = await get("/classified-posts/");
classifiedLatestPosts.value = res2.data;

const classifiedPosts = ref([]);
const toast = useToast();

const microGigsFilter = [
  { title: "All", value: "" },
  { title: "Available", value: "approved" },
  { title: "Completed", value: "completed" },
];

const microGigsStatus = ref(microGigsFilter[1]);

const errorIndex = ref([]);
function handleImageError(index) {
  if (!errorIndex.value.includes(index)) {
    errorIndex.value.push(index);
  }
}

// Progress bar color helpers
function getProgressColor(gig) {
  const progress = (gig.filled_quantity / gig.required_quantity) * 100;
  if (progress >= 100) return 'text-emerald-600';
  if (progress >= 70) return 'text-amber-600';
  return 'text-blue-600';
}

function getProgressBarColor(gig) {
  const progress = (gig.filled_quantity / gig.required_quantity) * 100;
  if (progress >= 100) return 'bg-emerald-500';
  if (progress >= 70) return 'bg-amber-500';
  return 'bg-blue-500';
}

async function getMicroGigsCategories() {
  const categoryCounts = microGigs.value.reduce((acc, gig) => {
    const category = gig.category_details.title;
    const id = gig.category_details.id;
    const isActiveAndApproved =
      gig.active_gig && gig.gig_status === "approved" && gig.user?.id;

    if (!acc[category]) {
      acc[category] = { total: 0, active: 0, id: id };
    }

    acc[category].total++;
    if (isActiveAndApproved) {
      acc[category].active++;
    }

    return acc;
  }, {});

  categoryArray.value = Object.entries(categoryCounts).map(
    ([category, { total, active, id }]) => ({
      category,
      total,
      active,
      id,
    })
  );
}

setTimeout(() => {
  getMicroGigsCategories();
}, 20);

async function getMicroGigsByAvailability(e) {
  resetPagination();
  if (e === "completed") {
    const { data, error } = await get(`/micro-gigs/?show_submitted=true`);
    microGigs.value = data;
  } else if (e === "approved") {
    const { data, error } = await get(`/micro-gigs/?show_submitted=false`);
    microGigs.value = data;
  } else {
    const { data, error } = await get(`/micro-gigs/`);
    microGigs.value = data;
  }
}

const selectCategory = async (category) => {
  selectedCategory.value = category || null;
  resetPagination();
  try {
    const { data, error } = await get(
      `/micro-gigs/?category=${category.id}&show_submitted=${false}`
    );
    microGigs.value = data;
  } catch (error) {
    console.error(error);
    toast.add({ title: "error" });
  }
};

const selectAllCategories = async () => {
  selectedCategory.value = null;
  resetPagination();
  try {
    const { data, error } = await get(`/micro-gigs/`);
    microGigs.value = data;
    getMicroGigsCategories();
  } catch (error) {
    console.error(error);
    toast.add({ title: "error" });
  }
};


async function handleSearch() {
  if (!title.value?.trim()) {
    toast.add({
      title: "Please enter a search term",
      color: "orange",
    });
    return;
  }

  isLoading.value = true;

  try {
    const [categoriesRes, postsRes] = await Promise.all([
      get(
        `/classified-categories/?title=${encodeURIComponent(
          title.value.trim()
        )}`
      ),
      get(`/classified-posts/?title=${encodeURIComponent(title.value.trim())}`),
    ]);

    services.value = categoriesRes.data;
    classifiedPosts.value = postsRes.data;
  } catch (error) {
    console.error("Search error:", error);
    toast.add({
      title: error?.message || "An error occurred while searching",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// watch(
//   () => (title.value ? title.value.trim() : ""),
//   async (newValue) => {
//     if (!newValue) {
//       isLoading.value = true;
//       try {
//         const res = await get("/classified-categories/");
//         services.value = res.data;
//         classifiedPosts.value = [];
//       } catch (error) {
//         console.error("Error fetching categories:", error);
//         toast.add({
//           title: "Failed to refresh categories",
//           color: "red",
//         });
//       } finally {
//         isLoading.value = false;
//       }
//     }
//   },
//   {
//     debounce: 300,
//     immediate: false,
//   }
// );
// Replace the existing watch function with this:
watch(
  () => title.value,
  async (newValue) => {
    // Don't trigger search if value is empty
    if (!newValue?.trim()) {
      isLoading.value = true;
      try {
        const res = await get("/classified-categories/");
        services.value = res.data;
        searchServices.value = [];
        classifiedPosts.value = [];
      } catch (error) {
        console.error("Error fetching categories:", error);
        toast.add({
          title: "Failed to refresh categories",
          color: "red",
        });
      } finally {
        isLoading.value = false;
      }
      return;
    }

    // Perform search
    isLoading.value = true;
    try {
      const [categoriesRes, postsRes] = await Promise.all([
        get(
          `/classified-categories/?title=${encodeURIComponent(newValue.trim())}`
        ),
        get(`/classified-posts/?title=${encodeURIComponent(newValue.trim())}`),
      ]);

      services.value = categoriesRes.data;
      searchServices.value = categoriesRes.data;
      classifiedPosts.value = postsRes.data;
    } catch (error) {
      console.error("Search error:", error);
      toast.add({
        title: error?.message || "An error occurred while searching",
        color: "red",
      });
    } finally {
      isLoading.value = false;
    }
  },
  {
    // Add debounce to prevent too many API calls while typing
    debounce: 500,
    // Don't run on component mount
    immediate: false,
  }
);

// You can now remove the handleSearch function and update the template:

const operators = ref([]);
const operatorsRes = await get("/mobile-recharge/operators/");

operators.value = operatorsRes.data;
</script>
