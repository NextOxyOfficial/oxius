<template>
  <PublicSection id="micro-gigs">
    <UContainer>
      <h2 class="text-xl md:text-2xl mb-6 md:mb-6 text-center">
        {{ $t("micro_gigs") }} ({{ $t("quick_earn") }})
      </h2>
      <AccountBalance v-if="user" :user="user" :isUser="true" />
      <NuxtLink
        to="/mobile-recharge"
        class="mb-6 bg-gray-100 shadow-sm border border-gray-500 block py-2 px-4 max-w-fit mx-auto rounded-xl"
      >
        <div class="flex gap-2">
          <h2 class="text-base text-gray-800 sm:text-xl text-center">
            Mobile Recharge
          </h2>
          <div class="flex justify-center gap-2">
            <NuxtImg
              v-for="operator in operators"
              :key="operator.id"
              :src="operator.icon"
              :title="operator.title"
              class="size-6"
            />
          </div>
        </div>
      </NuxtLink>
      <UCard
        :ui="{
          body: { padding: 'p-0' },
          header: { padding: 'p-0' },
          rounded: 'rounded-md overflow-hidden',
          ring: 'max-sm:ring-0',
          shadow: '',
        }"
      >
        <div class="flex flex-col md:flex-row w-full">
          <div
            class="w-full md:w-60 bg-slate-50/70 border-dashed border max-sm:rounded-lg max-sm:overflow-hidden"
          >
            <ul class="py-2 text-center">
              <li>
                <p
                  class="px-2 font-semibold pb-2 text-left cursor-pointer"
                  @click.prevent="selectAllCategories"
                >
                  {{ $t("all_category") }}
                </p>
                <UDivider label="" class="mb-2 px-4" />
              </li>

              <li v-for="category in categoryArray" :key="category?.id">
                <UButton
                  :ui="{
                    rounded: '',
                  }"
                  size="md"
                  variant="ghost"
                  color="white"
                  class="w-full text-base px-4 py-0 font-normal text-blue-950 capitalize"
                  @click.prevent="selectCategory(category)"
                  >{{ category.category }} ({{ category.active }})
                </UButton>
              </li>
            </ul>
          </div>
          <div
            class="space-y-[0.5px] flex-1 max-sm:border max-sm:pt-2 max-sm:mt-4 max-sm:rounded-md min-h-40"
          >
            <div class="flex justify-between">
              <p class="px-2 font-semibold pb-3.5">
                {{ $t("available_gigs") }}
              </p>
              <USelectMenu
                color="white"
                size="sm"
                class="w-40"
                :options="microGigsFilter"
                v-model="microGigsStatus"
                @change="getMicroGigsByAvailability($event)"
                placeholder="Filter"
                value-attribute="value"
                option-attribute="title"
              />
            </div>
            <UCard
              v-for="(gig, i) in paginatedGigs"
              :key="i"
              :ui="{
                rounded: '',
                body: {
                  padding: 'p-0 sm:p-0 flex-1 w-full',
                },
                header: {
                  padding: 'p-0',
                },
                footer: {
                  padding: 'p-0',
                },
                ring: 'max-sm:ring-1',
              }"
              class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full bg-slate-50/70"
            >
              <div
                class="flex flex-col sm:flex-row sm:justify-between"
                v-if="gig.user"
              >
                <div class="flex gap-4">
                  <div>
                    <NuxtImg
                      v-if="!errorIndex.includes(i)"
                      :src="gig.category_details?.image"
                      class="w-12 rounded-full object-contain"
                    />
                    <img
                      v-else
                      src="/static/frontend/images/no-image.jpg"
                      alt="No Image"
                      class="w-12 rounded-full"
                    />
                  </div>
                  <div class="flex-1">
                    <h3
                      class="text-[15px] leading-tight font-semibold mb-1.5 capitalize"
                    >
                      {{ gig.title }}
                    </h3>
                    <div class="flex gap-0.5 gap-x-4 md:gap-4 flex-wrap">
                      <div class="flex gap-1 items-center">
                        <UIcon name="i-heroicons-bell-solid" />
                        <p class="text-sm">
                          <span class="">{{ gig.filled_quantity }}</span> /
                          <span class="text-green-600">{{
                            gig.required_quantity
                          }}</span>
                        </p>
                      </div>
                      <p class="text-sm">
                        {{ formatDate(gig.created_at) }}
                      </p>
                      <p
                        class="font-semibold text-base text-green-900 inline-flex items-center max-sm:ml-auto sm:hidden"
                      >
                        <UIcon name="i-mdi:currency-bdt" class="text-base" />{{
                          gig.price
                        }}
                      </p>
                      <div class="flex gap-1 items-center text-sm">
                        Posted By:
                        <p class="text-sm">
                          <span class="text-green-600"
                            >{{ gig.user.name.slice(0, 6) }}***</span
                          >
                        </p>
                      </div>
                      <UButton
                        v-if="user?.user && user?.user?.id !== gig.user.id"
                        :disabled="user?.user?.id === gig.user.id"
                        size="sm"
                        class="ml-auto sm:hidden w-[70px] justify-center"
                        color="primary"
                        variant="outline"
                        :to="`/order/${gig.slug}/`"
                      >
                        Earn
                      </UButton>
                      <UButton
                        v-if="user?.user?.id === gig.user.id"
                        :disabled="user?.user?.id === gig.user.id"
                        size="sm"
                        class="ml-auto sm:hidden w-[70px] justify-center"
                        color="primary"
                        variant="outline"
                      >
                        Ineligible
                      </UButton>
                      <UButton
                        v-if="!user?.user"
                        size="sm"
                        class="ml-auto sm:hidden w-[70px] justify-center"
                        color="primary"
                        variant="outline"
                        :to="`/auth/login/`"
                      >
                        Earn
                      </UButton>
                    </div>
                  </div>
                </div>
                <div
                  class="hidden sm:flex gap-16 items-center justify-end md:justify-between max-sm:mt-2"
                >
                  <p
                    class="font-semibold text-base text-green-900 sm:inline-flex items-center hidden"
                  >
                    <UIcon name="i-mdi:currency-bdt" class="text-base" />{{
                      gig.price
                    }}
                  </p>

                  <UButton
                    v-if="user?.user && user?.user?.id !== gig.user.id"
                    :disabled="user?.user?.id === gig.user.id"
                    size="sm"
                    color="primary"
                    variant="outline"
                    class="w-[70px] justify-center"
                    :to="`/order/${gig.slug}/`"
                  >
                    Earn
                  </UButton>
                  <UButton
                    v-if="user?.user?.id === gig.user.id"
                    :disabled="user?.user?.id === gig.user.id"
                    size="sm"
                    color="primary"
                    variant="outline"
                    class="w-[70px] justify-center"
                  >
                    Ineligible
                  </UButton>
                  <UButton
                    v-if="!user?.user"
                    size="sm"
                    color="primary"
                    variant="outline"
                    :to="`/auth/login/`"
                    class="w-[70px] justify-center"
                  >
                    Earn
                  </UButton>
                </div>
              </div>
            </UCard>
            <!-- Professional Pagination Section -->
            <div v-if="microGigs?.length > 0" class="mt-6 mb-4 px-4">
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
            <div v-else-if="!microGigs?.length" class="py-12 text-center">
              <UIcon name="i-heroicons-inbox" class="w-12 h-12 mx-auto text-gray-300 mb-4" />
              <p class="text-gray-500">No gigs found</p>
            </div>
          </div>
        </div>
      </UCard>
    </UContainer>
  </PublicSection>
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
    errorIndex.value.push(index); // Add index to errorIndex
  }
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
