<template>
  <div class="max-w-6xl mx-auto px-1 py-6">
    <!-- Seller Profile Header -->

    <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
      <div
        class="relative h-40 bg-gradient-to-r from-emerald-600 to-emerald-800"
      >
        <!-- Profile Actions -->
        <div class="absolute top-4 right-4 flex space-x-2">
          <button
            class="bg-white/90 hover:bg-white text-gray-700 px-3 py-1.5 rounded-md text-sm transition-colors duration-200 flex items-center"
            @click="handleShare"
          >
            <Share2 class="h-4 w-4 mr-1.5" />
            Share
          </button>
          <button
            class="bg-white/90 hover:bg-white text-gray-700 px-3 py-1.5 rounded-md text-sm transition-colors duration-200 flex items-center"
            @click="toggleReportDialog"
          >
            <Flag class="h-4 w-4 mr-1.5" />
            Report
          </button>
        </div>
      </div>

      <div class="px-6 pb-6 relative">        <!-- Profile Avatar -->
        <div
          class="relative -top-16 left-6 h-32 w-32 rounded-full border-4 border-white bg-white overflow-hidden group cursor-pointer"
          @click="openProfilePhotoModal"
        >
          <img
            :src="seller.image || '/static/frontend/avatar.png'"
            :alt="seller.name"
            class="h-full w-full object-contain"
          />

          <!-- Persistent camera icon -->
          <div class="absolute bottom-0 right-0 z-20">
            <button
              @click="toggleProfilePhotoMenu"
              class="bg-white rounded-full p-2 shadow-sm hover:shadow-sm transition-all duration-300"
              ref="cameraButtonRef"
            >
              <UIcon
                name="i-heroicons-camera"
                class="size-5 text-emerald-600"
              />
            </button>

            <!-- Menu with options -->
            <div
              v-if="showProfilePhotoMenu"
              class="absolute bottom-12 right-0 bg-white rounded-md shadow-sm p-2 w-40 border border-gray-200 z-30"
              ref="profilePhotoMenuRef"
            >
              <div class="flex flex-col space-y-1">
                <button
                  @click="navigateToSettings"
                  class="flex items-center space-x-2 px-3 py-2 hover:bg-gray-100 rounded-md text-sm text-gray-700 transition-colors"
                >
                  <UIcon
                    name="i-heroicons-pencil-square"
                    class="size-4 text-emerald-600"
                  />
                  <span>Change Photo</span>
                </button>
                <button
                  @click="openProfilePhotoModal"
                  class="flex items-center space-x-2 px-3 py-2 hover:bg-gray-100 rounded-md text-sm text-gray-700 transition-colors"
                >
                  <UIcon
                    name="i-heroicons-eye"
                    class="size-4 text-emerald-600"
                  />
                  <span>View Photo</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Profile Info -->
        <div
          class="flex flex-col md:flex-row md:items-end justify-between"
        >
          <div>
            <div class="flex items-center">
              <h1 class="text-2xl font-bold text-gray-800">
                {{ seller.name }}
              </h1>
              <div
                class="ml-3 bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded text-sm font-medium flex items-center"
                v-if="seller.kyc"
              >
                <CheckCircle class="h-3 w-3 mr-1" />
                Verified Seller
              </div>
            </div>
            <p class="text-gray-500 text-sm mt-1">
              Member since {{ formatDate(seller.date_joined) }}
            </p>

            <div class="flex items-center mt-3 space-x-4">
              <div class="flex items-center">
                <Tag class="h-4 w-4 text-emerald-600 mr-1.5" />
                <span class="text-sm text-gray-600"
                  >{{ seller.sale_post_count }} Listings</span
                >
              </div>
              <div class="flex items-center">
                <MapPin class="h-4 w-4 text-emerald-600 mr-1.5" />
                <span class="text-sm text-gray-600">{{ seller.address }}</span>
              </div>
            </div>
          </div>

          <div class="mt-4 md:mt-0">
            <button
              class="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-md text-sm transition-colors duration-200"
            >
              Contact Seller
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Seller Details Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
      <!-- About & Contact - 1 column on large screens -->
      <div class="lg:col-span-1 space-y-6">
        <!-- About Section -->
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div class="p-5">
            <h2 class="text-lg font-bold text-gray-800 flex items-center mb-4">
              <User class="h-5 w-5 mr-2 text-emerald-600" />
              About
            </h2>
            <p class="text-gray-600 text-sm">
              {{ seller?.about }}
            </p>
          </div>
        </div>

        <!-- Contact Information -->
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div class="p-5">
            <h2 class="text-lg font-bold text-gray-800 flex items-center mb-4">
              <Phone class="h-5 w-5 mr-2 text-emerald-600" />
              Contact Information
            </h2>

            <div class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Phone</span>
                <div class="flex items-center">
                  <span class="font-medium text-sm text-gray-800 mr-2">
                    {{
                      showPhone ? seller.phone : maskPhoneNumber(seller.phone)
                    }}
                  </span>
                  <button
                    class="text-emerald-600 hover:text-emerald-700"
                    @click="toggleShowPhone"
                  >
                    <component :is="showPhone ? EyeOff : Eye" class="h-4 w-4" />
                  </button>
                </div>
              </div>

              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Email</span>
                <span class="font-medium text-sm text-gray-800">{{
                  seller.email
                }}</span>
              </div>

              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Location</span>
                <span class="font-medium text-sm text-gray-800">{{
                  seller.address
                }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Seller Products - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div class="py-5 px-1 sm:px-4">
            <div class="flex-block items-center justify-between mb-4">
              <h2 class="text-lg mb-4 font-bold text-gray-800 flex items-center">
                <ShoppingBag class="h-5 w-5 mr-2 text-emerald-600" />
                {{ seller.name }}'s Listings ({{ seller.sale_post_count }})
              </h2>

              <div class="flex items-center justify-center space-x-2">
                <select
                  v-model="sortOption"
                  class="text-sm border border-gray-200 rounded-md px-2 py-1.5 text-gray-600 bg-white"
                >
                  <option value="recent">Most Recent</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="popular">Most Popular</option>
                </select>

                <div
                  class="flex border border-gray-200 rounded-md overflow-hidden"
                >
                  <button
                    :class="`px-3 py-3 ${
                      viewMode === 'grid'
                        ? 'bg-emerald-50 text-emerald-600'
                        : 'bg-white text-gray-600 hover:bg-gray-50'
                    } border-r border-gray-200`"
                    @click="viewMode = 'grid'"
                  >
                    <LayoutGrid class="h-4 w-4" />
                  </button>
                  <button
                    :class="`px-3 py-3 ${
                      viewMode === 'list'
                        ? 'bg-emerald-50 text-emerald-600'
                        : 'bg-white text-gray-600 hover:bg-gray-50'
                    }`"
                    @click="viewMode = 'list'"
                  >
                    <List class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>

            <!-- Filter Bar -->
            <div
              class="flex flex-wrap items-center gap-2 mb-4 pb-4 border-b border-gray-100"
            >
              <span class="text-sm text-gray-600">Filter by:</span>

              <select
                v-model="categoryFilter"
                class="text-sm border border-gray-200 rounded-md px-2 py-1 text-gray-600 bg-white"
              >
                <option value="">All Categories</option>
                <option
                  v-for="category in categories"
                  :key="category.id"
                  :value="category?.name"
                >
                  {{ category?.name }}
                </option>
              </select>

              <select
                v-model="conditionFilter"
                class="text-sm border border-gray-200 rounded-md px-2 py-1 text-gray-600 bg-white"
              >
                <option value="">All Conditions</option>
                <option
                  v-for="condition in conditions"
                  :value="condition.value"
                  :key="condition.id"
                >
                  {{ condition.name }}
                </option>
              </select>

              <button
                class="ml-1 text-sm text-emerald-600 hover:text-emerald-700"
                @click="clearFilters"
              >
                Clear All Filters
              </button>
            </div>

            <!-- Grid View -->
            <div v-if="viewMode === 'grid'" class="grid grid-cols-2 gap-2">
              <div
                v-for="product in products"
                :key="product.id"
                class="bg-white rounded-lg overflow-hidden"
              >                <div class="relative aspect-video">
                  <NuxtLink :to="`/sale/${product.slug}`">
                    <img
                      :src="product.main_image"
                      :alt="product.title"
                      class="absolute inset-0 w-full h-full object-contain"
                    />
                  </NuxtLink>
                </div><div class="p-4">
                  <h3 class="font-semibold text-gray-800 mb-1 line-clamp-2">
                    <NuxtLink :to="`/sale/${product.slug}`" class="hover:text-emerald-600 transition-colors">
                      {{ product.title }}
                    </NuxtLink>
                  </h3>

                  <div class="flex items-center justify-between mt-2">
                    <span class="font-bold text-emerald-700"
                      >${{ product.price.toLocaleString() }}</span
                    >
                    <span class="text-sm text-gray-500">{{
                      formatDate(product.created_at)
                    }}</span>
                  </div>

                  <div class="flex items-center mt-3 text-sm text-gray-500">
                    <Tag class="h-3 w-3 mr-1" />
                    <span>{{ product.category_name }}</span>
                    <span class="mx-2">•</span>
                    <MapPin class="h-3 w-3 mr-1" />
                    <span>{{
                      product?.division && product?.district && product?.area
                        ? `${product?.division}, ${product?.district}, ${product?.area}`
                        : `All Over Bagnladesh`
                    }}</span>
                  </div>                  <div
                    class="flex justify-between items-center mt-3 pt-3 border-t border-gray-100"
                  >
                    <NuxtLink
                      :to="`/sale/${product.slug}`"
                      class="text-emerald-600 hover:text-emerald-700 text-sm flex items-center"
                    >
                      View Details
                      <ChevronRight class="h-3 w-3 ml-1" />
                    </NuxtLink>
                  </div>
                </div>
              </div>
            </div>

            <!-- List View -->
            <div v-else class="space-y-4">
              <div
                v-for="product in products"
                :key="product.id"
                class="flex flex-col sm:flex-row bg-white rounded-lg overflow-hidden"
              >
                <div class="relative sm:w-1/3 aspect-video sm:aspect-none">
                  <img
                    :src="product.main_image || '/static/frontend/avatar.png'"
                    :alt="product.title"
                    class="absolute inset-0 w-full h-full object-contain"
                  />
                </div>

                <div class="p-4 sm:w-2/3 flex flex-col">                  <h3 class="font-semibold text-gray-800 mb-1">
                    <NuxtLink :to="`/sale/${product.slug}`" class="hover:text-emerald-600 transition-colors">
                      {{ product.title }}
                    </NuxtLink>
                  </h3>

                  <div class="flex items-center justify-between mt-2">
                    <span class="font-bold text-emerald-700"
                      >${{ product.price.toLocaleString() }}</span
                    >
                    <span class="text-sm text-gray-500">{{
                      formatDate(product.created_at)
                    }}</span>
                  </div>

                  <div class="flex items-center mt-3 text-sm text-gray-500">
                    <Tag class="h-3 w-3 mr-1" />
                    <span>{{ product.category }}</span>
                    <span class="mx-2">•</span>
                    <MapPin class="h-3 w-3 mr-1" />
                    <span>{{
                      product?.division && product?.district && product?.area
                        ? `${product?.division}, ${product?.district}, ${product?.area}`
                        : `All Over Bagnladesh`
                    }}</span>
                  </div>

                  <p class="text-sm text-gray-600 mt-2 line-clamp-2">
                    {{ product.description || "No description available." }}
                  </p>

                  <div
                    class="flex justify-between items-center mt-auto pt-3 border-t border-gray-100"
                  >
                    <button
                      class="text-emerald-600 hover:text-emerald-700 text-sm flex items-center"
                    >
                      View Details
                      <ChevronRight class="h-3 w-3 ml-1" />
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Empty State -->
            <div v-if="products?.length === 0" class="py-8 text-center">
              <div
                class="mx-auto w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4"
              >
                <SearchX class="h-8 w-8 text-gray-400" />
              </div>
              <h3 class="text-gray-700 font-medium mb-1">No listings found</h3>
              <p class="text-gray-500 text-sm">
                Try adjusting your filters or check back later
              </p>
              <button
                class="mt-4 text-emerald-600 hover:text-emerald-700 text-sm"
                @click="clearFilters"
              >
                Clear all filters
              </button>
            </div>

            <!-- Pagination -->
            <div
              class="flex items-center justify-between mt-6 pt-4 border-t border-gray-100"
            >
              <button
                class="flex items-center text-sm text-gray-600 hover:text-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed"
                :disabled="currentPage === 1"
                @click="prevPage"
              >
                <ChevronLeft class="h-4 w-4 mr-1" />
                Previous
              </button>

              <div class="flex items-center space-x-1">
                <button
                  v-for="page in pages"
                  :key="page"
                  :class="`h-8 w-8 rounded-md flex items-center justify-center text-sm ${
                    currentPage === page
                      ? 'bg-emerald-600 text-white'
                      : 'hover:bg-gray-100 text-gray-600'
                  }`"
                  @click="goToPage(page)"
                >
                  {{ page }}
                </button>
              </div>

              <button
                class="flex items-center text-sm text-gray-600 hover:text-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed"
                :disabled="
                  pages?.length === 0 ? true : currentPage === pages?.length
                "
                @click="nextPage"
              >
                Next
                <ChevronRight class="h-4 w-4 ml-1" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Report Dialog -->
    <div
      v-if="showReportDialog"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeReportDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Report Seller</h3>
          <button
            @click="closeReportDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5">
          <p class="text-sm text-gray-600 mb-4">
            Please select a reason for reporting this seller:
          </p>

          <div class="space-y-2">
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="fake"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-700"
                >Fake or misleading listings</span
              >
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="prohibited"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-700"
                >Selling prohibited items</span
              >
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="offensive"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-700">Offensive content</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="scam"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-700">Scam or fraud</span>
            </label>
            <label class="flex items-center space-x-2 cursor-pointer">
              <input
                type="radio"
                v-model="reportReason"
                value="other"
                class="text-emerald-600"
              />
              <span class="text-sm text-gray-700">Other</span>
            </label>
          </div>

          <textarea
            v-if="reportReason === 'other'"
            v-model="reportDetails"
            placeholder="Please provide details about your report..."
            class="mt-4 w-full border border-gray-200 rounded-md p-2 text-sm text-gray-700 h-24 resize-none focus:outline-none focus:ring-1 focus:ring-emerald-500"
          ></textarea>

          <div class="mt-6 flex justify-end space-x-3">
            <button
              class="px-4 py-2 border border-gray-200 rounded-md text-sm text-gray-600 hover:bg-gray-50"
              @click="closeReportDialog"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="submitReport"
            >
              Submit Report
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Share Dialog -->
    <div
      v-if="showShareDialog"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeShareDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Share this profile</h3>
          <button
            @click="closeShareDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5">
          <div class="flex items-center space-x-2">
            <div class="flex-1">
              <div
                class="flex items-center justify-between rounded-md border border-gray-200 px-3 py-2"
              >
                <span class="text-sm truncate text-gray-600">{{
                  shareUrl
                }}</span>
              </div>
            </div>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-sm transition-colors duration-200"
              @click="copyToClipboard"
            >
              Copy
            </button>
          </div>

          <div class="mt-5">
            <h4 class="text-sm font-medium mb-3 text-gray-700">Share via</h4>
            <div class="grid grid-cols-2 gap-3">
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('facebook')"
              >
                <span
                  class="w-5 h-5 bg-blue-600 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >f</span
                >
                Facebook
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('twitter')"
              >
                <span
                  class="w-5 h-5 bg-sky-500 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >t</span
                >
                Twitter
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('whatsapp')"
              >
                <span
                  class="w-5 h-5 bg-green-500 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >w</span
                >
                WhatsApp
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('email')"
              >
                <span
                  class="w-5 h-5 bg-gray-700 text-white rounded flex items-center justify-center mr-2 text-sm"
                  >@</span
                >
                Email
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>    <!-- Profile Photo Modal -->
    <MediaViewer
      v-if="showProfilePhotoModal"
      :activeMedia="profilePhotoMedia"
      :user="user"
      :profileMode="true"
      :profileUser="seller"
      @close-media="showProfilePhotoModal = false"
    />
      :profileMode="true"
      :profileUser="seller"
      @close-media="showProfilePhotoModal = false"
    />
  </div>
</template>

<script setup>
import { ref, reactive, computed } from "vue";
import MediaViewer from "~/components/business-network/MediaViewer.vue";
import {
  User,
  MapPin,
  Tag,
  Phone,
  Share2,
  Flag,
  CheckCircle,
  ChevronRight,
  ChevronLeft,
  Clock,
  ShoppingBag,
  Eye,
  EyeOff,
  LayoutGrid,
  List,
  X,
  SearchX,
} from "lucide-vue-next";

const { get } = useApi();
const { params } = useRoute();

// State variables
const showPhone = ref(false);
const viewMode = ref("list"); // Changed from 'grid' to 'list' to show list view by default
const sortOption = ref("recent");
const categoryFilter = ref("");
const conditionFilter = ref("");
const currentPage = ref(1);
const itemsPerPage = ref(4); // 2 rows of 2 items
const showReportDialog = ref(false);
const showShareDialog = ref(false);
const reportReason = ref("");
const reportDetails = ref("");
const shareUrl = ref(window.location.href);
const showProfilePhotoMenu = ref(false);
const cameraButtonRef = ref(null);
const profilePhotoMenuRef = ref(null);
const showProfilePhotoModal = ref(false);
const profilePhotoMedia = ref(null); // For MediaViewer
const totalPages = ref(0);

const seller = ref({});

async function getSellerDetails() {
  try {
    const response = await get(`/user/${params.id}/`);
    if (response.data) {
      console.log(response.data);
      seller.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching seller details:", error);
  }
}
await getSellerDetails();
// Sample products data with more items for pagination

const products = ref([]);

async function getProducts() {
  try {
    const response = await get(
      `/sale/posts/?page=${currentPage.value}&seller=${params.id}`
    );
    console.log("prod", response.data);
    if (response.data) {
      console.log(response.data);
      if (!totalPages.value > 0) {
        totalPages.value = Math.ceil(
          response.data?.count / response.data?.results
        );
      }
      products.value = response.data?.results;
    }
  } catch (error) {
    console.error("Error fetching products:", error);
  }
}

await getProducts();

const categories = ref([]);

async function getCategories() {
  try {
    const response = await get("/sale/categories/");
    console.log(response.data);
    if (response.data) {
      categories.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}

await getCategories();

const conditions = ref([]);

async function getConditions() {
  try {
    const response = await get("/sale/conditions/");
    console.log("conditions", response.data);
    if (response.data) {
      conditions.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching conditions:", error);
  }
}
await getConditions();

const pages = computed(() => {
  const pages = [];
  for (let i = 1; i <= totalPages.value; i++) {
    pages.push(i);
  }
  return pages;
});

// Format date
const formatDate = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays <= 1) {
    return "Today";
  } else if (diffDays <= 2) {
    return "Yesterday";
  } else if (diffDays <= 7) {
    return `${diffDays} days ago`;
  } else {
    return new Intl.DateTimeFormat("en-US", {
      month: "short",
      day: "numeric",
    }).format(date);
  }
};

// Mask phone number
const maskPhoneNumber = (phone) => {
  return "XXXXXXX" + phone.slice(-3);
};

// Toggle phone visibility
const toggleShowPhone = () => {
  showPhone.value = !showPhone.value;
};

// Pagination methods
const prevPage = async () => {
  if (currentPage.value > 1) {
    currentPage.value--;
    await getProducts();
  }
};

const nextPage = async () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++;
    await getProducts();
  }
};

const goToPage = async (page) => {
  currentPage.value = page;
  await getProducts();
};

// Clear filters
const clearFilters = () => {
  categoryFilter.value = "";
  conditionFilter.value = "";
  currentPage.value = 1;
};

// Report dialog methods
const toggleReportDialog = () => {
  showReportDialog.value = !showReportDialog.value;
  if (showReportDialog.value) {
    reportReason.value = "";
    reportDetails.value = "";
  }
};

const closeReportDialog = () => {
  showReportDialog.value = false;
};

const submitReport = () => {
  // In a real app, this would send the report to the server
  alert(
    `Report submitted. Reason: ${reportReason.value}${
      reportReason.value === "other" ? ", Details: " + reportDetails.value : ""
    }`
  );
  closeReportDialog();
};

// Share dialog methods
const handleShare = () => {
  showShareDialog.value = true;
};

const closeShareDialog = () => {
  showShareDialog.value = false;
};

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareUrl.value);
  alert("Link copied to clipboard!");
};

const shareViaMedia = (platform) => {
  let url = "";
  const currentUrl = encodeURIComponent(window.location.href);
  const title = encodeURIComponent(`Check out ${seller.name}'s profile`);

  switch (platform) {
    case "facebook":
      url = `https://www.facebook.com/sharer/sharer.php?u=${currentUrl}`;
      break;
    case "twitter":
      url = `https://twitter.com/intent/tweet?text=${title}&url=${currentUrl}`;
      break;
    case "whatsapp":
      url = `https://api.whatsapp.com/send?text=${title} ${currentUrl}`;
      break;
    case "email":
      url = `mailto:?subject=${title}&body=${currentUrl}`;
      break;
  }

  if (url) {
    window.open(url, "_blank");
  }

  closeShareDialog();
};

// Profile photo menu methods
const toggleProfilePhotoMenu = () => {
  showProfilePhotoMenu.value = !showProfilePhotoMenu.value;
};

const navigateToSettings = () => {
  alert("Navigating to settings to change photo.");
};

const openProfilePhotoModal = () => {
  // Create a media object for the profile photo
  profilePhotoMedia.value = {
    image: seller.value?.image || '/placeholder.svg',
    type: 'image',
    id: seller.value?.id || 'profile'
  };
  
  showProfilePhotoModal.value = true;
};
</script>

<style scoped>
/* Additional custom styles */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  line-clamp: 2;
  overflow: hidden;
}
</style>
