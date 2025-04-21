<template>
  <div class="rounded-t-sm">
    <!-- Mobile Overlay (shows when sidebar is open on mobile) -->
    <div
      v-if="isMobile && cart.burgerMenu"
      class="fixed inset-0 bg-black/50 z-40 lg:hidden"
      @click="cart.toggleBurgerMenu()"
    ></div>

    <!-- Sidebar -->
    <aside
      :class="[
        'sm:max-h-screen fixed sm:static top-14 bottom-0 pb-16 sm:pb-0 z-50 flex flex-col bg-white border-r border-gray-200 transition-all duration-300 ease-in-out rounded-t-sm',
        isMobile
          ? cart.burgerMenu
            ? 'translate-x-0 w-72'
            : '-translate-x-full'
          : 'w-72',
        '',
      ]"
    >
      <!-- Sidebar Header -->
      <div
        class="h-12 mt-2flex items-center justify-between px-4 border-gray-100 relative"
      >
        <button
          v-if="cart.burgerMenu"
          class="fixed flex top-3 -right-10 lg:hidden h-8 w-8 items-center justify-center rounded-md bg-gray-200 text-gray-500"
          @click="cart.toggleBurgerMenu()"
        >
          <X class="h-5 w-5" />
        </button>
      </div>

      <!-- Sidebar Content (Scrollable) -->
      <div class="flex-1 overflow-y-auto py-4 px-2 space-y-7 -mt-12 sm:-mt-10">
        <!-- Main Menu Section -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center"
          >
            <Menu class="h-3.5 w-3.5 mr-1.5" />
            <span>Menu</span>
          </h3>
          <nav class="space-y-1">
            <NuxtLink
              v-for="item in mainMenu"
              :key="item.path"
              :href="item.path"
              :class="[
                'flex items-center px-3 py-2.5 rounded-md transition-colors group',
                item.active
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50',
              ]"
            >
              <component
                :is="item.icon"
                :class="[
                  'h-5 w-5 mr-3',
                  item.active
                    ? 'text-blue-600'
                    : 'text-gray-500 group-hover:text-gray-600',
                ]"
              />
              <span class="text-sm font-medium">{{ item.label }}</span>
              <div
                v-if="item.badge"
                class="ml-auto bg-blue-600 text-white text-xs rounded-full min-w-[20px] h-5 flex items-center justify-center px-1"
              >
                {{ item.badge }}
              </div>
            </NuxtLink>
          </nav>
        </div>

        <!-- Useful Links Section -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center"
          >
            <Link class="h-3.5 w-3.5 mr-1.5" />
            <span>Useful Links</span>
          </h3>
          <div class="grid grid-cols-2 gap-2 px-3">
            <NuxtLink
              v-for="item in usefulLinks"
              :key="item.path"
              :to="item.path"
              class="flex flex-col items-center justify-center p-3 rounded-md bg-gray-50 border border-gray-100 hover:bg-blue-50 hover:border-blue-100 transition-all shadow-sm"
            >
              <component :is="item.icon" class="h-5 w-5 mb-2 text-blue-600" />
              <span class="text-xs font-medium text-gray-700">{{
                item.label
              }}</span>
            </NuxtLink>
          </div>
        </div>

        <!-- Adsy News Section -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
          >
            <div class="flex items-center">
              <Newspaper class="h-3.5 w-3.5 mr-1.5" />
              <span>Adsy News</span>
            </div>
            <a
              href="/adsy-news"
              class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center"
              @click="handleNavigation('/adsy-news')"
            >
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </a>
          </h3>
          <div class="px-3 relative">
            <div
              v-if="isLoadingNews"
              class="flex justify-center items-center h-40 bg-gray-50 rounded-lg"
            >
              <div
                class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"
              ></div>
            </div>
            <div
              v-else
              class="overflow-hidden rounded-lg border border-gray-200 shadow-sm"
            >
              <div
                class="transition-transform duration-300 ease-in-out flex"
                :style="{
                  transform: `translateX(-${currentNewsIndex * 100}%)`,
                }"
                @mouseenter="pauseCarousel"
                @mouseleave="resumeCarousel"
              >
                <a
                  v-for="(news, index) in newsItems"
                  :key="index"
                  :href="`/adsy-news/${news.slug}/`"
                  class="w-full flex-shrink-0"
                  @click="handleNavigation(`/adsy-news/${news.slug}/`)"
                >
                  <div class="aspect-[16/9] w-full bg-gray-100 relative">
                    <img
                      :src="
                        news.post_media && news.post_media.length > 0
                          ? news.post_media[0].image
                          : '/static/frontend/images/placeholder.jpg'
                      "
                      :alt="news.title"
                      class="w-full h-full object-cover"
                    />
                    <div
                      class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent p-3"
                    >
                      <div class="flex items-center mb-1">
                        <span
                          class="text-xs font-medium text-white bg-blue-600 px-2 py-0.5 rounded-sm"
                          >News</span
                        >
                        <span
                          class="text-xs text-white/80 ml-2 flex items-center"
                        >
                          <Clock class="h-3 w-3 mr-1" />
                          {{ formatDate(news.created_at) }}
                        </span>
                      </div>
                      <h4 class="text-sm font-medium text-white line-clamp-2">
                        {{ news.title }}
                      </h4>
                    </div>
                  </div>
                </a>
              </div>
            </div>
            <!-- News Controls -->
            <div class="flex justify-between items-center mt-2">
              <div class="flex space-x-1">
                <button
                  v-for="(_, index) in newsItems"
                  :key="index"
                  @click="currentNewsIndex = index"
                  :class="[
                    'h-1.5 rounded-full transition-all',
                    currentNewsIndex === index
                      ? 'w-4 bg-blue-600'
                      : 'w-1.5 bg-gray-300',
                  ]"
                ></button>
              </div>
              <div class="flex space-x-1">
                <button
                  class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                  @click="prevNews"
                >
                  <ChevronLeft class="h-3 w-3" />
                </button>
                <button
                  class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                  @click="nextNews"
                >
                  <ChevronRight class="h-3 w-3" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Hashtags Section -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
          >
            <div class="flex items-center">
              <Hash class="h-3.5 w-3.5 mr-1.5" />
              <span>Trending Hashtags</span>
            </div>
            <a
              href="/hashtags"
              class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center"
              @click="handleNavigation('/hashtags')"
            >
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </a>
          </h3>
          <div class="flex flex-wrap gap-2 px-3">
            <a
              v-for="tag in hashtags"
              :key="tag.tag"
              :href="`/hashtag/${tag.tag}`"
              class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-blue-50 hover:text-blue-600 transition-colors"
              @click="handleNavigation(`/hashtag/${tag.tag}`)"
            >
              <span>#{{ tag.tag }}</span>
              <span class="ml-1 text-gray-500">{{ tag.count }}</span>
            </a>
          </div>
        </div>

        <!-- Products Slider -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
          >
            <div class="flex items-center">
              <ShoppingBag class="h-3.5 w-3.5 mr-1.5" />
              <span>Featured Products</span>
            </div>
            <div class="flex space-x-1">
              <button
                class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                @click="prevProduct"
              >
                <ChevronLeft class="h-3 w-3" />
              </button>
              <button
                class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                @click="nextProduct"
              >
                <ChevronRight class="h-3 w-3" />
              </button>
            </div>
          </h3>
          <div class="px-3 relative">
            <div
              v-if="isLoadingProducts"
              class="flex justify-center items-center h-40 bg-gray-50 rounded-lg"
            >
              <div
                class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"
              ></div>
            </div>
            <div
              v-else
              class="overflow-hidden rounded-lg border border-gray-200 shadow-sm"
            >
              <div
                class="transition-transform duration-300 ease-in-out flex"
                :style="{
                  transform: `translateX(-${currentProductIndex * 100}%)`,
                }"
              >
                <a
                  v-for="(product, index) in products"
                  :key="index"
                  :href="`/product-details/${product.slug}`"
                  class="w-full flex-shrink-0"
                  @click="handleNavigation(`/product-details/${product.slug}`)"
                >
                  <div class="aspect-video w-full bg-gray-100 relative">
                    <img
                      :src="getProductImage(product)"
                      :alt="product.name"
                      class="w-full h-full object-cover"
                    />
                    <div
                      class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent p-3"
                    >
                      <div class="flex items-center justify-between mb-1">
                        <span class="text-white text-xs font-bold"
                          >৳{{ product.sale_price }}</span
                        >
                        <span
                          v-if="
                            calculateDiscount(
                              product.sale_price,
                              product.regular_price
                            ) > 0
                          "
                          class="text-xs bg-red-500 text-white px-1.5 py-0.5 rounded-sm"
                          >{{
                            calculateDiscount(
                              product.sale_price,
                              product.regular_price
                            )
                          }}% OFF</span
                        >
                      </div>
                      <h4 class="text-white text-sm font-medium line-clamp-1">
                        {{ product.name }}
                      </h4>
                    </div>
                  </div>
                </a>
              </div>
            </div>
            <!-- Dots indicator -->
            <div class="flex justify-center mt-2 space-x-1">
              <button
                v-for="(_, index) in products"
                :key="index"
                @click="currentProductIndex = index"
                :class="[
                  'h-1.5 rounded-full transition-all',
                  currentProductIndex === index
                    ? 'w-4 bg-blue-600'
                    : 'w-1.5 bg-gray-300',
                ]"
              ></button>
            </div>
          </div>
        </div>

        <!-- Top Contributors -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
          >
            <div class="flex items-center">
              <Users class="h-3.5 w-3.5 mr-1.5" />
              <span>Top Contributors</span>
            </div>
            <a
              href="/contributors"
              class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center"
              @click="handleNavigation('/contributors')"
            >
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </a>
          </h3>
          <div class="space-y-2">
            <div
              v-if="isLoadingContributors"
              class="flex justify-center items-center h-20 bg-gray-50 rounded-lg"
            >
              <div
                class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"
              ></div>
            </div>
            <a
              v-else
              v-for="(user, index) in topContributors.slice(0, 2)"
              :key="index"
              :href="`/profile/${user.id}`"
              class="flex items-center px-3 py-2 rounded-md hover:bg-gray-50 transition-colors"
              @click="handleNavigation(`/profile/${user.id}`)"
            >
              <div class="relative">
                <img
                  :src="
                    user.avatar || '/static/frontend/images/placeholder.jpg'
                  "
                  :alt="user.name"
                  class="h-10 w-10 rounded-full object-cover border-2 border-white shadow-sm"
                />
                <div
                  class="absolute -top-1 -right-1 bg-blue-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center border border-white"
                >
                  {{ index + 1 }}
                </div>
              </div>
              <div class="ml-3 min-w-0">
                <h4 class="text-sm font-medium text-gray-800 truncate">
                  {{ user.name }}
                </h4>
                <p class="text-xs text-gray-500 flex items-center">
                  <FileText class="h-3 w-3 mr-1" />
                  <span>{{ user.posts }} posts</span>
                  <Users class="h-3 w-3 mx-1" />
                  <span>{{ user.followers }}</span>
                </p>
              </div>
              <div class="ml-auto">
                <div
                  class="text-xs px-1.5 py-0.5 bg-blue-50 text-blue-600 rounded-md border border-blue-100"
                >
                  <Trophy class="h-3 w-3" />
                </div>
              </div>
            </a>
          </div>
        </div>
      </div>
    </aside>
  </div>
</template>

<script setup>
import {
  Home,
  User,
  Bell,
  Settings,
  ShoppingBag,
  DollarSign,
  Store,
  Hash,
  ChevronLeft,
  ChevronRight,
  X,
  Menu,
  Newspaper,
  LogOut,
  Award,
  Zap,
  Smartphone,
  Clock,
  Link,
  Users,
  FileText,
  Trophy,
} from "lucide-vue-next";

// State
const isOpen = ref(false);
const isMobile = ref(false);
const currentProductIndex = ref(0);
const currentNewsIndex = ref(0);
const { user } = useAuth();
const { get } = useApi();
const logo = ref([]);
const cart = useStoreCart();

// Loading states
const isLoadingNews = ref(true);
const isLoadingProducts = ref(true);
const isLoadingContributors = ref(true);
let newsInterval = null;

async function getLogo() {
  try {
    const { data } = await get("/bn-logo/");
    logo.value = data;
  } catch (error) {
    console.error("Error fetching logo:", error);
  }
}

await getLogo();

// Main Menu Items
const mainMenu = [
  {
    label: "Recent",
    path: "/business-network/",
    icon: Home,
    active: true,
  },
  {
    label: "Profile",
    path: `/business-network/profile/${user.value?.user?.id}`,
    icon: User,
    active: false,
  },
  {
    label: "Notifications",
    path: "business-network/notifications",
    icon: Bell,
    badge: 5,
    active: false,
  },
  {
    label: "Settings",
    path: "/settings",
    icon: Settings,
    active: false,
  },
];

// Useful Links
const usefulLinks = [
  {
    label: "eShop",
    path: "/shop",
    icon: ShoppingBag,
  },
  {
    label: "Earn Money",
    path: "/#micro-gigs",
    icon: DollarSign,
  },
  {
    label: "Sell Products",
    path: "/shop-manager",
    icon: Store,
  },
  {
    label: "Mobile Recharge",
    path: "/mobile-recharge",
    icon: Smartphone,
  },
];

// News Items
const newsItems = ref([]);

async function fetchNewsItems() {
  isLoadingNews.value = true;
  try {
    // Fetch news posts from the API with a higher limit to allow random selection
    const response = await get("/news/posts/?limit=20");
    if (
      response.data &&
      response.data.results &&
      response.data.results.length > 0
    ) {
      // Get random 5 items from the results
      const allNews = response.data.results;
      const randomNews = [];

      // Get 5 random items or all items if less than 5
      const itemsToShow = Math.min(5, allNews.length);
      const usedIndices = new Set();

      while (randomNews.length < itemsToShow) {
        const randomIndex = Math.floor(Math.random() * allNews.length);
        if (!usedIndices.has(randomIndex)) {
          randomNews.push(allNews[randomIndex]);
          usedIndices.add(randomIndex);
        }
      }

      newsItems.value = randomNews;
    } else {
      console.warn("Unexpected news response format:", response.data);
      newsItems.value = [];
    }
  } catch (error) {
    console.error("Error fetching news:", error);
    newsItems.value = [];
  } finally {
    isLoadingNews.value = false;
  }
}

// Hashtags
const hashtags = ref([]);

async function fetchHashtags() {
  try {
    // Fetch trending hashtags from the news tags API
    const response = await get("/news/tags/?limit=10");
    if (response.data && response.data.results) {
      hashtags.value = response.data.results.map((tag) => ({
        tag: tag.tag,
        count: tag.posts_count || 0,
      }));
    } else {
      console.warn("Unexpected hashtags response format:", response.data);
      hashtags.value = [];
    }
  } catch (error) {
    console.error("Error fetching hashtags:", error);
    hashtags.value = [];
  }
}

// Products
const products = ref([]);

async function fetchProducts() {
  isLoadingProducts.value = true;
  try {
    // Fetch featured products from the eShop API with a higher limit to allow random selection
    const response = await get("/all-products/?limit=20&is_featured=true");

    let productList = [];
    if (
      response.data &&
      response.data.results &&
      response.data.results.length > 0
    ) {
      productList = response.data.results;
    } else if (Array.isArray(response.data) && response.data.length > 0) {
      productList = response.data;
    }

    // Get random 5 items or all items if less than 5
    if (productList.length > 0) {
      const randomProducts = [];
      const itemsToShow = Math.min(5, productList.length);
      const usedIndices = new Set();

      while (randomProducts.length < itemsToShow) {
        const randomIndex = Math.floor(Math.random() * productList.length);
        if (!usedIndices.has(randomIndex)) {
          randomProducts.push(productList[randomIndex]);
          usedIndices.add(randomIndex);
        }
      }

      products.value = randomProducts;
    } else {
      console.warn("No products found");
      products.value = [];
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    products.value = [];
  } finally {
    isLoadingProducts.value = false;
  }
}

// Top Contributors
const topContributors = ref([]);

async function fetchTopContributors() {
  isLoadingContributors.value = true;
  try {
    // Fetch top contributors - adjust the endpoint as needed
    const response = await get("/top-contributors/?limit=5");
    if (response.data) {
      topContributors.value = response.data.map((user) => ({
        id: user.id,
        name: user.first_name
          ? `${user.first_name} ${user.last_name || ""}`
          : user.username,
        avatar: user.profile_image,
        posts: user.post_count || 0,
        followers: user.follower_count || 0,
      }));
    } else {
      console.warn("Unexpected contributors response format:", response.data);
      // Fallback to dummy data if API is not available yet
      topContributors.value = [
        { id: 1, name: "John Doe", avatar: null, posts: 25, followers: 120 },
        { id: 2, name: "Jane Smith", avatar: null, posts: 18, followers: 85 },
      ];
    }
  } catch (error) {
    console.error("Error fetching contributors:", error);
    // Fallback to dummy data
    topContributors.value = [
      { id: 1, name: "John Doe", avatar: null, posts: 25, followers: 120 },
      { id: 2, name: "Jane Smith", avatar: null, posts: 18, followers: 85 },
    ];
  } finally {
    isLoadingContributors.value = false;
  }
}

// Methods
const toggleSidebar = () => {
  isOpen.value = !isOpen.value;

  // Prevent body scroll when sidebar is open on mobile
  if (isOpen.value && isMobile.value) {
    document.body.style.overflow = "hidden";
  } else {
    document.body.style.overflow = "";
  }
};

const handleNavigation = (path) => {
  // Close sidebar on mobile when navigating
  if (isMobile.value) {
    isOpen.value = false;
    document.body.style.overflow = "";
  }

  // In a real app, you would use router.push(path) here
  console.log(`Navigating to: ${path}`);
};

const nextProduct = () => {
  if (products.value.length === 0) return;
  currentProductIndex.value =
    (currentProductIndex.value + 1) % products.value.length;
};

const prevProduct = () => {
  if (products.value.length === 0) return;
  currentProductIndex.value =
    (currentProductIndex.value - 1 + products.value.length) %
    products.value.length;
};

const nextNews = () => {
  if (newsItems.value.length === 0) return;
  currentNewsIndex.value =
    (currentNewsIndex.value + 1) % newsItems.value.length;
};

const prevNews = () => {
  if (newsItems.value.length === 0) return;
  currentNewsIndex.value =
    (currentNewsIndex.value - 1 + newsItems.value.length) %
    newsItems.value.length;
};

const checkMobile = () => {
  isMobile.value = window.innerWidth < 1024; // lg breakpoint

  // Auto-close sidebar on mobile when resizing
  if (isMobile.value) {
    isOpen.value = false;
  }
};

// Format date for news items
const formatDate = (dateString) => {
  if (!dateString) return "";
  const options = { year: "numeric", month: "short", day: "numeric" };
  return new Date(dateString).toLocaleDateString(undefined, options);
};

// Get product image with fallback
const getProductImage = (product) => {
  if (!product) return "/static/frontend/images/placeholder.jpg";

  if (product.image_details) {
    if (
      Array.isArray(product.image_details) &&
      product.image_details.length > 0
    ) {
      return (
        product.image_details[0].image ||
        "/static/frontend/images/placeholder.jpg"
      );
    }
    if (typeof product.image_details === "string") {
      return product.image_details;
    }
  }

  if (
    product.images &&
    Array.isArray(product.images) &&
    product.images.length > 0
  ) {
    return product.images[0].image || "/static/frontend/images/placeholder.jpg";
  }

  if (product.image) {
    return product.image;
  }

  return "/static/frontend/images/placeholder.jpg";
};

// Calculate discount percentage
const calculateDiscount = (salePrice, regularPrice) => {
  if (!regularPrice || !salePrice) return 0;

  const sale =
    typeof salePrice === "string" ? parseFloat(salePrice) : salePrice;
  const regular =
    typeof regularPrice === "string" ? parseFloat(regularPrice) : regularPrice;

  if (regular <= sale) return 0;
  return Math.round(((regular - sale) / regular) * 100);
};

const pauseCarousel = () => {
  if (newsInterval) {
    clearInterval(newsInterval);
  }
};

const resumeCarousel = () => {
  pauseCarousel(); // Clear any existing interval first
  newsInterval = setInterval(() => {
    nextNews();
  }, 7000);
};

// Lifecycle hooks
onMounted(async () => {
  // Initial check for mobile
  checkMobile();

  // Add resize listener
  window.addEventListener("resize", checkMobile);

  // Fetch dynamic data
  await Promise.all([
    fetchNewsItems(),
    fetchHashtags(),
    fetchProducts(),
    fetchTopContributors(),
  ]);

  // Auto-rotate products every 5 seconds
  const productInterval = setInterval(() => {
    nextProduct();
  }, 5000);

  // Auto-rotate news every 7 seconds
  newsInterval = setInterval(() => {
    nextNews();
  }, 7000);

  // Cleanup
  onUnmounted(() => {
    window.removeEventListener("resize", checkMobile);
    clearInterval(productInterval);
    if (newsInterval) clearInterval(newsInterval);
  });
});
</script>

<style scoped>
/* Ensure smooth scrolling */
.overflow-y-auto {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.overflow-y-auto::-webkit-scrollbar {
  width: 4px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: transparent;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 20px;
}

/* Line clamp for text truncation */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
