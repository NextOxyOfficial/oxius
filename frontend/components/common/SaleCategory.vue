<template>
  <div id="sale-category" class="for-sale-section py-6 bg-white rounded-lg mt-3">
    <div class="container mx-auto px-1">
      <!-- Updated section header with linked buttons -->
      <div
        class="section-header sm:mb-8 mb-5 flex justify-between items-center"
      >
        <div class="flex items-center gap-3">
          <h2 class="text-xl md:text-xl font-medium text-gray-800">{{$t("sale_listing")}}</h2>
        </div>
        <div v-if="user" class="flex gap-2 sm:gap-3">
          <button
            class="my-post-btn border border-gray-300 hover:bg-gray-50 rounded-md px-2 py-1 sm:px-3 sm:py-1.5 text-sm sm:text-sm flex items-center gap-1"
            @click="openMyPostsModal"
          >
            <Icon name="heroicons:document-text" size="16px" />
            My Posts
          </button>
          <button
            class="my-post-btn border border-emerald-600 hover:bg-gray-50 rounded-md px-2 py-1 sm:px-3 sm:py-1.5 text-emerald-600 text-sm sm:text-sm flex items-center gap-1"
            @click="openPostSaleModal"
          >
            <Icon name="heroicons:plus-circle" size="16px" />
            Post a Sale
          </button>
        </div>
      </div>

      <!-- Dynamic banner ads with responsive layout -->
      <div class="banner-container mb-4 sm:mb-8">
        <div class="flex flex-col md:flex-row gap-2">
          <!-- Show loading placeholder when banners are loading -->
          <template v-if="isLoadingBanners">
            <div class="main-banner rounded-lg overflow-hidden md:w-1/2">
              <div
                class="w-full h-16 sm:h-20 md:h-32 bg-gray-200 animate-pulse"
              ></div>
            </div>
            <div class="secondary-banner rounded-lg overflow-hidden md:w-1/2">
              <div
                class="w-full h-16 sm:h-20 md:h-32 bg-gray-200 animate-pulse"
              ></div>
            </div>
          </template>

          <!-- Display banners when loaded -->
          <template v-else>
            <!-- Main banner -->
            <div
              v-if="banners.length > 0"
              class="main-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <NuxtLink
                :to="
                  `/sale/?category=${banners[0]?.category_details?.id}` || '#'
                "
                class="block"
              >
                <img
                  :src="getImageUrl(banners[0]?.image)"
                  :alt="banners[0]?.title || 'Promotion'"
                  class="w-full h-24 sm:h-20 md:h-32 object-contain"
                />
              </NuxtLink>
            </div>

            <!-- Secondary banner -->
            <div
              v-if="banners.length > 1"
              class="secondary-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <NuxtLink
                :to="
                  `/sale/?category=${banners[1]?.category_details?.id}` || '#'
                "
                class="block"
              >
                <img
                  :src="getImageUrl(banners[1]?.image)"
                  :alt="banners[1]?.title || 'Offer'"
                  class="w-full h-24 sm:h-20 md:h-32 object-contain"
                />
              </NuxtLink>
            </div>

            <!-- Fallback banners if API returns empty data -->
            <div
              v-if="banners.length === 0"
              class="main-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <img
                src="https://via.placeholder.com/1200x80/3B82F6/FFFFFF?text=Special+Promotion"
                alt="Promotion"
                class="w-full h-16 sm:h-20 md:h-32 object-contain"
              />
            </div>

            <div
              v-if="banners.length <= 1"
              class="secondary-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2"
            >
              <img
                src="https://via.placeholder.com/1200x80/4F46E5/FFFFFF?text=Limited+Time+Offer"
                alt="Offer"
                class="w-full h-16 sm:h-20 md:h-32 object-contain"
              />
            </div>
          </template>
        </div>
      </div>

      <div class="category-tabs relative mb-6">
        <!-- Navigation buttons (only visible on mobile) -->
        <button
          v-if="isMobile"
          @click="slideLeft"
          class="slider-nav-btn left-0 transition-opacity duration-300 opacity-25 hover:opacity-70"
          :class="{ 'cursor-not-allowed': isAtStart }"
          :disabled="isAtStart"
        >
          <Icon name="heroicons:chevron-left" size="18px" />
        </button>

        <!-- Categories slider with touch events -->
        <div
          class="overflow-hidden"
          ref="sliderContainer"
          @touchstart="handleTouchStart"
          @touchmove="handleTouchMove"
          @touchend="handleTouchEnd"
        >
          <div
            class="categories-wrapper flex transition-all duration-500 ease-out mt-3"
            :style="{ transform: `translateX(-${scrollPosition}px)` }"
            ref="categoriesWrapper"
          >
            <!-- Show category loading placeholders when categories are loading -->
            <template v-if="isLoadingCategories">
              <div
                v-for="index in 6"
                :key="`placeholder-${index}`"
                class="category-item flex-shrink-0"
                :class="[isMobile ? 'w-1/4' : 'w-1/6']"
              >
                <div
                  class="category-card transition-all duration-200 cursor-pointer h-full mx-1"
                >
                  <div class="flex items-center justify-center h-full">
                    <div class="text-center py-2">
                      <div
                        class="icon-container mx-auto mb-1 flex items-center justify-center bg-gray-200 rounded-full animate-pulse"
                      >
                        <div class="h-8 w-8"></div>
                      </div>
                      <div
                        class="h-4 bg-gray-200 rounded w-16 mx-auto animate-pulse"
                      ></div>
                    </div>
                  </div>
                </div>
              </div>
            </template>

            <!-- Show loaded categories -->
            <template v-else>
              <div
                v-for="category in categories"
                :key="category.id"
                class="category-item flex-shrink-0"
                :class="[isMobile ? 'w-1/4' : 'w-1/6']"
                @click="selectCategory(category)"
              >
                <div
                  class="category-card transition-all duration-200 cursor-pointer h-full mx-1"
                  :class="{
                    'category-active': selectedCategory === category.id,
                    'category-inactive': selectedCategory !== category.id,
                  }"
                >
                  <div class="flex items-center justify-center h-full">
                    <div class="text-center py-2">
                      <div
                        class="icon-container mx-auto mb-1 flex items-center justify-center"
                      >
                        <img
                          v-if="category.icon"
                          :src="getImageUrl(category.icon)"
                          :alt="category.name"
                          class="size-8 object-contain"
                        />
                        <Icon
                          v-else
                          :name="getCategoryIcon(category.name)"
                          size="22px"
                        />
                      </div>
                      <span class="category-name font-medium text-sm">{{
                        category.name
                      }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>

        <button
          v-if="isMobile"
          @click="slideRight"
          class="slider-nav-btn right-0 transition-opacity duration-300 opacity-25 hover:opacity-70"
          :class="{ 'cursor-not-allowed': isAtEnd }"
          :disabled="isAtEnd"
        >
          <Icon name="heroicons:chevron-right" size="18px" />
        </button>
      </div>

      <!-- Display section for selected category items with lazy loading -->
      <div class="selected-category-items mt-4" v-if="selectedCategory">
        <div class="flex justify-between items-center mb-3">
          <div>
            <h3 class="text-lg font-semibold">
              {{ getSelectedCategoryName() }}
            </h3>
          </div>
          <NuxtLink
            :to="`/sale`"
            class="my-post-btn border border-emerald-600 hover:bg-gray-50 rounded-md px-2 py-1 sm:px-3 sm:py-1.5 text-emerald-600 text-sm sm:text-sm flex items-center gap-1"
          >
            View All <Icon name="heroicons:arrow-right" size="14px" />
          </NuxtLink>
        </div>

        <!-- Lazy loading skeleton when loading -->
        <div v-if="isLoading" class="grid grid-cols-2 md:grid-cols-5 gap-2">
          <div
            v-for="i in isMobile ? 4 : 5"
            :key="i"
            class="item-card bg-white rounded-lg shadow-sm overflow-hidden border border-gray-100 animate-pulse"
          >
            <div class="h-32 bg-gray-200"></div>
            <div class="p-3">
              <div class="h-4 bg-gray-200 rounded mb-2"></div>
              <div class="h-3 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div class="flex justify-between items-center">
                <div class="h-5 bg-gray-200 rounded-full w-1/4"></div>
                <div class="h-6 w-6 rounded-full bg-gray-200"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Display actual posts from the database -->
        <div
          v-else-if="categoryPosts.length > 0"
          class="grid grid-cols-2 md:grid-cols-5 gap-2"
        >
          <NuxtLink
            v-for="post in categoryPosts"
            :key="post.id"
            :to="`/sale/${post.slug}`"
            class="item-card bg-white rounded-lg shadow-sm transition-shadow overflow-hidden border border-gray-100 flex flex-col h-full transform"
          >
            <div class="relative">
              <!-- Price overlay in top right -->
              <div class="absolute top-0 right-0 m-2 z-10">
                <div
                  class="px-2 py-1 bg-primary text-white text-sm font-semibold rounded shadow-sm"
                >
                  ৳{{ post.price?.toLocaleString() || "Negotiable" }}
                </div>
              </div>

              <!-- Status badges in top left -->
              <div class="absolute top-0 left-0 m-2 z-10">
                <span
                  v-if="post.featured"
                  class="bg-yellow-500 text-white text-xs px-2 py-0.5 rounded"
                  >Featured</span
                >
                <span
                  v-else-if="post.status === 'sold'"
                  class="bg-blue-500 text-white text-xs px-2 py-0.5 rounded"
                  >Sold</span
                >
              </div>

              <!-- Image with gradient overlay -->
              <div class="h-36 overflow-hidden relative">
                <div
                  class="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent z-0"
                ></div>
                <img
                  :src="post.main_image"
                  :alt="post.title"
                  class="w-full h-full object-contain transition-transform duration-300 hover:scale-105"
                  loading="lazy"
                />
              </div>
            </div>

            <div class="p-3 flex-grow flex flex-col">
              <!-- Title with truncation -->
              <h4 class="font-medium text-gray-800 line-clamp-1 text-sm">
                {{ post.title }}
              </h4>
              <!-- Address with location icon -->
              <div class="flex items-start mt-1 mb-2 text-xs text-gray-600">
                <Icon
                  name="heroicons:map-pin"
                  class="h-3 w-3 mr-1 mt-0.5 flex-shrink-0 text-gray-600"
                />
                {{
                  post?.division && post?.district && post?.area
                    ? `${post?.division}, ${post?.district}, ${post?.area}`
                    : `All Over Bangladesh`
                }}
              </div>

              <div class="mt-auto flex justify-between items-center pt-1">
                <!-- Condition tag -->
                <div
                  class="text-xs text-gray-600 bg-gray-100 px-2 py-0.5 rounded-full"
                >
                  {{ post.condition }}
                </div>

                <!-- Date or other secondary info -->
                <div class="text-xs text-gray-600 flex items-center">
                  <Icon
                    name="heroicons:clock"
                    class="h-3 w-3 mr-1 text-gray-600"
                  />
                  {{ formatDate(post.created_at) }}
                </div>
              </div>
            </div>
          </NuxtLink>
        </div>

        <!-- No posts found message -->
        <div
          v-else
          class="flex flex-col items-center justify-center py-8 px-4 bg-gray-50 rounded-lg"
        >
          <Icon
            name="heroicons:document-magnifying-glass"
            size="40px"
            class="text-gray-600 mb-2"
          />
          <h3 class="text-base font-medium text-gray-800 mb-1">
            No listings found
          </h3>
          <p class="text-gray-600 text-sm text-center">
            There are no items currently listed in this category.
          </p>
        </div>
      </div>
    </div>
  </div>

  <!-- Post Sale Modal -->
  <div
    v-if="showPostSaleModal"
    class="fixed inset-0 z-50 overflow-y-auto pt-16"
  >
    <!-- Added pt-16 for header spacing -->
    <div
      class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
    >
      <div class="fixed inset-0 transition-opacity" @click="closePostSaleModal">
        <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
      </div>

      <div
        v-if="user?.user"
        class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-3xl w-full"
      >
        <div class="bg-white px-2 pt-5 pb-4 sm:p-6 sm:pb-4">
          <div class="sm:flex sm:items-start">
            <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
              <div class="flex justify-between items-center border-b pb-3 mb-4">
                <h3 class="text-lg leading-6 font-medium text-gray-800">
                  Post a Sale
                </h3>
                <button
                  type="button"
                  class="text-gray-600 hover:text-gray-600"
                  @click="closePostSaleModal"
                >
                  <Icon name="heroicons:x-mark" size="24px" />
                </button>
              </div>
              <PostSale :categories="categories" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- My Posts Modal -->
  <Teleport to="body">
    <div
      v-if="showMyPostsModal"
      class="fixed inset-0 z-50 overflow-y-auto pt-14 md:pt-16"
    >
      <!-- Added pt-16 for header spacing -->
      <div
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 transition-opacity"
          @click="closeMyPostsModal"
        >
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div
          v-if="user?.user"
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full"
        >
          <div class="bg-white px-2 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <div
                  class="flex justify-between items-center border-b pb-3 mb-4"
                >
                  <h3 class="text-lg leading-6 font-medium text-gray-800">
                    My Posts
                  </h3>
                  <button
                    type="button"
                    class="text-gray-600 hover:text-gray-600"
                    @click="closeMyPostsModal"
                  >
                    <Icon name="heroicons:x-mark" size="24px" />
                  </button>
                </div>
                <MyPosts
                  @create-post="switchToPostSaleModal"
                  @edit-post="handleEditPost"
                  @delete-post="handleDeletePost"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import PostSale from "~/components/sale/PostSale.vue";
import MyPosts from "~/components/sale/MyPosts.vue";
const { user } = useAuth();

const { get } = useApi();

// State for categories and banners now from API
const categories = ref([]);
const banners = ref([]);
const selectedCategory = ref(null);
const scrollPosition = ref(0);
const sliderContainer = ref(null);
const categoriesWrapper = ref(null);
const isLoading = ref(false);
const isMobile = ref(false);

// Add loading states for initial data fetching
const isLoadingCategories = ref(true);
const isLoadingBanners = ref(true);

// Touch handling variables
const touchStartX = ref(0);
const touchEndX = ref(0);
const touchMoveX = ref(0);
const isHandlingTouch = ref(false);
const swipeThreshold = 8; // Minimum distance to start visual feedback
const minSwipeDistance = 50; // Minimum distance to trigger swipe action

const isAtStart = computed(() => scrollPosition.value <= 0);
const isAtEnd = computed(() => {
  if (!categoriesWrapper.value || !sliderContainer.value) return true;
  return (
    scrollPosition.value + sliderContainer.value.clientWidth >=
    categoriesWrapper.value.scrollWidth
  );
});

// Helper function to construct full image URL
const getImageUrl = (path) => {
  if (!path) return "";
  const { staticURL } = useApi();

  // If path already starts with http(s) or //, it's a full URL
  if (path.match(/^(https?:)?\/\//)) {
    return path;
  }

  // Otherwise prepend static URL
  return `${staticURL}${path}`;
};

// Get appropriate icon for a category based on its name
const getCategoryIcon = (categoryName) => {
  const iconMap = {
    Properties: "heroicons:home-modern",
    Vehicles: "heroicons:truck",
    Electronics: "heroicons:device-phone-mobile",
    Sports: "heroicons:trophy",
    B2B: "heroicons:building-office",
    Fashion: "heroicons:shopping-bag",
    Services: "heroicons:wrench",
    Jobs: "heroicons:briefcase",
    Pets: "heroicons:heart",
    Books: "heroicons:book-open",
    Furniture: "heroicons:table",
  };

  return iconMap[categoryName] || "heroicons:squares-plus"; // Default to 'squares-plus' for unknown categories
};

// Select a category with lazy loading simulation
const selectCategory = (category) => {
  if (selectedCategory.value === category.id) return;

  isLoading.value = true;
  selectedCategory.value = category.id;

  // Simulate API request delay - in a real app, you would fetch actual items for this category
  setTimeout(() => {
    isLoading.value = false;
  }, 800);
};

// Get the name of the selected category
const getSelectedCategoryName = () => {
  const found = categories.value.find(
    (cat) => cat.id === selectedCategory.value
  );
  return found ? found.name : "";
};

// Slide the categories left
const slideLeft = () => {
  if (scrollPosition.value <= 0) return;

  // On mobile, we show 4 categories at once
  const containerWidth = sliderContainer.value.clientWidth;

  // Calculate width of single item based on container width
  const itemWidth = isMobile.value
    ? containerWidth / 4 // Show 4 items on mobile
    : containerWidth / 6; // Show 6 items on desktop

  // Smooth scrolling by precisely calculating the scroll position
  // Using Math.ceil to ensure we always scroll to complete item boundaries
  const targetPosition = Math.max(0, scrollPosition.value - itemWidth * 2); // Scroll 2 items at once for better UX

  // Apply smooth transition
  if (categoriesWrapper.value) {
    categoriesWrapper.value.style.transition =
      "transform 500ms cubic-bezier(0.25, 0.1, 0.25, 1)";
  }

  scrollPosition.value = targetPosition;

  // Add animation feedback
  if (sliderContainer.value) {
    sliderContainer.value.classList.add("sliding");
    setTimeout(() => {
      sliderContainer.value.classList.remove("sliding");
    }, 500);
  }
};

// Slide the categories right
const slideRight = () => {
  if (!categoriesWrapper.value || !sliderContainer.value) return;

  const containerWidth = sliderContainer.value.clientWidth;
  const maxScroll = categoriesWrapper.value.scrollWidth - containerWidth;

  if (scrollPosition.value >= maxScroll) return;

  // Calculate width of single item based on container width
  const itemWidth = isMobile.value
    ? containerWidth / 4 // Show 4 items on mobile
    : containerWidth / 6; // Show 6 items on desktop

  // Smooth scrolling by precisely calculating the scroll position
  // Using Math.floor to ensure we always scroll to complete item boundaries
  const targetPosition = Math.min(
    maxScroll,
    scrollPosition.value + itemWidth * 2
  ); // Scroll 2 items at once for better UX

  // Apply smooth transition
  if (categoriesWrapper.value) {
    categoriesWrapper.value.style.transition =
      "transform 500ms cubic-bezier(0.25, 0.1, 0.25, 1)";
  }

  scrollPosition.value = targetPosition;

  // Add animation feedback
  if (sliderContainer.value) {
    sliderContainer.value.classList.add("sliding");
    setTimeout(() => {
      sliderContainer.value.classList.remove("sliding");
    }, 500);
  }
};

// Touch event handlers
const handleTouchStart = (e) => {
  isHandlingTouch.value = true;
  touchStartX.value = e.touches[0].clientX;
  touchEndX.value = touchStartX.value;

  // Remove any transition during drag for immediate response
  if (categoriesWrapper.value) {
    categoriesWrapper.value.style.transition = "none";
  }
};

const handleTouchMove = (e) => {
  if (!isHandlingTouch.value) return;

  touchMoveX.value = e.touches[0].clientX;
  const swipeDiff = touchMoveX.value - touchStartX.value;

  // Only prevent default if significant swipe detected to allow normal scrolling
  if (Math.abs(swipeDiff) > swipeThreshold) {
    e.preventDefault();

    // Don't allow further swiping if at the edges
    if (
      (swipeDiff > 0 && isAtStart.value) ||
      (swipeDiff < 0 && isAtEnd.value)
    ) {
      return;
    }

    // Real-time movement of the slider with finger
    const moveOffset = swipeDiff / 2; // Dampen the movement for better control

    if (categoriesWrapper.value) {
      const currentTransform = scrollPosition.value - moveOffset;
      categoriesWrapper.value.style.transform = `translateX(-${currentTransform}px)`;
    }

    // Visual feedback classes
    if (sliderContainer.value) {
      sliderContainer.value.classList.remove("swiping-left", "swiping-right");
      if (swipeDiff > 0) {
        sliderContainer.value.classList.add("swiping-right");
      } else {
        sliderContainer.value.classList.add("swiping-left");
      }
    }
  }
};

const handleTouchEnd = (e) => {
  if (!isHandlingTouch.value) return;

  touchEndX.value = e.changedTouches[0].clientX;

  // Reset the transition for smooth animation after touch
  if (categoriesWrapper.value) {
    categoriesWrapper.value.style.transition = "transform 500ms ease-out";
  }

  // Remove swiping classes
  if (sliderContainer.value) {
    sliderContainer.value.classList.remove("swiping-left", "swiping-right");
  }

  handleSwipe();
  isHandlingTouch.value = false;
};

const handleSwipe = () => {
  const distance = touchStartX.value - touchEndX.value;

  if (Math.abs(distance) < minSwipeDistance) {
    // If swipe was too small, snap back to original position
    if (categoriesWrapper.value) {
      categoriesWrapper.value.style.transform = `translateX(-${scrollPosition.value}px)`;
    }
    return;
  }

  if (distance > 0 && !isAtEnd.value) {
    // Swipe left (show more categories to the right)
    slideRight();
  } else if (distance < 0 && !isAtStart.value) {
    // Swipe right (show previous categories to the left)
    slideLeft();
  } else {
    // If at the edge, snap back to current position with animation
    if (categoriesWrapper.value) {
      categoriesWrapper.value.style.transform = `translateX(-${scrollPosition.value}px)`;
    }
  }
};

// Fetch categories from the backend
const fetchCategories = async () => {
  try {
    isLoadingCategories.value = true;
    // Update to the correct API endpoint
    const response = await get("/sale/categories/");
    console.log("API Response for categories:", response.data);
    if (response.data && Array.isArray(response.data)) {
      // This will place the most recently added categories at the end
      const sortedCategories = [...response.data].sort((a, b) => a.id - b.id);
      categories.value = sortedCategories;

      // Set initial category if available
      if (categories.value.length > 0) {
        selectedCategory.value = categories.value[0].id;
      }
    } else {
      // Fallback to default categories if API returns invalid data
      console.error("Invalid category data received from API");
    }
  } catch (error) {
    console.error("Error fetching sale categories:", error);
    // Fallback to default categories if API fails
  } finally {
    isLoadingCategories.value = false;
  }
};

// Fetch banners from the backend
const fetchBanners = async () => {
  try {
    isLoadingBanners.value = true;
    // Update to the correct API endpoint
    const response = await get("/sale/banners/");
    if (response.data && Array.isArray(response.data)) {
      banners.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching sale banners:", error);
    // Banners will remain an empty array if API fails
  } finally {
    isLoadingBanners.value = false;
  }
};

// Fetch posts for the selected category
const categoryPosts = ref([]);
const fetchCategoryPosts = async () => {
  if (!selectedCategory.value) return;

  try {
    isLoading.value = true;
    console.log("Fetching posts for category:", selectedCategory.value);

    // Update to the correct API endpoint
    const response = await get(
      `/sale/posts/?category=${selectedCategory.value}`
    );

    if (response.error) {
      console.error("Error response from API:", response.error);
      categoryPosts.value = [];
      return;
    }

    console.log("API response for category posts:", response.data);

    // Handle different API response formats
    if (response.data) {
      if (Array.isArray(response.data)) {
        // Direct array of posts
        categoryPosts.value = response.data;
      } else if (
        response.data.results &&
        Array.isArray(response.data.results)
      ) {
        // Paginated response
        categoryPosts.value = response.data.results;
      } else if (typeof response.data === "object") {
        // Single post object (unlikely but handling just in case)
        categoryPosts.value = [response.data];
      } else {
        console.warn("Unexpected API response format:", response.data);
        categoryPosts.value = [];
      }
    } else {
      categoryPosts.value = [];
    }

    console.log("Processed category posts:", categoryPosts.value);
  } catch (error) {
    console.error("Error fetching posts for category:", error);
    categoryPosts.value = [];
  } finally {
    isLoading.value = false;
  }
};

watch(selectedCategory, fetchCategoryPosts);

// Handle screen resize
const checkIfMobile = () => {
  isMobile.value = window.innerWidth < 768;

  // Reset scroll position when switching between mobile and desktop
  if (!isMobile.value) {
    scrollPosition.value = 0;
  }
};

// Initialize on mount
onMounted(async () => {
  // Fetch data from API
  await Promise.all([fetchCategories(), fetchBanners()]);

  // Check device type initially
  checkIfMobile();

  // Add proper event listeners for touch events with passive: false for better performance
  if (sliderContainer.value) {
    sliderContainer.value.addEventListener("touchstart", handleTouchStart, {
      passive: true,
    });
    sliderContainer.value.addEventListener("touchmove", handleTouchMove, {
      passive: false,
    });
    sliderContainer.value.addEventListener("touchend", handleTouchEnd, {
      passive: true,
    });
  }

  // Add resize event listener
  window.addEventListener("resize", checkIfMobile);
});

// Clean up event listeners
onUnmounted(() => {
  window.removeEventListener("resize", checkIfMobile);

  // Remove touch event listeners to prevent memory leaks
  if (sliderContainer.value) {
    sliderContainer.value.removeEventListener("touchstart", handleTouchStart);
    sliderContainer.value.removeEventListener("touchmove", handleTouchMove);
    sliderContainer.value.removeEventListener("touchend", handleTouchEnd);
  }
});

// Modal states
const showPostSaleModal = ref(false);
const showMyPostsModal = ref(false);

// Open modals for buttons
const openMyPostsModal = () => {
  showMyPostsModal.value = true;
  showPostSaleModal.value = false;
};

const closeMyPostsModal = () => {
  showMyPostsModal.value = false;
};

const openPostSaleModal = () => {
  showPostSaleModal.value = true;
  showMyPostsModal.value = false;
};

const closePostSaleModal = () => {
  showPostSaleModal.value = false;
};

const switchToPostSaleModal = () => {
  showMyPostsModal.value = false;
  showPostSaleModal.value = true;
};

// Post actions
const handleEditPost = (post) => {
  // Here you would implement edit functionality, possibly pre-filling the PostSale form
  console.log("Edit post:", post);
  // For now, just open the post sale modal
  openPostSaleModal();
};

const handleDeletePost = (postId) => {
  // Here you would implement delete functionality, possibly making an API call
  console.log("Delete post with ID:", postId);
  // In a real app, you would remove the post from the listings after successful deletion
};

// Helper function for formatting dates
const formatDate = (dateString) => {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString("en-US", { day: "numeric", month: "short" });
};
</script>

<style scoped>
.category-tabs {
  position: relative;
  width: calc(100% - 4px);
  margin: 0 auto;
}

.slider-nav-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background-color: white;
  border: 1px solid rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.12);
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.slider-nav-btn:hover {
  background-color: #f8f8f8;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-50%) scale(1.05);
}

.slider-nav-btn:active {
  transform: translateY(-50%) scale(0.98);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.category-card {
  border-bottom: 2px solid transparent;
  border-radius: 0;
  background-color: white;
}

.category-active {
  border-color: #3b82f6;
  background-color: rgb(249 250 251);
}

.category-inactive:hover {
  background-color: rgb(249 250 251);
}

.icon-container {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.categories-wrapper {
  touch-action: pan-x;
  will-change: transform; /* Optimize for animation performance */
}

/* Visual feedback classes for swipe direction */
.swiping-left {
  position: relative;
}
.swiping-left::after {
  content: "";
  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: 30px;
  background: linear-gradient(to left, rgba(59, 130, 246, 0.2), transparent);
  border-radius: 0 8px 8px 0;
  pointer-events: none;
}

.swiping-right {
  position: relative;
}
.swiping-right::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  width: 30px;
  background: linear-gradient(to right, rgba(59, 130, 246, 0.2), transparent);
  border-radius: 8px 0 0 8px;
  pointer-events: none;
}

/* Sliding animation class */
.sliding {
  position: relative;
}
.sliding::after {
  content: "";
  position: absolute;
  inset: 0;
  background-color: rgba(255, 255, 255, 0.1);
  pointer-events: none;
}

/* Animation for loading skeleton */
@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Responsive settings */
@media (min-width: 768px) {
  /* Desktop: show all 6 categories */
  .category-item {
    width: 16.666667%; /* 1/6 */
  }

  /* Hide navigation buttons on desktop as all categories are visible */
  .slider-nav-btn {
    display: none;
  }
}

@media (max-width: 767px) {
  /* Mobile: show 4 categories at once */
  .category-item {
    width: 25%; /* 1/4 */
  }

  /* Show navigation buttons on mobile */
  .slider-nav-btn {
    display: flex;
  }
}

/* Add extra small breakpoint for button labels */
@media (min-width: 480px) {
  .xs\:inline {
    display: inline;
  }
}

/* Banner styles */
.banner-container {
  width: 100%;
}
</style>
