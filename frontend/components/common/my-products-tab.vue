<template>
  <div class="animate-fade-in">
    <!-- Product Summary Cards -->
    <div
      class="grid grid-cols-2 md:grid-cols-4 gap-2 p-2 bg-gray-50 border-b border-gray-200"
    >
      <div class="bg-white rounded-lg shadow-sm p-4 border border-gray-100">
        <div class="flex items-center justify-between">
          <div>            <p class="text-sm font-medium text-gray-600">Total Products</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ productStats.total }}
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

    <div class="px-2 sm:px-6 py-5 border-b border-gray-200 bg-gray-50">
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
    </div>    <!-- Products Grid -->
    <div v-if="isLoading" class="p-6">
      <div class="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-4 gap-3">
        <div
          v-for="i in 8"
          :key="i"
          class="bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden animate-pulse"
        >
          <div class="w-full h-48 bg-gray-200"></div>
          <div class="p-4">
            <div class="h-4 bg-gray-200 rounded mb-2"></div>
            <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div class="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
      </div>
    </div>
    <div v-else class="p-6 grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-4 gap-3">
      <div
        v-for="product in displayedProducts"
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
            </button>            <!-- Delete Button -->
            <button
              @click="confirmDeleteProduct(product)"
              class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-red-50 to-rose-50 border border-red-100 text-red-600 hover:shadow-sm transition-all duration-300"
            >
              <!-- Hover effect overlay -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-red-500 to-rose-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>

              <!-- Text only, no icon -->
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
      </div>      <div
        v-if="displayedProducts.length === 0 && !isLoading"
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

    <!-- Load More Button -->
    <div
      v-if="hasMoreProducts"
      class="p-6 border-t border-gray-100 bg-gradient-to-b from-white/80 to-gray-50/60 text-center"
    >
      <UButton
        @click="loadMoreProducts"
        :loading="isLoadingMore"
        variant="outline"
        color="gray"
        size="lg"
        class="px-8 py-3"
      >
        <template #leading>
          <UIcon name="i-heroicons-arrow-down" />
        </template>
        {{ isLoadingMore ? 'Loading more products...' : 'Load more products' }}
      </UButton>
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
          </UButton>        
        </div>
      </div>
    </UModal>    
    <!-- Store Reviews Modal -->
    <Teleport to="body">
      <div
        v-if="showReviewsModal"
        class="fixed inset-0 z-50 overflow-y-auto pt-14 md:pt-16"
      >
        <!-- Modal backdrop -->
        <div
          class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
        >
          <div
            class="fixed inset-0 transition-opacity"
            @click="showReviewsModal = false"
          >
            <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
          </div>

          <div
            class="inline-block w-full align-bottom bg-white rounded-lg text-left overflow-hidden transform transition-all sm:my-8 sm:align-middle sm:w-2xl sm:max-w-2xl"
          >
            <!-- Modal Header -->
            <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-white">
              <div class="flex items-center space-x-3">
                <UIcon name="i-heroicons-star" class="w-6 h-6 text-yellow-500" />
                <div>
                  <h3 class="text-xl font-semibold text-gray-900">Store Reviews</h3>
                  <p class="text-sm text-gray-600">Reviews for your products</p>
                </div>
                <span class="bg-primary-100 text-primary-800 text-sm font-medium px-3 py-1 rounded-full">
                  {{ storeReviewsCount }} {{ storeReviewsCount === 1 ? 'Review' : 'Reviews' }}
                </span>
              </div>
              <button
                type="button"
                class="text-gray-600 hover:text-gray-600"
                @click="showReviewsModal = false"
              >
                <UIcon name="i-heroicons-x-mark" class="w-6 h-6" />
              </button>
            </div>

            <!-- Modal Content -->
            <div class="bg-gray-50 max-h-[70vh] overflow-y-auto">
              <!-- Loading State -->
              <div v-if="isLoadingStoreReviews" class="flex justify-center items-center py-32">
                <div class="flex flex-col items-center">
                  <div class="animate-spin w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full"></div>
                  <span class="text-gray-600 mt-4 text-lg">Loading reviews...</span>
                </div>
              </div>

              <!-- Reviews List -->
              <div v-else-if="storeReviews.length > 0" class="p-6">
                <div>
                  <div
                    v-for="(review, index) in storeReviews"
                    :key="review.id || index"
                    class="bg-white border border-gray-200 rounded-xl p-6 shadow-sm hover:shadow-sm transition-all duration-300"
                  ><!-- Review Header -->
                <div class="flex items-start justify-between mb-4">
                  <div class="flex items-center space-x-3">
                    <div class="w-12 h-12 bg-gradient-to-br from-primary-100 to-primary-200 rounded-full flex items-center justify-center text-primary-700 font-semibold text-lg">
                      {{ review.user?.display_name?.charAt(0) || review.reviewer_name?.charAt(0) || "U" }}
                    </div>
                    <div>
                      <div class="font-medium text-gray-900">
                        {{ review.user?.display_name || review.reviewer_name || "Anonymous" }}
                      </div>
                      <div class="text-sm text-gray-500 flex items-center">
                        <UIcon name="i-heroicons-clock" class="w-4 h-4 mr-1" />
                        {{ review.formatted_date || "Recently" }}
                      </div>
                    </div>
                  </div>
                  
                  <!-- Rating Stars -->
                  <div class="flex text-yellow-400">
                    <UIcon
                      v-for="star in 5"
                      :key="star"
                      :name="star <= review.rating ? 'i-heroicons-star-solid' : 'i-heroicons-star'"
                      class="w-5 h-5"
                      :class="star <= review.rating ? 'text-yellow-400' : 'text-gray-300'"
                    />
                  </div>
                </div><!-- Product Info -->
                <div class="mb-4 p-4 bg-gradient-to-r from-gray-50 to-gray-100 rounded-lg border border-gray-200">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <UIcon name="i-heroicons-cube" class="w-5 h-5 text-gray-500 mr-2" />
                      <span class="font-medium text-gray-700">Product:</span>
                    </div>
                    <UIcon name="i-heroicons-arrow-top-right-on-square" class="w-4 h-4 text-gray-400" />
                  </div>
                  <NuxtLink
                    v-if="review.product?.slug"
                    :to="`/product-details/${review.product.slug}`"
                    class="font-medium text-primary-600 hover:text-primary-800 transition-colors duration-200 mt-1 block cursor-pointer"
                  >
                    {{ review.product?.name || 'Unknown Product' }}
                  </NuxtLink>
                  <span v-else class="font-semibold text-gray-600 text-lg mt-1 block">
                    {{ review.product?.name || 'Product no longer available' }}
                  </span>
                  <div v-if="review.product?.sale_price || review.product?.regular_price" class="text-sm text-gray-600 mt-1">
                    ৳{{ review.product?.sale_price || review.product?.regular_price }}
                  </div>
                </div>

                <!-- Review Content -->
                <div v-if="review.title" class="font-semibold text-gray-800 mb-2 text-lg">
                  "{{ review.title }}"
                </div>
                <p class="text-gray-600 leading-relaxed mb-4">
                  "{{ review.comment }}"
                </p>

                <!-- Review Actions -->
                <div class="flex items-center justify-between pt-4 border-t border-gray-100">
                  
                  <div class="flex items-center text-sm text-gray-400">
                    <UIcon name="i-heroicons-chat-bubble-bottom-center-text" class="w-4 h-4 mr-1" />
                    Review #{{ index + 1 + (currentStoreReviewPage - 1) * storeReviewsPerPage }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-else class="text-center py-24">
            <div class="max-w-md mx-auto">
              <UIcon name="i-heroicons-chat-bubble-bottom-center-text" class="w-24 h-24 text-gray-300 mx-auto mb-6" />
              <h3 class="text-2xl font-semibold text-gray-800 mb-4">No Reviews Yet</h3>
              <p class="text-gray-600 text-lg leading-relaxed">
                Your products haven't received any reviews yet. Encourage customers to leave feedback after their purchase!
              </p>
              <div class="mt-6">
                <UButton
                  color="primary"
                  variant="outline"
                  @click="showReviewsModal = false"
                  icon="i-heroicons-arrow-left"
                >
                  Back to Products
                </UButton>
              </div>
            </div>          
          </div>        </div>

            <!-- Modal Footer with Pagination -->
            <div v-if="totalStoreReviewPages > 1" class="px-6 py-4 border-t border-gray-200 bg-white flex-shrink-0">
              <div class="flex justify-between items-center">
                <div class="text-sm text-gray-600">
                  Showing {{ ((currentStoreReviewPage - 1) * storeReviewsPerPage) + 1 }} to 
                  {{ Math.min(currentStoreReviewPage * storeReviewsPerPage, storeReviewsCount) }} 
                  of {{ storeReviewsCount }} reviews
                </div>
                <div class="flex items-center gap-2">
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
                      class="rounded-full min-w-[36px] h-9"
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
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from "vue";
import { useAuth } from "~/composables/useAuth";
import { useApi } from "~/composables/useApi";
// import { useToast } from "~/composables/useToast";

/**
 * My Products Tab Component with Pagination
 * 
 * Features:
 * - Backend pagination (8 products per page)
 * - Load more button (disappears when all products are loaded)
 * - Real-time filtering (status, search)
 * - Debounced search (300ms delay)
 * - Product statistics summary
 * - Product management (edit, activate/deactivate, delete)
 */

const { user } = useAuth();
const { get, patch, del } = useApi();
const toast = useToast();

// UI state
const showDeleteConfirmModal = ref(false);
const isProcessing = ref(false);
const isLoading = ref(true);
const isLoadingMore = ref(false);

// Pagination state
const currentPage = ref(1);
const hasMoreProducts = ref(false);
const pagination = ref(null);
const pageSize = 8; // Display 8 products per page
const searchTimeout = ref(null);

// Reviews state
const showReviewsModal = ref(false);
const storeReviews = ref([]);
const storeReviewsCount = ref(0);
const isLoadingReviewsCount = ref(false);
const isLoadingStoreReviews = ref(false);
const currentStoreReviewPage = ref(1);
const totalStoreReviewPages = ref(1);
const storeReviewsPerPage = 10;

// Filters and search
const productFilter = ref("all");
const productSearch = ref("");

// Selected items
const selectedProduct = ref(null);

// Component state
const products = ref([]);
const allProducts = ref([]); // Store all products for filtering
const productStats = ref({
  total: 0,
  active: 0,
  inactive: 0,
  out_of_stock: 0,
  total_value: 0,
  active_value: 0,
  inactive_value: 0,
  out_of_stock_value: 0
});

// Product summary computed properties (now using API statistics)
const activeProducts = computed(() => {
  return { length: productStats.value.active };
});

const inactiveProducts = computed(() => {
  return { length: productStats.value.inactive };
});

const outOfStockProducts = computed(() => {
  return { length: productStats.value.out_of_stock };
});

const totalProductsValue = computed(() => {
  return productStats.value.total_value || 0;
});

const activeProductsValue = computed(() => {
  return productStats.value.active_value || 0;
});

const inactiveProductsValue = computed(() => {
  return productStats.value.inactive_value || 0;
});

const outOfStockProductsValue = computed(() => {
  return productStats.value.out_of_stock_value || 0;
});

// Product filtering and display
const filteredProducts = computed(() => {
  let result = [...allProducts.value];

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

// Display products based on pagination
const displayedProducts = computed(() => {
  return products.value;
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
async function getProducts(page = 1) {
  if (page === 1) {
    isLoading.value = true;
    products.value = [];
  } else {
    isLoadingMore.value = true;
  }

  try {
    // Build query parameters for pagination
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('page_size', pageSize.toString());

    // Add filters to API call if they exist
    if (productFilter.value && productFilter.value !== 'all') {
      if (productFilter.value === 'active') {
        params.append('is_active', 'true');
        params.append('has_stock', 'true');
      } else if (productFilter.value === 'inactive') {
        params.append('is_active', 'false');
      } else if (productFilter.value === 'out-of-stock') {
        params.append('is_active', 'true');
        params.append('has_stock', 'false');
      }
    }

    if (productSearch.value) {
      params.append('search', productSearch.value);
    }

    const res = await get(`/my-products/?${params.toString()}`, {}, {
      headers: {
        "Cache-Control": "no-cache",
        Pragma: "no-cache",
      },
    });    if (res && res.data) {
      if ("results" in res.data) {
        // Paginated response
        pagination.value = {
          count: res.data.count,
          next: res.data.next,
          previous: res.data.previous,
        };        if (page === 1) {
          products.value = res.data.results;
          allProducts.value = res.data.results;
        } else {
          products.value = [...products.value, ...res.data.results];
          allProducts.value = [...allProducts.value, ...res.data.results];
        }

        hasMoreProducts.value = !!res.data.next;
        console.log(`Loaded ${res.data.results.length} products (page ${page})`);
      } else if (Array.isArray(res.data)) {
        // Non-paginated response - handle fallback
        products.value = res.data;
        allProducts.value = res.data;
        hasMoreProducts.value = false;
        console.log(`Loaded ${res.data.length} products (non-paginated)`);
      } else {
        console.warn("Unexpected data format received");
        products.value = [];
        allProducts.value = [];
        hasMoreProducts.value = false;
      }
    } else {
      console.warn("No product data received");
      products.value = [];
      allProducts.value = [];
      hasMoreProducts.value = false;
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load your products. Please try again later.",
      color: "red",
    });
    products.value = [];
    allProducts.value = [];
    hasMoreProducts.value = false;
  } finally {
    isLoading.value = false;
    isLoadingMore.value = false;
  }
}

// Load more products
const loadMoreProducts = () => {
  if (hasMoreProducts.value && !isLoadingMore.value) {
    currentPage.value++;
    getProducts(currentPage.value);
  }
};

// Refresh statistics only (for when products are updated)
const refreshProductStats = async () => {
  try {
    const res = await get("/my-products/stats/", {}, {
      headers: {
        "Cache-Control": "no-cache",
        Pragma: "no-cache",
      },
    });

    if (res && res.data) {
      productStats.value = res.data;
    }
  } catch (error) {
    console.error("Error refreshing product statistics:", error);
  }
};

// Load product statistics
const loadProductStats = async () => {
  try {
    const res = await get("/my-products/stats/");
    if (res && res.data) {
      productStats.value = res.data;
    }
  } catch (error) {
    console.error("Error loading product statistics:", error);
  }
};

const toggleProductStatus = async (product) => {
  if (isProcessing.value) return;

  isProcessing.value = true;
  try {
    const res = await patch(`/products/${product.slug}/`, {
      is_active: !product.is_active,
    });

    if (res.data) {
      // Update product status in both arrays
      const updateProduct = (products) => {
        const index = products.findIndex((p) => p.id === product.id);
        if (index !== -1) {
          products[index].is_active = res.data.is_active;
        }
      };

      updateProduct(products.value);
      updateProduct(allProducts.value);      toast.add({
        title: "Status Changed",
        description: `${product.name} is now ${
          res.data.is_active ? "visible" : "hidden"
        } to customers.`,
        color: "green",
      });

      // Refresh statistics after status change
      await refreshProductStats();
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
      // Remove product from both arrays
      products.value = products.value.filter(
        (p) => p.id !== selectedProduct.value.id
      );
      allProducts.value = allProducts.value.filter(
        (p) => p.id !== selectedProduct.value.id
      );      toast.add({
        title: "Product Deleted",
        description: `${selectedProduct.value.name} has been successfully deleted.`,
        color: "green",
      });

      // Refresh statistics after deletion
      await refreshProductStats();
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

// Watch for filter changes to reset pagination
watch(productFilter, () => {
  currentPage.value = 1;
  hasMoreProducts.value = false;
  getProducts(1);
});

// Debounced search
watch(productSearch, (newSearch) => {
  // Clear existing timeout
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value);
  }
  
  // Set new timeout
  searchTimeout.value = setTimeout(() => {
    currentPage.value = 1;
    hasMoreProducts.value = false;
    getProducts(1);
  }, 300);
});

// Initialize component
onMounted(async () => {
  await Promise.all([
    getProducts(1),
    getStoreReviewsCount(),
    loadProductStats()
  ]);
});

// Cleanup
onUnmounted(() => {
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value);
  }
});
</script>
