<template>
  <div ref="productCardRef">
    <div class="transition-all duration-200">
      <!-- Simplified Card Container -->
      <div
        class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-lg overflow-hidden h-full flex flex-col"
      >
        <!-- Product Image Section -->
        <div class="relative pt-[100%] overflow-hidden">
          <!-- Simplified Discount Badge -->
          <div
            v-if="
              product.regular_price &&
              calculateDiscount(product.sale_price, product.regular_price) > 0
            "
            class="absolute top-2 left-2 z-20"
          >
            <div
              class="px-2 py-1 bg-red-500 rounded text-white text-xs font-semibold flex items-center"
            >
              <UIcon name="i-heroicons-bolt" class="size-3 mr-1" />
              <span
                >{{
                  calculateDiscount(product.sale_price, product.regular_price)
                }}% OFF</span
              >
            </div>
          </div>
          <!-- Simplified Free Delivery Badge -->
          <div
            v-if="product.is_free_delivery"
            class="absolute bottom-2 left-2 z-20"
          >
            <div
              class="px-2 py-1 bg-green-500/90 rounded text-white text-xs font-semibold flex items-center"
            >
              <UIcon name="i-heroicons-truck" class="size-3 mr-1" />
              <span>FREE DELIVERY</span>
            </div>
          </div>
          <!-- Simplified Image -->
          <img
            :src="getProductImage(product)"
            :alt="product.name"
            class="absolute inset-0 w-full h-full object-cover"
            loading="lazy"
          />

          <!-- Simplified Quick View Button -->
          <div
            class="absolute inset-0 z-10 flex items-center justify-center opacity-0 bg-transparent hover:opacity-100 transition-opacity"
          >
            <button
              @click="openProductModal(product)"
              class="px-3 py-2 bg-white dark:bg-slate-900 text-sm font-medium rounded shadow-sm flex items-center"
            >
              <UIcon name="i-heroicons-eye" class="mr-2 size-4" />
              <span>Quick View</span>
            </button>
          </div>
        </div>
        <!-- Product Details -->
        <div class="my-2 px-2 flex-grow flex flex-col">
          <!-- Price Section - Moved to top -->
          <div class="mb-2">
            <div class="flex items-center gap-2">
              <span
                class="font-semibold text-gray-800 dark:text-white text-base flex items-center"
              >
                <span class="text-xs mr-1 text-slate-500">৳</span
                >{{
                  product.sale_price && parseFloat(product.sale_price) > 0
                    ? product.sale_price
                    : product.regular_price
                }}
              </span>
              <span
                v-if="
                  product.sale_price &&
                  parseFloat(product.sale_price) > 0 &&
                  product.regular_price &&
                  parseFloat(product.sale_price) <
                    parseFloat(product.regular_price)
                "
                class="text-xs text-slate-400 line-through flex items-center"
              >
                <span class="text-xs mr-0.5">৳</span>{{ product.regular_price }}
              </span>
            </div>
          </div>
          <!-- Product Title - Moved above store name -->
          <NuxtLink :to="`/product-details/${product?.slug}`" class="mb-2">
            <h3
              class="font-medium text-gray-800 dark:text-white line-clamp-1 text-sm text-left capitalize"
            >
              {{ product.name }}
            </h3>
          </NuxtLink>
          <!-- Store Link - Moved below product name -->
          <NuxtLink
            :to="`/eshop/${
              product?.owner_details?.store_username ||
              product?.owner?.store_username
            }`"
            class="text-gray-600 dark:text-gray-400 text-sm mb-3 inline-flex items-center gap-2 hover:text-primary-600 transition-colors duration-200 bg-gray-50 dark:bg-slate-700 px-2 py-1 rounded-lg"
          >
            <div
              class="flex items-center justify-center size-5 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full shadow-sm"
            >
              <UIcon
                name="i-material-symbols-storefront-outline-rounded"
                class="size-3 text-white"
              />
            </div>
            <span class="line-clamp-1 font-medium text-xs">
              {{
                product?.owner_details?.store_name ||
                product?.owner?.store_name ||
                "Store"
              }}
            </span>
          </NuxtLink>
          <!-- Full Width Buy Now Button -->
          <button
            :disabled="loadingStates[product.id]"
            class="w-full flex items-center justify-center gap-2 px-4 py-2.5 font-medium text-white bg-gray-700 hover:bg-gray-800 rounded transition-colors duration-200 disabled:opacity-70"
            @click="addToCart(product, quantity)"
          >
            <span
              v-if="!loadingStates[product.id]"
              class="flex items-center gap-2"
            >
              <UIcon name="i-heroicons-shopping-cart" class="size-4" />
              <span class="text-sm font-medium">Buy Now</span>
            </span>
            <span v-else class="flex items-center gap-2">
              <UIcon
                name="i-heroicons-arrow-path"
                class="size-4 animate-spin"
              />
              <span class="text-sm">Processing...</span>
            </span>
          </button>
        </div>
      </div>
    </div>
    <!-- Simplified Product Details Modal -->
    <UModal
      v-if="!isInModal"
      v-model="isModalOpen"
      :ui="{
        width: 'w-full sm:max-w-4xl',
        height: 'h-auto',
        container: 'flex flex-col h-auto mt-20 p-0 sm:p-0',
        padding: 'p-0',
        transition: {
          enter: 'duration-300 ease-out',
          enterFrom: 'opacity-0 scale-95',
          enterTo: 'opacity-100 scale-100',
          leave: 'duration-200 ease-in',
          leaveFrom: 'opacity-100 scale-100',
          leaveTo: 'opacity-0 scale-95',
        },
      }"
    >
      <div>
        <div class="bg-white dark:bg-slate-800 rounded-xl">
          <CommonProductDetailsCard
            :current-product="selectedProduct"
            :modal="true"
            :seeDetails="true"
            @close-modal="closeProductModal"
            @close-and-reopen-modal="updateModalProduct"
          />
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const { patch } = useApi();
const { product, isInModal, onModalProductChange } = defineProps({
  product: { type: Object, required: true },
  isInModal: { type: Boolean, default: false },
  onModalProductChange: { type: Function, default: null },
});

// Define emits for parent communication
const emit = defineEmits(["updateModalProduct"]);

const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);

const loadingStates = ref({});
const cart = useStoreCart();
const productCardRef = ref(null);

function getProductImage(item) {
  if (!item) return "/placeholder-image.jpg";

  if (item.image_details) {
    if (Array.isArray(item.image_details) && item.image_details.length > 0) {
      return item.image_details[0].image || "/placeholder-image.jpg";
    }
    if (typeof item.image_details === "string") {
      return item.image_details;
    }
  } else if (item.image) {
    return item.image;
  }

  return "/placeholder-image.jpg";
}

// Calculate discount percentage
function calculateDiscount(salePrice, originalPrice) {
  if (
    !salePrice ||
    !originalPrice ||
    parseFloat(originalPrice) <= parseFloat(salePrice)
  )
    return 0;
  const discount =
    ((parseFloat(originalPrice) - parseFloat(salePrice)) /
      parseFloat(originalPrice)) *
    100;
  return Math.round(discount);
}

// Cart functionality with improved loading handling
function addToCart(item, qty = 1) {
  // Set loading state for this specific product
  loadingStates.value[item.id] = true;

  try {
    // Simulate network delay (remove in production)
    setTimeout(() => {
      cart.addProduct(item, qty);
      navigateTo("/checkout/");

      // Clear loading state if navigation fails
      loadingStates.value[item.id] = false;
    }, 800); // Simulate network latency
  } catch (error) {
    console.error("Error adding to cart:", error);
    const toast = useToast();
    toast.add({
      title: "Network Error",
      description: "Please check your internet connection and try again.",
      color: "red",
    });

    // Clear loading state on error
    loadingStates.value[item.id] = false;
  }
}

// Product modal functions
function openProductModal(product) {
  // If this product card is inside a modal, emit event to parent instead of opening new modal
  if (isInModal && onModalProductChange) {
    onModalProductChange(product);
    return;
  }

  // If this product card is inside a modal but no handler provided, emit event
  if (isInModal) {
    emit("updateModalProduct", product);
    return;
  }

  // Normal behavior for product cards not in modal
  selectedProduct.value = product;
  quantity.value = 1;
  isModalOpen.value = true;
}

function closeProductModal() {
  isModalOpen.value = false;
}

function updateModalProduct(newProduct) {
  // Close current modal first
  isModalOpen.value = false;

  // After modal close animation completes, open with new product
  setTimeout(() => {
    selectedProduct.value = newProduct;
    quantity.value = 1;
    isModalOpen.value = true;
  }, 250); // Match the modal leave transition duration
}

async function increaseProductViews() {
  try {
    const { data } = await patch(`/products/${product.slug}/`, {
      views: product.views + 1,
    });
  } catch (error) {
    console.error(error);
  }
}

onMounted(() => {
  const observer = new IntersectionObserver(
    (entries) => {
      if (entries[0].isIntersecting && !product.viewIncremented) {
        product.viewIncremented = true;

        setTimeout(() => {
          increaseProductViews();
        }, 500);

        observer.disconnect();
      }
    },
    {
      threshold: 0.5, // Trigger when at least 50% of the product is visible
      rootMargin: "0px", // No margin around the viewport
    }
  );

  // Start observing the product card element
  if (productCardRef.value) {
    observer.observe(productCardRef.value);
  }

  // Cleanup observer on component unmount
  onUnmounted(() => {
    if (observer) {
      observer.disconnect();
    }
  });
});
</script>

<style scoped>
/* Optimized and minified CSS for better performance */
:root {
  --primary-400: #38bdf8;
  --primary-500: #0ea5e9;
  --primary-600: #0284c7;
}
</style>
