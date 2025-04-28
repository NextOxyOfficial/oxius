<template>
  <div class="rounded-t-sm mt-16">
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
          <nav class="space-y-1" v-if="user?.user?.id">
            <NuxtLink
              v-for="item in mainMenu"
              :key="item.path"
              :to="item.path"
              @click="cart.toggleBurgerMenu()"
              :class="[
                'flex items-center px-3 py-2.5 rounded-md transition-colors group',
                item.path === route.path
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50',
              ]"
            >
              <component
                :is="item.icon"
                :class="[
                  'h-5 w-5 mr-3',
                  item.path === route.path
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
          <nav v-else>
            <NuxtLink
              v-for="(item, i) in mainMenu2"
              :key="i"
              :to="item.path"
              @click="cart.toggleBurgerMenu()"
              :class="[
                'flex items-center px-3 py-2.5 rounded-md transition-colors group',
                item.path === route.path
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50',
              ]"
            >
              <component
                :is="item.icon"
                :class="[
                  'h-5 w-5 mr-3',
                  item.path === route.path
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

        <!-- Workspaces Section -->
        <!-- <div class="bg-gray-100 p-4 rounded-lg shadow-md">
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center"
          >
            <Hash class="h-3.5 w-3.5 mr-1.5" />
            <span>Workspaces</span>
          </h3>
          <nav class="space-y-2">
            <button
              @click="isCreateWorkspaceModalOpen = true"
              class="flex items-center px-4 py-3 rounded-lg transition-colors group bg-blue-50 hover:bg-blue-100 text-blue-600"
            >
              <Plus
                class="h-5 w-5 mr-3 text-blue-500 group-hover:text-blue-600"
              />
              <span class="text-sm font-medium">Create Workspace</span>
            </button>
            <div
              v-if="workspaces?.length === 0"
              class="px-4 py-3 text-gray-500 text-center"
            >
              No workspaces available.
            </div>
            <NuxtLink
              v-for="workspace in workspaces"
              :key="workspace.id"
              :to="`/business-network/workspace/${workspace.id}`"
              class="flex items-center px-4 py-3 rounded-lg transition-colors group"
              :class="
                workspace.active
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-100'
              "
            >
              <span class="text-sm font-medium">#{{ workspace.name }}</span>
            </NuxtLink>
          </nav>
        </div> -->

        <!-- Create Workspace Modal -->
        <Teleport to="body">
          <div
            v-if="isCreateWorkspaceModalOpen"
            class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
            @click="isCreateWorkspaceModalOpen = false"
          >
            <div
              class="bg-white rounded-lg max-w-md w-full p-6 shadow-lg"
              @click.stop
            >
              <h3 class="text-lg font-semibold mb-4">Create Workspace</h3>
              <form @submit.prevent="createWorkspace">
                <div class="mb-4">
                  <label
                    for="workspaceName"
                    class="block text-sm font-medium text-gray-700 mb-1"
                  >
                    Workspace Name
                  </label>
                  <input
                    id="workspaceName"
                    v-model="newWorkspaceName"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-600"
                    placeholder="Enter workspace name"
                  />
                </div>
                <div class="flex justify-end space-x-2">
                  <button
                    type="button"
                    class="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                    @click="isCreateWorkspaceModalOpen = false"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                  >
                    Create
                  </button>
                </div>
              </form>
            </div>
          </div>
        </Teleport>

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
        <UButton
          label="Promote on ABN"
          variant="outline"
          block
          to="/business-network/abn-ads"
        />
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
              <span>See All</span>
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
                        news.image
                          ? news.image
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
            <div
              class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center"
            >
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </div>
          </h3>
          <div class="flex flex-wrap gap-2 px-3">
            <p
              v-for="tag in tags"
              :key="tag.id"
              class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-blue-50 hover:text-blue-600 transition-colors"
            >
              <span>#{{ tag.tag }}</span>
            </p>
          </div>
        </div>

        <!-- Products Slider -->
        <div>
          <h3
            class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
          >
            <div class="flex items-center">
              <ShoppingBag class="h-3.5 w-3.5 mr-1.5" />
              <span>Featured Product</span>
            </div>
            <div class="flex space-x-1">
              <button
                class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                @click="changeRandomProduct"
              >
                <RefreshCw class="h-3 w-3" />
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
              class="rounded-lg border border-gray-200 shadow-sm overflow-hidden"
            >
              <a
                v-if="displayProduct"
                :href="`/product-details/${displayProduct.slug}`"
                class="block w-full h-full"
                @click="
                  handleNavigation(`/product-details/${displayProduct.slug}`)
                "
              >
                <div class="aspect-video w-full bg-gray-100 relative">
                  <img
                    :src="getProductImage(displayProduct)"
                    :alt="displayProduct.name"
                    class="w-full h-full object-cover"
                  />
                  <div
                    class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent p-3"
                  >
                    <div class="flex items-center justify-between mb-1">
                      <span class="text-white text-xs font-bold"
                        >৳
                        {{
                          displayProduct.sale_price &&
                          parseFloat(displayProduct.sale_price) > 0
                            ? displayProduct.sale_price
                            : displayProduct.regular_price
                        }}
                      </span>
                      <span
                        v-if="
                          displayProduct.sale_price &&
                          parseFloat(displayProduct.sale_price) > 0 &&
                          displayProduct.regular_price &&
                          parseFloat(displayProduct.sale_price) <
                            parseFloat(displayProduct.regular_price)
                        "
                        class="text-xs bg-red-500 text-white px-1.5 py-0.5 rounded-sm"
                        >{{ calculateDiscount(displayProduct) }}% OFF</span
                      >
                    </div>
                    <h4 class="text-white text-sm font-medium line-clamp-1">
                      {{ displayProduct.name }}
                    </h4>
                  </div>
                </div>
              </a>
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
              :href="`/business-network/profile/${user.id}`"
              class="flex items-center px-3 py-2 rounded-md hover:bg-gray-50 transition-colors"
              @click="handleNavigation(`/business-network/profile/${user.id}`)"
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
  RefreshCw,
  Plus,
} from "lucide-vue-next";

// State
const isOpen = ref(false);
const isMobile = ref(false);
const currentProductIndex = ref(0);
const currentNewsIndex = ref(0);
const { user } = useAuth();
const { get, post } = useApi();
const logo = ref([]);
const cart = useStoreCart();
const route = useRoute();
console.log(route.path);
const tags = ref([]);
const displayProduct = ref(null);
const allProducts = ref([]); // Store all fetched products
const workspaces = ref([]); // Predefined workspaces with # prefix
const isCreateWorkspaceModalOpen = ref(false);
const newWorkspaceName = ref(""); // Store new workspace name

// Updated the toggleSidebar function to handle mobile screen issues and ensure proper state management.
const toggleSidebar = () => {
  isOpen.value = !isOpen.value;

  // Prevent body scroll when sidebar is open on mobile
  if (isOpen.value && isMobile.value) {
    document.body.style.overflow = "hidden";
  } else {
    document.body.style.overflow = "";
  }

  // Ensure cart.burgerMenu state syncs with isOpen
  if (isMobile.value) {
    cart.burgerMenu = isOpen.value;
  }
};

// Updated checkMobile function to auto-close sidebar properly on resize
const checkMobile = () => {
  isMobile.value = window.innerWidth < 1024; // lg breakpoint

  // Auto-close sidebar on mobile when resizing
  if (isMobile.value) {
    isOpen.value = false;
    cart.burgerMenu = false;
    document.body.style.overflow = "";
  }
};

// Loading states
const isLoadingNews = ref(true);
const isLoadingProducts = ref(true);
const isLoadingContributors = ref(true);
let newsInterval = null;

const toast = useToast(); // Initialize toast

async function getLogo() {
  try {
    const { data } = await get("/bn-logo/");
    logo.value = data;
  } catch (error) {
    console.error("Error fetching logo:", error);
  }
}

await getLogo();

async function getTags() {
  try {
    const response = await get("/bn/tags/");
    tags.value = response.data;
    console.log(tags.value);
  } catch (error) {
    console.log(error);
  }
}

await getTags();

// Main Menu Items
const mainMenu = [
  {
    label: "Recent",
    path: "/business-network",
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
    label: "MindForce",
    path: `/business-network/mindforce`,
    icon: Hash,
    active: false,
  },
  {
    label: "Notifications",
    path: "/business-network/notifications",
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

const mainMenu2 = [
  {
    label: "Recent",
    path: "/business-network",
    icon: Home,
    active: true,
  },
  {
    label: "Login",
    path: `/auth/login`,
    icon: User,
    active: false,
  },
];

// Useful Links
const usefulLinks = [
  {
    label: "eShop",
    path: "/eshop",
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

// Enhanced fetchNewsItems function to handle retries and validate API response
async function fetchNewsItems() {
  isLoadingNews.value = true;
  let retries = 3;

  while (retries > 0) {
    try {
      const response = await get("/news/posts/?limit=20");
      if (
        response.data &&
        Array.isArray(response.data.results) &&
        response.data.results.length > 0
      ) {
        const allNews = response.data.results;
        newsItems.value = allNews.slice(0, 5); // Limit to 5 items
        break;
      } else {
        console.warn("Unexpected news response format:", response.data);
        newsItems.value = [];
      }
    } catch (error) {
      console.error("Error fetching news:", error);
    }
    retries--;
    if (retries > 0) await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  isLoadingNews.value = false;
}

// Hashtags
const hashtags = ref([]);

async function fetchHashtags() {
  try {
    // Fetch trending hashtags from the news tags API
    const response = await get("/news/categories/?limit=10");
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

// Workspaces
async function fetchWorkspaces() {
  try {
    const response = await get("/bn/workspaces/");
    workspaces.value = response.data;
  } catch (error) {
    console.error("Error fetching workspaces:", error);
    workspaces.value = [];
  }
}

// Create Workspace
async function createWorkspace() {
  if (!newWorkspaceName.value.trim()) {
    toast.add({ title: "Workspace name cannot be empty" });
    return;
  }

  if (!user.value) {
    toast.add({ title: "Please login to create a workspace" });
    return;
  }

  try {
    const response = await post("/bn/workspaces/", {
      name: newWorkspaceName.value,
    });
    if (response.data) {
      await fetchWorkspaces();
      toast.add({ title: "Workspace created successfully!" });
      newWorkspaceName.value = "";
    }
  } catch (error) {
    console.log(error);
  }
}

// Products
async function fetchProducts() {
  isLoadingProducts.value = true;
  let retries = 3;

  while (retries > 0) {
    try {
      const response = await get("/all-products/?limit=20&is_featured=true");
      if (
        response.data &&
        Array.isArray(response.data.results) &&
        response.data.results.length > 0
      ) {
        allProducts.value = response.data.results;
        displayProduct.value = allProducts.value[0]; // Display the first product
        break;
      } else {
        console.warn("Unexpected products response format:", response.data);
        allProducts.value = [];
        displayProduct.value = null;
      }
    } catch (error) {
      console.error("Error fetching products:", error);
    }
    retries--;
    if (retries > 0) await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  isLoadingProducts.value = false;
}

// Add a function to display a new random product
const changeRandomProduct = () => {
  if (allProducts.value.length === 0) return;

  const currentIndex = allProducts.value.findIndex(
    (p) => p.id === displayProduct.value?.id
  );

  let newIndex;
  do {
    newIndex = Math.floor(Math.random() * allProducts.value.length);
  } while (newIndex === currentIndex && allProducts.value.length > 1);

  displayProduct.value = allProducts.value[newIndex];
};

// Calculate discount percent
const calculateDiscount = (product) => {
  if (!product.sale_price || !product.regular_price) return 0;

  const regular = parseFloat(product.regular_price);
  const sale = parseFloat(product.sale_price);

  if (regular <= 0 || sale <= 0) return 0;

  return Math.round(((regular - sale) / regular) * 100);
};

// Top Contributors
const topContributors = ref([]);

// Enhanced fetchTopContributors function to handle retries and validate API response
async function fetchTopContributors() {
  isLoadingContributors.value = true;
  let retries = 3;

  while (retries > 0) {
    try {
      const response = await get("/top-contributors/?limit=5");
      if (response.data && Array.isArray(response.data)) {
        topContributors.value = response.data.map((user) => ({
          id: user.id,
          name: user.first_name
            ? `${user.first_name} ${user.last_name || ""}`
            : user.username,
          avatar: user.profile_image,
          posts: user.post_count || 0,
          followers: user.follower_count || 0,
        }));
        break;
      } else {
        console.warn("Unexpected contributors response format:", response.data);
        topContributors.value = [];
      }
    } catch (error) {
      console.error("Error fetching contributors:", error);
    }
    retries--;
    if (retries > 0) await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  isLoadingContributors.value = false;
}

// Methods
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
    fetchWorkspaces(),
    fetchProducts(),
    fetchTopContributors(),
  ]);

  // Auto-change product every 10 seconds
  const productInterval = setInterval(() => {
    changeRandomProduct();
  }, 10000);

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
/* Hide scrollbars but maintain scrolling functionality */
.overflow-y-auto {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}

.overflow-y-auto::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
  width: 0;
}

/* Ensure the rest of your styles remain */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-clamp: 1; /* Standard property for compatibility */
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-clamp: 2; /* Standard property for compatibility */
}

/* Updated hover color for sidebar items */
nav a:hover {
  background-color: #e0f7fa; /* Light cyan hover color */
}

button:hover {
  background-color: #c4eef3; /* Light cyan hover color */
}
</style>
