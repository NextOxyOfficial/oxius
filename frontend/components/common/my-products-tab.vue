<template>
  <div class="animate-fade-in">
    <!-- Product Summary Cards -->
    <div
      class="grid grid-cols-2 md:grid-cols-4 gap-2 p-2 bg-gray-50 border-b border-gray-200"
    >
      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Total Products</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ products.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-indigo-50 flex items-center justify-center"
          >
            <UIcon
              name="i-heroicons-shopping-cart"
              class="h-6 w-6 text-indigo-500"
            />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-indigo-600">
          ৳{{ totalProductsValue.toFixed(2) }}
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Active Products</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ activeProducts.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-green-50 flex items-center justify-center"
          >
            <UIcon
              name="i-heroicons-check-circle"
              class="h-6 w-6 text-green-500"
            />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-green-600">
          ৳{{ activeProductsValue.toFixed(2) }}
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Inactive Products</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ inactiveProducts.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-gray-50 flex items-center justify-center"
          >
            <UIcon
              name="i-heroicons-pause-circle"
              class="h-6 w-6 text-gray-600"
            />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-gray-600">
          ৳{{ inactiveProductsValue.toFixed(2) }}
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Out of Stock</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ outOfStockProducts.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-red-50 flex items-center justify-center"
          >
            <UIcon name="i-heroicons-x-circle" class="h-6 w-6 text-red-500" />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-red-600">
          ৳{{ outOfStockProductsValue.toFixed(2) }}
        </p>
      </div>
    </div>

    <div class="px-6 py-5 border-b border-gray-200 bg-gray-50">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between">        <div class="flex items-center space-x-2">
          <UIcon
            name="i-heroicons-shopping-cart"
            class="h-5 w-5 text-indigo-600"
          />
          <h2 class="text-xl font-semibold text-gray-800">My Products</h2>
          <UButton
            v-if="storeReviewsCount > 0"
            variant="outline"
            color="blue"
            size="xs"
            @click="showReviewsModal = true"
            :loading="isLoadingReviewsCount"
            class="ml-2"
          >
            <UIcon name="i-heroicons-star" class="w-3 h-3 mr-1" />
            {{ storeReviewsCount }} {{ storeReviewsCount === 1 ? 'Review' : 'Reviews' }}
          </UButton>
        </div>
        <div class="mt-3 md:mt-0 flex items-center space-x-4">
          <div class="relative">
            <select
              v-model="productFilter"
              class="block w-full pl-3 pr-10 py-1.5 text-base border-gray-300 focus:outline-none sm:text-sm rounded-md"
            >
              <option value="all">All Products</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="out-of-stock">Out of Stock</option>
            </select>
          </div>
          <div class="relative rounded-md shadow-sm">
            <input
              type="text"
              v-model="productSearch"
              placeholder="Search products..."
              class="block w-full pr-10 py-2 pl-1.5 sm:text-sm border-gray-300 rounded-md focus:outline-none"
            />
            <div
              class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none"
            >
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="h-5 w-5 text-gray-600"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Products Grid -->
    <div class="p-6 grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-4 gap-3">
      <div
        v-for="product in filteredProducts"
        :key="product.id"
        class="group bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden hover:shadow-sm transition-all duration-300 transform hover:-translate-y-1"
      >
        <div class="relative">
          <img
            v-if="product?.image_details?.length"
            :src="product.image_details[0].image"
            :alt="product.name"
            class="w-full h-48 object-contain transition-transform duration-500 group-hover:scale-105"
          />
          <div
            v-else
            class="w-full h-48 bg-gray-200 flex items-center justify-center"
          >
            <UIcon name="i-heroicons-photo" class="h-12 w-12 text-gray-600" />
          </div>
          <div class="absolute top-2 right-2">
            <span
              v-if="product.is_active && product.quantity > 0"
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
            >
              <UIcon name="i-heroicons-check-circle" class="h-3 w-3 mr-1" />
              Active
            </span>
            <span
              v-else-if="!product.is_active"
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
            >
              <UIcon name="i-heroicons-pause-circle" class="h-3 w-3 mr-1" />
              Inactive
            </span>
            <span
              v-else-if="product.quantity <= 0"
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
            >
              <UIcon name="i-heroicons-x-circle" class="h-3 w-3 mr-1" />
              Out of Stock
            </span>
          </div>
        </div>
        <div class="p-4">
          <NuxtLink :to="`/product-details/${product.slug}`">
            <h3
              class="text-lg font-medium mb-1 line-clamp-1 first-letter:uppercase text-green-950"
            >
              {{ product.name }}
            </h3>
          </NuxtLink>
          <div
            v-if="product.short_description"
            class="text-sm text-gray-600 mb-2 line-clamp-2"
          >
            {{ product.short_description }}
          </div>
          <div class="flex justify-between items-center">
            <div class="text-lg font-semibold text-indigo-600">
              ৳{{
                product.sale_price && parseFloat(product.sale_price) > 0
                  ? product.sale_price
                  : product.regular_price
              }}
              <span
                v-if="
                  product.sale_price &&
                  parseFloat(product.sale_price) > 0 &&
                  product.regular_price &&
                  parseFloat(product.sale_price) <
                    parseFloat(product.regular_price)
                "
                class="text-xs text-slate-400 line-through -mt-0.5 flex items-center"
              >
                <span class="text-xs mr-0.5">৳</span
                >{{ product.regular_price }}
              </span>
            </div>
            <div class="text-sm text-gray-600 flex items-center">
              <UIcon
                name="i-heroicons-eye"
                class="h-4 w-4 mr-1 text-gray-600"
              />
              {{ product.views }}
            </div>
            <div class="text-sm text-gray-600 flex items-center">
              <UIcon
                name="i-heroicons-shopping-bag"
                class="h-4 w-4 mr-1 text-gray-600"
              />
              {{ product.order_count }}
            </div>
            <div class="text-sm text-gray-600 flex items-center">
              <UIcon
                name="i-heroicons-cube"
                class="h-4 w-4 mr-1 text-gray-600"
              />
              {{ product.quantity }}
            </div>
          </div>
          <div class="flex flex-col sm:flex-row gap-2 mt-4">
            <!-- Edit Button (Fixed) -->
            <NuxtLink
              :to="`/product-details/${product.slug}/edit/`"
              class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-50 to-blue-50 border border-indigo-100 text-indigo-600 hover:shadow-sm transition-all duration-300"
            >
              <!-- Hover effect overlay -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-indigo-500 to-blue-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>

              <!-- Icon and text -->
              <UIcon
                name="i-heroicons-pencil-square"
                class="h-4 w-4 relative z-10 group-hover:text-white transition-colors duration-300"
              />
              <span
                class="font-medium text-sm relative z-10 group-hover:text-white transition-colors duration-300"
                >Edit</span
              >

              <!-- Subtle glow effect on hover -->
              <div
                class="absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-indigo-400/20 blur-sm"
              ></div>
            </NuxtLink>

            <!-- Activate/Deactivate Button -->
            <button
              @click="toggleProductStatus(product)"
              class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-slate-50 to-gray-50 border border-slate-200 text-gray-600 hover:shadow-sm transition-all duration-300"
            >
              <!-- Hover effect overlay -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-slate-600 to-gray-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>

              <!-- Dynamic icon based on product status -->
              <UIcon
                :name="
                  product.is_active
                    ? 'i-heroicons-eye-slash'
                    : 'i-heroicons-eye'
                "
                class="h-4 w-4 relative z-10 group-hover:text-white transition-colors duration-300"
              />

              <!-- Dynamic text based on product status -->
              <span
                class="font-medium text-sm relative z-10 group-hover:text-white transition-colors duration-300 whitespace-nowrap"
              >
                {{ product.is_active ? "Deactivate" : "Activate" }}
              </span>

              <!-- Subtle glow effect on hover -->
              <div
                class="absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-slate-400/20 blur-sm"
              ></div>
            </button>

            <!-- Delete Button -->
            <button
              @click="confirmDeleteProduct(product)"
              class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-red-50 to-rose-50 border border-red-100 text-red-600 hover:shadow-sm transition-all duration-300"
            >
              <!-- Hover effect overlay -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-red-500 to-rose-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>

              <!-- Icon and text -->
              <UIcon
                name="i-heroicons-trash"
                class="h-4 w-4 relative z-10 group-hover:text-white transition-colors duration-300"
              />
              <span
                class="font-medium text-sm relative z-10 group-hover:text-white transition-colors duration-300"
                >Delete</span
              >

              <!-- Subtle glow effect on hover -->
              <div
                class="absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-red-400/20 blur-sm"
              ></div>
            </button>
          </div>
        </div>
      </div>
      <div
        v-if="filteredProducts.length === 0"
        class="col-span-full py-10 text-center text-gray-600"
      >
        <div class="flex flex-col items-center justify-center">
          <UIcon
            name="i-heroicons-cube-transparent"
            class="h-12 w-12 text-gray-400 mb-2"
          />
          No products found matching your criteria
        </div>
      </div>
    </div>

    <!-- Delete Product Confirmation Modal -->
    <UModal v-model="showDeleteConfirmModal">
      <div
        class="bg-white rounded-xl shadow-sm overflow-hidden max-w-lg w-full"
      >
        <div
          class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
        ></div>
        <div
          class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
        >
          <h3
            class="text-xl font-semibold text-gray-800 flex items-center"
            id="modal-title"
          >
            <UIcon
              name="i-heroicons-exclamation-triangle"
              class="h-5 w-5 mr-2 text-red-500"
            />
            Confirm Deletion
          </h3>
          <button
            @click="showDeleteConfirmModal = false"
            class="text-gray-600 hover:text-gray-600 transition-colors duration-150"
          >
            <UIcon name="i-heroicons-x-mark" class="h-6 w-6" />
          </button>
        </div>
        <div class="px-6 py-4">
          <p class="text-gray-800">
            Are you sure you want to delete the product
            <span class="font-medium">{{ selectedProduct?.name }}</span
            >? This action cannot be undone.
          </p>
        </div>
        <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
          <UButton
            color="red"
            @click="deleteProduct"
            :loading="isProcessing"
            icon="i-heroicons-trash"
          >
            Delete
          </UButton>
          <UButton
            color="gray"
            variant="outline"
            @click="showDeleteConfirmModal = false"
            icon="i-heroicons-x-mark"
          >
            Cancel
          </UButton>        </div>
      </div>
    </UModal>

    <!-- Store Reviews Modal -->
    <UModal v-model="showReviewsModal" :ui="{ width: 'max-w-4xl' }">
      <div class="p-0">
        <!-- Modal Header -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
          <div class="flex items-center space-x-2">
            <UIcon name="i-heroicons-star" class="w-5 h-5 text-yellow-500" />
            <h3 class="text-lg font-semibold text-gray-800">Store Reviews</h3>
            <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded">
              {{ storeReviewsCount }} {{ storeReviewsCount === 1 ? 'Review' : 'Reviews' }}
            </span>
          </div>
          <UButton
            color="gray"
            variant="ghost"
            icon="i-heroicons-x-mark"
            @click="showReviewsModal = false"
            class="rounded-full"
          />
        </div>

        <!-- Modal Content -->
        <div class="max-h-96 overflow-y-auto">
          <!-- Loading State -->
          <div v-if="isLoadingStoreReviews" class="flex justify-center items-center py-12">
            <div class="animate-spin w-8 h-8 border-2 border-primary-500 border-t-transparent rounded-full"></div>
            <span class="ml-3 text-gray-600">Loading reviews...</span>
          </div>

          <!-- Reviews List -->
          <div v-else-if="storeReviews.length > 0" class="p-6 space-y-4">
            <div
              v-for="(review, index) in storeReviews"
              :key="review.id || index"
              class="bg-white border border-gray-200 rounded-lg p-4 hover:shadow-sm transition-shadow"
            >
              <!-- Review Header -->
              <div class="flex items-start justify-between mb-3">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center text-primary-700 dark:text-primary-300 font-medium">
                    {{ review.user?.display_name?.charAt(0) || review.reviewer_name?.charAt(0) || "U" }}
                  </div>
                  <div>
                    <div class="font-medium text-gray-800">
                      {{ review.user?.display_name || review.reviewer_name || "Anonymous" }}
                    </div>
                    <div class="text-xs text-gray-500">
                      {{ review.formatted_date || "Recently" }}
                      <span v-if="review.is_verified_purchase" class="ml-2 text-green-600">
                        ✓ Verified Purchase
                      </span>
                    </div>
                  </div>
                </div>
                
                <!-- Rating Stars -->
                <div class="flex text-yellow-400">
                  <UIcon
                    v-for="star in 5"
                    :key="star"
                    :name="star <= review.rating ? 'i-heroicons-star-solid' : 'i-heroicons-star'"
                    class="w-4 h-4"
                    :class="star <= review.rating ? 'text-yellow-400' : 'text-gray-300'"
                  />
                </div>
              </div>

              <!-- Product Info -->
              <div class="mb-3 p-2 bg-gray-50 rounded text-sm">
                <span class="font-medium text-gray-700">Product:</span>
                <span class="text-gray-600 ml-1">{{ review.product?.name || 'Unknown Product' }}</span>
              </div>

              <!-- Review Content -->
              <div v-if="review.title" class="font-medium text-gray-800 mb-1">
                {{ review.title }}
              </div>
              <p class="text-gray-600 text-sm">
                "{{ review.comment }}"
              </p>

              <!-- Review Actions -->
              <div class="flex items-center justify-between mt-3 pt-3 border-t border-gray-100">
                <div class="flex items-center space-x-2 text-xs text-gray-500">
                  <span v-if="review.helpful_count > 0">
                    {{ review.helpful_count }} {{ review.helpful_count === 1 ? 'person found' : 'people found' }} this helpful
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-else class="text-center py-12">
            <UIcon name="i-heroicons-chat-bubble-bottom-center-text" class="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-800 mb-2">No Reviews Yet</h3>
            <p class="text-gray-600">
              Your products haven't received any reviews yet. Encourage customers to leave feedback!
            </p>
          </div>
        </div>

        <!-- Modal Footer -->
        <div v-if="totalStoreReviewPages > 1" class="px-6 py-4 border-t border-gray-200 bg-gray-50">
          <div class="flex justify-center items-center gap-2">
            <!-- Previous button -->
            <UButton
              icon="i-heroicons-chevron-left"
              color="gray"
              variant="ghost"
              :disabled="currentStoreReviewPage === 1 || isLoadingStoreReviews"
              @click="previousStoreReviewPage"
              size="sm"
              class="rounded-full"
            />

            <!-- Page numbers -->
            <div class="flex gap-1">
              <UButton
                v-for="page in storeReviewPaginationRange"
                :key="page"
                :variant="currentStoreReviewPage === page ? 'solid' : 'ghost'"
                :color="currentStoreReviewPage === page ? 'primary' : 'gray'"
                :disabled="page === '...' || isLoadingStoreReviews"
                @click="page !== '...' && goToStoreReviewPage(page)"
                size="sm"
                class="rounded-full min-w-[32px]"
              >
                {{ page }}
              </UButton>
            </div>

            <!-- Next button -->
            <UButton
              icon="i-heroicons-chevron-right"
              color="gray"
              variant="ghost"
              :disabled="currentStoreReviewPage === totalStoreReviewPages || isLoadingStoreReviews"
              @click="nextStoreReviewPage"
              size="sm"
              class="rounded-full"
            />
          </div>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from "vue";
import { useAuth } from "~/composables/useAuth";
import { useApi } from "~/composables/useApi";
// import { useToast } from "~/composables/useToast";

const { user } = useAuth();
const { get, patch, del } = useApi();
const toast = useToast();

// UI state
const showDeleteConfirmModal = ref(false);
const isProcessing = ref(false);

// Reviews state
const showReviewsModal = ref(false);
const storeReviews = ref([]);
const storeReviewsCount = ref(0);
const isLoadingReviewsCount = ref(false);
const isLoadingStoreReviews = ref(false);
const currentStoreReviewPage = ref(1);
const totalStoreReviewPages = ref(1);
const storeReviewsPerPage = 6;

// Filters and search
const productFilter = ref("all");
const productSearch = ref("");

// Selected items
const selectedProduct = ref(null);

// Component state
const products = ref([]);

// Product summary computed properties
const activeProducts = computed(() => {
  return products.value.filter(
    (product) => product.is_active && product.quantity > 0
  );
});

const inactiveProducts = computed(() => {
  return products.value.filter((product) => !product.is_active);
});

const outOfStockProducts = computed(() => {
  return products.value.filter(
    (product) => product.is_active && product.quantity <= 0
  );
});

const totalProductsValue = computed(() => {
  return products.value.reduce(
    (total, product) =>
      total +
      (parseFloat(product.sale_price) || 0) * (parseInt(product.quantity) || 0),
    0
  );
});

const activeProductsValue = computed(() => {
  return activeProducts.value.reduce(
    (total, product) =>
      total +
      (parseFloat(product.sale_price) || 0) * (parseInt(product.quantity) || 0),
    0
  );
});

const inactiveProductsValue = computed(() => {
  return inactiveProducts.value.reduce(
    (total, product) =>
      total +
      (parseFloat(product.sale_price) || 0) * (parseInt(product.quantity) || 0),
    0
  );
});

const outOfStockProductsValue = computed(() => {
  return outOfStockProducts.value.reduce(
    (total, product) =>
      total +
      (parseFloat(product.sale_price) || 0) * (parseInt(product.quantity) || 0),
    0
  );
});

// Product filtering
const filteredProducts = computed(() => {
  let result = [...products.value];

  // Apply status filter
  if (productFilter.value === "active") {
    result = result.filter(
      (product) => product.is_active && product.quantity > 0
    );
  } else if (productFilter.value === "inactive") {
    result = result.filter((product) => !product.is_active);
  } else if (productFilter.value === "out-of-stock") {
    result = result.filter(
      (product) => product.is_active && product.quantity <= 0
    );
  }

  // Apply search filter
  if (productSearch.value) {
    const search = productSearch.value.toLowerCase();
    result = result.filter(
      (product) =>
        product.name.toLowerCase().includes(search) ||
        (product.short_description &&
          product.short_description.toLowerCase().includes(search))
    );
  }
  return result;
});

// Store reviews pagination
const storeReviewPaginationRange = computed(() => {
  if (totalStoreReviewPages.value <= 5) {
    return Array.from({ length: totalStoreReviewPages.value }, (_, i) => i + 1);
  }

  if (currentStoreReviewPage.value <= 3) {
    return [1, 2, 3, 4, "...", totalStoreReviewPages.value];
  }

  if (currentStoreReviewPage.value >= totalStoreReviewPages.value - 2) {
    return [
      1,
      "...",
      totalStoreReviewPages.value - 3,
      totalStoreReviewPages.value - 2,
      totalStoreReviewPages.value - 1,
      totalStoreReviewPages.value,
    ];
  }

  return [
    1,
    "...",
    currentStoreReviewPage.value - 1,
    currentStoreReviewPage.value,
    currentStoreReviewPage.value + 1,
    "...",
    totalStoreReviewPages.value,
  ];
});

// Methods
// Reviews functions
async function getStoreReviewsCount() {
  try {
    isLoadingReviewsCount.value = true;
    const res = await get("/reviews/store-reviews/count/");
    if (res && res.data) {
      storeReviewsCount.value = res.data.count || 0;
    }
  } catch (error) {
    console.error("Error fetching store reviews count:", error);
    storeReviewsCount.value = 0;
  } finally {
    isLoadingReviewsCount.value = false;
  }
}

async function getStoreReviews(page = 1) {
  try {
    isLoadingStoreReviews.value = true;
    const res = await get("/reviews/store-reviews/", {
      params: {
        page: page,
        page_size: storeReviewsPerPage
      }
    });
    
    if (res && res.data) {
      if (res.data.results) {
        storeReviews.value = res.data.results;
        totalStoreReviewPages.value = Math.ceil((res.data.count || 0) / storeReviewsPerPage);
      } else if (Array.isArray(res.data)) {
        storeReviews.value = res.data;
        totalStoreReviewPages.value = Math.ceil(res.data.length / storeReviewsPerPage);
      } else {
        storeReviews.value = [];
        totalStoreReviewPages.value = 1;
      }
    } else {
      storeReviews.value = [];
      totalStoreReviewPages.value = 1;
    }
  } catch (error) {
    console.error("Error fetching store reviews:", error);
    storeReviews.value = [];
    totalStoreReviewPages.value = 1;
    toast.add({
      title: "Error loading reviews",
      description: "Could not load store reviews. Please try again later.",
      color: "red",
    });
  } finally {
    isLoadingStoreReviews.value = false;
  }
}

// Reviews pagination functions
async function goToStoreReviewPage(page) {
  if (page !== currentStoreReviewPage.value) {
    currentStoreReviewPage.value = page;
    await getStoreReviews(page);
  }
}

async function previousStoreReviewPage() {
  if (currentStoreReviewPage.value > 1) {
    const newPage = currentStoreReviewPage.value - 1;
    currentStoreReviewPage.value = newPage;
    await getStoreReviews(newPage);
  }
}

async function nextStoreReviewPage() {
  if (currentStoreReviewPage.value < totalStoreReviewPages.value) {
    const newPage = currentStoreReviewPage.value + 1;    currentStoreReviewPage.value = newPage;
    await getStoreReviews(newPage);
  }
}

// Product methods
async function getProducts() {
  try {
    const res = await get("/my-products/");
    if (res && res.data) {
      products.value = res.data;
      console.log(`Loaded ${products.value.length} products`);
    } else {
      console.warn("No product data received");
      products.value = [];
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load your products. Please try again later.",
      color: "red",
    });
    products.value = []; // Ensure it's at least an empty array
  }
}

const toggleProductStatus = async (product) => {
  if (isProcessing.value) return;

  isProcessing.value = true;
  try {
    const res = await patch(`/products/${product.slug}/`, {
      is_active: !product.is_active,
    });

    if (res.data) {
      // Update product status locally
      const index = products.value.findIndex((p) => p.id === product.id);
      if (index !== -1) {
        products.value[index].is_active = res.data.is_active;
      }

      toast.add({
        title: "Status Changed",
        description: `${product.name} is now ${
          res.data.is_active ? "visible" : "hidden"
        } to customers.`,
        color: "green",
      });
    }
  } catch (error) {
    console.error("Error toggling product status:", error);
    toast.add({
      title: "Status Change Failed",
      description: "There was an error changing the product status.",
      color: "red",
    });
  } finally {
    isProcessing.value = false;
  }
};

const confirmDeleteProduct = (product) => {
  selectedProduct.value = product;
  showDeleteConfirmModal.value = true;
};

const deleteProduct = async () => {
  if (!selectedProduct.value || isProcessing.value) return;

  isProcessing.value = true;

  try {
    const res = await del(`/products/${selectedProduct.value.slug}/`);

    if (res.status === 204 || res.status === 200) {
      // Remove product from local array
      products.value = products.value.filter(
        (p) => p.id !== selectedProduct.value.id
      );

      toast.add({
        title: "Product Deleted",
        description: `${selectedProduct.value.name} has been successfully deleted.`,
        color: "green",
      });
    }

    // Close the modal
    showDeleteConfirmModal.value = false;
    selectedProduct.value = null;
  } catch (error) {
    console.error("Error deleting product:", error);
    toast.add({
      title: "Deletion Failed",
      description: "There was an error deleting the product.",
      color: "red",
    });  } finally {
    isProcessing.value = false;
  }
};

// Watch for modal opening to load reviews
watch(showReviewsModal, (newValue) => {
  if (newValue && storeReviews.value.length === 0) {
    currentStoreReviewPage.value = 1;
    getStoreReviews(1);
  }
});

// Initialize component
onMounted(async () => {
  await Promise.all([
    getProducts(),
    getStoreReviewsCount()
  ]);
});
</script>
