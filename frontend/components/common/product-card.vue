<template>
  <div ref="productCardRef">
    <div class="transition-all duration-200">      <!-- Simplified Card Container -->      
       <div
        class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-lg overflow-hidden h-full flex flex-col"
      >        <!-- Product Image Section -->
        <div class="relative pt-[100%] overflow-hidden">
          <!-- Simplified Discount Badge -->
          <div
            v-if="
              product.regular_price &&
              calculateDiscount(product.sale_price, product.regular_price) > 0
            "
            class="absolute top-2 left-2 z-20"
          >
            <div class="px-2 py-1 bg-red-500 rounded text-white text-xs font-semibold flex items-center">
              <UIcon name="i-heroicons-bolt" class="size-3 mr-1" />
              <span>{{
                calculateDiscount(product.sale_price, product.regular_price)
              }}% OFF</span>
            </div>
          </div>          <!-- Simplified Free Delivery Badge -->
          <div
            v-if="product.is_free_delivery"
            class="absolute bottom-2 left-2 z-20"
          >
            <div class="px-2 py-1 bg-green-500 rounded text-white text-xs font-semibold flex items-center">
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
          <div class="absolute inset-0 z-10 flex items-center justify-center opacity-0 bg-gray-100 hover:opacity-100 transition-opacity">
            <button
              @click="openProductModal(product)"
              class="px-3 py-2 bg-white dark:bg-slate-900 text-sm font-medium rounded shadow-sm flex items-center"
            >
              <UIcon name="i-heroicons-eye" class="mr-2 size-4" />
              <span>Quick View</span>
            </button>
          </div>
        </div>        <!-- Product Details -->
        <div class="my-2 px-2 flex-grow flex flex-col">
          <!-- Simplified Store Link -->
          <NuxtLink
            :to="`/eshop/${
              product?.owner_details?.store_username ||
              product?.owner?.store_username
            }`"
            class="text-primary-500 text-sm mb-1.5 inline-flex items-center gap-1 hover:text-primary-600"
          >
            <div class="flex items-center justify-center size-4 bg-primary-50 rounded">
              <UIcon
                name="i-material-symbols-storefront-outline-rounded"
                class="size-3"
              />
            </div>
            <span class="line-clamp-1 font-medium">
              {{
                product?.owner_details?.store_name ||
                product?.owner?.store_name ||
                "Store"
              }}
            </span>
          </NuxtLink>          <!-- Simplified Product Title -->
          <NuxtLink :to="`/product-details/${product?.slug}`" class="">
            <h3 class="font-medium text-gray-800 dark:text-white mb-2 line-clamp-2 flex-grow text-sm h-12 text-left">
              {{ product.name }}
            </h3>
          </NuxtLink>          
          <!-- Simplified Price Section -->
          <div class="flex justify-between mt-auto border-t border-gray-200 dark:border-slate-700 mr-0.5 sm:mr-3">
            <!-- Price Section -->
            <div class="flex flex-col h-10">
              <span class="font-semibold text-gray-800 dark:text-white text-base flex items-center">
                <span class="text-xs mr-1 text-slate-500">৳</span>{{
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
                class="text-xs text-slate-400 line-through -mt-0.5 flex items-center"
              >
                <span class="text-xs mr-0.5">৳</span>{{ product.regular_price }}
              </span>
            </div>

            <!-- Simplified Buy Button -->
            <button
              :disabled="loadingStates[product.id]"
              class="flex items-center justify-center gap-1 px-1.5 font-medium text-white bg-primary-500 hover:bg-primary-600 rounded h-[24px] min-w-[50px] disabled:opacity-70"
              @click="addToCart(product, quantity)"
            >
              <span v-if="!loadingStates[product.id]">
                <UIcon name="i-heroicons-shopping-cart" class="size-4 mr-1" />
                <span class="text-sm">Buy</span>
              </span>
              <span v-else class="text-sm">...</span>
            </button>
          </div>
        </div>
      </div>
    </div>        <!-- Simplified Product Details Modal -->       
     <UModal
      v-model="isModalOpen"
      :ui="{
        width: 'w-full sm:max-w-4xl',
        height: 'h-auto',
        container: 'flex flex-col h-auto mt-20 p-0 sm:p-0',
        padding: 'p-0'
      }"
    >
    <div>
      <div class="bg-white dark:bg-slate-800 rounded-xl"
      >        <CommonProductDetailsCard
          :current-product="selectedProduct"
          :modal="true"
          :seeDetails="true"
          @close-modal="closeProductModal"
        />
      </div>
    </div>
    </UModal>
  </div>
</template>

<script setup>
const { patch } = useApi();
const { product } = defineProps({ product: { type: Object, required: true } });
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
  selectedProduct.value = product;
  quantity.value = 1;
  isModalOpen.value = true;
}

function closeProductModal() {
  isModalOpen.value = false;
}

async function increaseProductViews() {
  console.log(product.views);
  try {
    const { data } = await patch(`/products/${product.slug}/`, {
      views: product.views + 1,
    });
    console.log("patch", data);
  } catch (error) {
    console.log(error);
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
:root{--primary-400:#38bdf8;--primary-500:#0ea5e9;--primary-600:#0284c7}
</style>
