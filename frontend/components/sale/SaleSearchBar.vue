<template>
  <div class="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
    <CommonGeoSelector />
    <UContainer class="py-3">
      <div class="location-breadcrumb relative mb-3">
        <!-- Subtle background effect -->
        <div
          class="absolute inset-0 bg-gradient-to-r from-gray-50 to-primary-50 opacity-70 rounded-lg"
        ></div>

        <!-- Decorative map pin -->
        <div class="absolute -left-3 top-1/2 -translate-y-1/2 text-primary-400">
          <UIcon name="i-heroicons-map-pin" class="w-16 h-16" />
        </div>

        <div
          class="relative z-10 flex items-center justify-between px-3 pl-12 rounded-lg border border-primary-100"
        >
          <!-- Location path with icons -->
          <div class="location-breadcrumb relative my-3">
            <!-- Subtle background effect -->
            <div
              class="relative z-10 flex items-center justify-between p-1 rounded-lg border border-primary-100"
            >
              <!-- Location path with icons -->
              <div class="flex items-center flex-wrap location-path">
                <!-- Show country if allOverBangladesh is true or only country is set -->
                <div
                  v-if="
                    location?.allOverBangladesh ||
                    (location?.country && !location?.state)
                  "
                  class="location-segment flex items-center"
                  data-location="country"
                >
                  <UIcon
                    name="i-heroicons-globe-asia-australia"
                    class="text-primary-600 mr-1.5 animate-pulse-slow"
                  />
                  <span class="font-medium text-gray-800">{{
                    location?.country || "Bangladesh"
                  }}</span>
                  <span
                    v-if="location?.allOverBangladesh"
                    class="ml-2 text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full"
                  >
                    All over {{ location?.country || "Bangladesh" }}
                  </span>
                </div>

                <!-- Show state, city, upazila only if not allOverBangladesh -->
                <template v-if="!location?.allOverBangladesh">
                  <div
                    v-if="location?.state"
                    class="location-segment flex items-center"
                    data-location="state"
                  >
                    <UIcon
                      name="i-heroicons-map"
                      class="text-primary-600 mr-1.5 animate-pulse-slow"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.state
                    }}</span>
                    <UIcon
                      v-if="location?.city"
                      name="i-heroicons-chevron-right"
                      class="mx-1.5 text-gray-600"
                    />
                  </div>

                  <div
                    v-if="location?.city"
                    class="location-segment flex items-center"
                    data-location="city"
                  >
                    <UIcon
                      name="i-heroicons-building-office-2"
                      class="text-primary-600 mr-1.5 location-icon"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.city
                    }}</span>
                    <UIcon
                      v-if="location?.upazila"
                      name="i-heroicons-chevron-right"
                      class="mx-1.5 text-gray-600"
                    />
                  </div>

                  <div
                    v-if="location?.upazila"
                    class="location-segment flex items-center"
                    data-location="upazila"
                  >
                    <UIcon
                      name="i-heroicons-home-modern"
                      class="text-primary-600 mr-1.5 location-icon"
                    />
                    <span class="font-medium text-gray-800">{{
                      location?.upazila
                    }}</span>
                  </div>
                </template>
              </div>
            </div>
          </div>
          <UTooltip text="Change Location" class="me-auto">
            <UButton
              icon="i-heroicons-map-pin"
              size="md"
              color="primary"
              variant="ghost"
              trailing-icon="i-heroicons-pencil-square"
              class="edit-location-btn ml-2 relative"
              @click="handleClearLocation"
            >
              <span class="sr-only">Edit Location</span>
            </UButton>
          </UTooltip>
          <UButtonGroup
            size="md"
            class="flex-1 hidden md:flex md:w-2/4 relative"
          >
            <div class="relative flex-1">
              <UInput
                icon="i-heroicons-magnifying-glass-20-solid"
                size="md"
                color="white"
                :trailing="false"
                placeholder="Search..."
                v-model="searchTerm"
                @input="handleSearchInput"
                @keyup.enter="handleSearch"
                @keydown.down="handleKeyDown"
                @keydown.up="handleKeyUp"
                @keydown.escape="showDropdown = false"
                @focus="handleFocus"
                @blur="handleBlur"
                class="w-full"
                :ui="{
                  padding: {
                    md: 'sm:py-2.5',
                  },
                }"
              />

              <!-- Search Dropdown -->
              <div
                v-if="
                  showDropdown && (searchResults.length > 0 || isLoadingResults)
                "
                class="absolute top-full left-0 right-0 bg-white border border-gray-200 rounded-b-md shadow-lg z-50 max-h-80 overflow-y-auto search-dropdown"
              >
                <!-- Loading state -->
                <div v-if="isLoadingResults" class="p-4 text-center">
                  <UIcon
                    name="i-heroicons-arrow-path"
                    class="animate-spin h-5 w-5 mx-auto text-primary-500"
                  />
                  <p class="text-sm text-gray-600 mt-2">Searching...</p>
                </div>

                <!-- Search results -->
                <div v-else-if="searchResults.length > 0">
                  <div
                    v-for="(result, index) in searchResults"
                    :key="result.id"
                    @mousedown="selectResult(result)"
                    :class="[
                      'flex items-center p-3 cursor-pointer border-b border-gray-100 last:border-b-0 search-result-item transition-colors',
                      selectedIndex === index
                        ? 'bg-primary-50 border-primary-200'
                        : 'hover:bg-gray-50',
                    ]"
                  >
                    <div
                      class="flex-shrink-0 w-12 h-12 bg-gray-200 rounded-md mr-3"
                    >
                      <img
                        v-if="result.main_image"
                        :src="result.main_image"
                        :alt="result.title"
                        class="w-full h-full object-cover"
                      />
                      <div
                        v-else
                        class="w-full h-full flex items-center justify-center"
                      >
                        <UIcon
                          name="i-heroicons-photo"
                          class="h-5 w-5 text-gray-400"
                        />
                      </div>
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium text-gray-900 truncate">
                        {{ result.title }}
                      </p>
                      <p class="text-sm text-gray-500">
                        <span
                          v-if="result.price"
                          class="text-green-600 font-medium"
                          >৳{{ formatPrice(result.price) }}</span
                        >
                        <span v-else class="text-gray-600">Negotiable</span>
                        <span class="mx-1">•</span>
                        <span>{{ result.category_name || "General" }}</span>
                      </p>
                    </div>
                    <div class="flex-shrink-0">
                      <UIcon
                        name="i-heroicons-arrow-top-right-on-square"
                        class="h-4 w-4 text-gray-400"
                      />
                    </div>
                  </div>

                  <!-- See all results option -->
                  <div
                    @mousedown="handleSearch"
                    class="p-3 text-center bg-gray-50 hover:bg-gray-100 cursor-pointer border-t border-gray-200"
                  >
                    <p class="text-sm text-primary-600 font-medium">
                      See all results for "{{ searchTerm }}"
                    </p>
                  </div>
                </div>

                <!-- No results -->
                <div v-else class="p-4 text-center">
                  <p class="text-sm text-gray-600">No results found</p>
                </div>
              </div>
            </div>

            <UButton
              size="md"
              :loading="isSearching"
              variant="solid"
              :label="t('search')"
              @click="handleSearch"
              class="sm:h-10 max-sm:!text-base w-24 justify-center bg-primary-600 text-white hover:bg-primary-700 transition-colors duration-200 rounded-l-none"
              :ui="{
                padding: {
                  md: 'sm:py-2.5',
                },
              }"
            />
          </UButtonGroup>
        </div>
      </div>
      <UButtonGroup
        size="md"
        class="flex-1 flex md:hidden md:w-2/4 px-2 pb-2 relative"
      >
        <div class="relative flex-1">
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="md"
            color="white"
            :trailing="false"
            placeholder="Search..."
            v-model="searchTerm"
            @input="handleSearchInput"
            @keyup.enter="handleSearch"
            @keydown.down="handleKeyDown"
            @keydown.up="handleKeyUp"
            @keydown.escape="showDropdown = false"
            @focus="handleFocus"
            @blur="handleBlur"
            class="w-full"
            :ui="{
              padding: {
                md: 'sm:py-2.5',
              },
            }"
          />
          <!-- Mobile Search Dropdown -->
          <div
            v-if="
              showDropdown && (searchResults.length > 0 || isLoadingResults)
            "
            class="absolute top-full left-0 right-0 bg-white border border-gray-200 rounded-b-md shadow-lg z-50 max-h-60 overflow-y-auto search-dropdown"
          >
            <!-- Loading state -->
            <div v-if="isLoadingResults" class="p-3 text-center">
              <UIcon
                name="i-heroicons-arrow-path"
                class="animate-spin h-4 w-4 mx-auto text-primary-500"
              />
              <p class="text-xs text-gray-600 mt-1">Searching...</p>
            </div>

            <!-- Search results -->
            <div v-else-if="searchResults.length > 0">
              <div
                v-for="result in searchResults.slice(0, 5)"
                :key="result.id"
                @mousedown="selectResult(result)"
                class="flex items-center p-2 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0 search-result-item"
              >
                <div
                  class="flex-shrink-0 w-10 h-10 bg-gray-200 rounded-md mr-2"
                >
                  <img
                    v-if="result.main_image"
                    :src="result.main_image"
                    :alt="result.title"
                    class="w-full h-full object-cover"
                  />
                  <div
                    v-else
                    class="w-full h-full flex items-center justify-center"
                  >
                    <UIcon
                      name="i-heroicons-photo"
                      class="h-4 w-4 text-gray-400"
                    />
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-xs font-medium text-gray-900 truncate">
                    {{ result.title }}
                  </p>
                  <p class="text-xs text-gray-500">
                    <span v-if="result.price" class="text-green-600 font-medium"
                      >৳{{ formatPrice(result.price) }}</span
                    >
                    <span v-else class="text-gray-600">Negotiable</span>
                  </p>
                </div>
                <div class="flex-shrink-0">
                  <UIcon
                    name="i-heroicons-arrow-top-right-on-square"
                    class="h-3 w-3 text-gray-400"
                  />
                </div>
              </div>

              <!-- See all results option -->
              <div
                @mousedown="handleSearch"
                class="p-2 text-center bg-gray-50 hover:bg-gray-100 cursor-pointer border-t border-gray-200"
              >
                <p class="text-xs text-primary-600 font-medium">
                  See all results
                </p>
              </div>
            </div>
          </div>
        </div>

        <UButton
          size="md"
          :loading="isSearching"
          color="primary"
          variant="solid"
          icon="i-heroicons-magnifying-glass-20-solid"
          @click="handleSearch"
          class="sm:h-10 max-sm:!text-base w-12 justify-center rounded-l-none"
          :ui="{
            padding: {
              md: 'sm:py-2.5',
            },
          }"
        />
      </UButtonGroup>
    </UContainer>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from "vue";

// Define props
const props = defineProps({
  initialSearchTerm: {
    type: String,
    default: "",
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  showSearchResults: {
    type: Boolean,
    default: false, // Only true on sale index page
  },
});

// Define emits
const emit = defineEmits(["search", "clear-location", "navigate-to-post"]);

// Composables
const { location, clearLocation } = useLocation();
const { t } = useI18n();
const { get } = useApi();

// Reactive data
const searchTerm = ref(props.initialSearchTerm);
const showDropdown = ref(false);
const searchResults = ref([]);
const isLoadingResults = ref(false);
const searchTimeout = ref(null);
const selectedIndex = ref(-1);

// Watch for prop changes
watch(
  () => props.initialSearchTerm,
  (newValue) => {
    searchTerm.value = newValue;
  }
);

// Methods
const handleSearch = () => {
  // If an item is selected via keyboard, navigate to it
  if (selectedIndex.value >= 0 && searchResults.value[selectedIndex.value]) {
    selectResult(searchResults.value[selectedIndex.value]);
    return;
  }

  showDropdown.value = false;

  // Always emit search event when user explicitly searches (Enter key or search button)
  const searchQuery = searchTerm.value?.trim() || "";
  emit("search", searchQuery);
};

const handleClearLocation = () => {
  clearLocation();
  emit("clear-location");
};

const handleSearchInput = () => {
  // Clear previous timeout
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value);
  }

  // If search term is empty, hide dropdown and emit empty search only if on sale index page
  if (!searchTerm.value?.trim()) {
    showDropdown.value = false;
    searchResults.value = [];
    selectedIndex.value = -1;
    // Only emit empty search to reset the main listing on sale index page
    if (props.showSearchResults) {
      emit("search", "");
    }
    return;
  }

  // Set a timeout for debounced search
  searchTimeout.value = setTimeout(() => {
    // Only emit search to update main post list if on sale index page
    if (props.showSearchResults) {
      emit("search", searchTerm.value?.trim() || "");
    }

    // Always perform dropdown search for all pages
    performSearch();
  }, 300); // 300ms delay
};

const handleFocus = () => {
  // If there's already text in the input, perform dropdown search
  if (searchTerm.value?.trim()) {
    performSearch();
  }
};

const performSearch = async () => {
  if (!searchTerm.value?.trim()) {
    return;
  }

  isLoadingResults.value = true;

  try {
    const params = new URLSearchParams();
    params.append("q", searchTerm.value.trim());
    params.append("limit", "8"); // Limit results for dropdown

    // Add location filtering parameters if available
    if (location.value && !location.value.allOverBangladesh) {
      if (location.value.state) {
        params.append("division", location.value.state);
      }
      if (location.value.city) {
        params.append("district", location.value.city);
      }
      if (location.value.upazila) {
        params.append("area", location.value.upazila);
      }
    }

    const searchUrl = `/sale/posts/search/?${params.toString()}`;
    const response = await get(searchUrl);

    if (response?.data?.results) {
      searchResults.value = response.data.results.map((item) => ({
        id: item.id,
        title: item.title,
        slug: item.slug,
        price: item.price,
        negotiable: item.negotiable,
        main_image: item.main_image,
        category_name: item.category_name || "General",
        user_name: item.user_name,
        created_at: item.created_at,
      }));
      showDropdown.value = true;
      selectedIndex.value = -1;
    } else {
      searchResults.value = [];
      showDropdown.value = false;
    }
  } catch (error) {
    searchResults.value = [];
    showDropdown.value = false;
  } finally {
    isLoadingResults.value = false;
  }
};

const selectResult = (result) => {
  showDropdown.value = false;

  // Always navigate to the individual post when clicking on a result
  navigateTo(`/sale/${result.slug}`);
};

const handleBlur = () => {
  // Use nextTick to allow click events to fire before hiding dropdown
  nextTick(() => {
    setTimeout(() => {
      showDropdown.value = false;
    }, 150);
  });
};

const formatPrice = (price) => {
  if (!price) return "";
  return new Intl.NumberFormat("en-IN").format(price);
};

const handleKeyDown = (event) => {
  if (!showDropdown.value || searchResults.value.length === 0) return;

  event.preventDefault();
  selectedIndex.value = Math.min(
    selectedIndex.value + 1,
    searchResults.value.length - 1
  );
};

const handleKeyUp = (event) => {
  if (!showDropdown.value || searchResults.value.length === 0) return;

  event.preventDefault();
  selectedIndex.value = Math.max(selectedIndex.value - 1, -1);
};

// Close dropdown when clicking outside
const closeDropdown = () => {
  showDropdown.value = false;
  selectedIndex.value = -1;
};

// Watch for route changes to close dropdown
watch(
  () => useRoute().path,
  () => {
    showDropdown.value = false;
  }
);
</script>

<style scoped>
.location-icon {
  transition: transform 0.2s ease;
}

.location-segment:hover .location-icon {
  transform: scale(1.1);
}

.edit-location-btn {
  transition: all 0.2s ease;
}

.edit-location-btn:hover {
  transform: translateY(-1px);
}

/* Animation for pulse effect */
@keyframes pulse-slow {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Dropdown styling */
.search-dropdown {
  backdrop-filter: blur(8px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1),
    0 10px 10px -5px rgba(0, 0, 0, 0.04);
}

.search-result-item {
  transition: all 0.15s ease;
}

.search-result-item:hover {
  transform: translateY(-1px);
}
</style>
