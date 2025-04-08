<template>
  <div>
    <div class="product-card relative group">
      <!-- Product Card Content -->
      <div
        class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden shadow-sm md:hover:shadow-md transition-all duration-300 h-full flex flex-col"
      >
        <!-- Product Image Section -->
        <div class="relative pt-[100%] overflow-hidden group">
          <!-- Discount Badge -->
          <div
            v-if="product.regular_price"
            class="absolute top-2 left-2 z-10 px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-full"
          >
            -{{ calculateDiscount(product.sale_price, product.regular_price) }}%
          </div>

          <!-- Product Image -->
          <img
            :src="getProductImage(product)"
            :alt="product.name"
            class="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-700 ease-out md:group-hover:scale-105"
          />

          <!-- Quick View Button -->
          <div
            class="absolute inset-0 bg-black/0 md:group-hover:bg-black/20 flex items-center justify-center transition-all duration-300 opacity-0 md:group-hover:opacity-100"
          >
            <UButton
              @click="openProductModal(product)"
              class="px-3 py-1.5 bg-green-800/90 dark:bg-slate-800/90 backdrop-blur-sm text-sm font-medium rounded-lg"
            >
              Quick View
            </UButton>
          </div>
        </div>

        <!-- Product Details -->
        <div class="p-3 flex-grow flex flex-col">
          <!-- Product Title -->
          <NuxtLink :to="`/product-details/${product.id}`">
            <h3
              class="font-medium text-green-950 dark:text-white mb-1 line-clamp-2 flex-grow text-base first-letter:uppercase"
            >
              {{ product.name }}
            </h3>
          </NuxtLink>
          <NuxtLink
            :to="`/eshop/${
              product?.owner_details?.store_username ||
              product?.owner?.store_username
            }`"
            class="text-blue-400 text-sm mb-1.5 inline-flex items-center gap-1 cursor-pointer"
          >
            <UIcon
              name="i-material-symbols-storefront-outline-rounded"
              class="size-4"
            />
            <span>
              {{
                product?.owner_details?.store_name || product?.owner?.store_name
              }}
            </span>
          </NuxtLink>
          <!-- Rating -->
          <!-- <div class="flex items-center gap-1 mb-1.5">
          <div class="flex">
            <UIcon
              v-for="n in 5"
              :key="n"
              :name="
                n <= Math.floor(product.rating || 0)
                  ? 'i-heroicons-star-solid'
                  : 'i-heroicons-star'
              "
              class="w-3.5 h-3.5"
              :class="
                n <= Math.floor(product.rating || 0)
                  ? 'text-yellow-400'
                  : 'text-gray-200'
              "
            />
          </div>
          <span class="text-xs text-slate-500 dark:text-slate-400">
            ({{ product.reviews?.length || 0 }})
          </span>
        </div> -->

          <!-- Price -->
          <div class="flex items-center justify-between">
            <div class="flex flex-col gap-1">
              <span class="font-semibold text-slate-800 dark:text-white">
                ৳{{ product.sale_price }}
              </span>
              <span
                v-if="product.regular_price"
                class="text-xs text-slate-400 line-through"
              >
                ৳{{ product.regular_price }}
              </span>
            </div>
            <UButton
              size="sm"
              color="primary"
              :icon="
                !loadingStates[product.id] ? 'i-heroicons-shopping-cart' : ''
              "
              :trailing="false"
              class="rounded-full"
              @click="addToCart(product, quantity)"
              :loading="loadingStates[product.id]"
              :disabled="loadingStates[product.id]"
            >
              {{ !loadingStates[product.id] ? "Buy" : "" }}
            </UButton>
          </div>
        </div>
      </div>
    </div>
    <Teleport to="body">
      <!-- Backdrop with blur effect and fade animation -->
      <div
        v-if="isModalOpen"
        class="fixed inset-0 bg-gray-900/60 dark:bg-gray-900/80 backdrop-blur-sm z-50 flex items-start justify-center overflow-y-auto"
        :class="{ 'animate-fade-in': isModalOpen }"
        @click="closeOnBackdrop ? $emit('update:modelValue', false) : null"
      >
        <!-- Modal container with animations -->
        <div
          class="relative flex flex-col w-full max-w-3xl mt-28 sm:mt-24 mb-10 sm:h-[750px] bg-white/95 dark:bg-gray-800/95 backdrop-blur-md rounded-xl shadow-2xl border border-white/20 dark:border-gray-700/50 overflow-hidden"
          :class="{ 'animate-modal-slide-up': isModalOpen }"
          @click.stop
          ref="modalRef"
        >
          <!-- Close button with hover effect -->

          <!-- Modal content with custom scrollbar -->
          <div
            class="w-full h-full overflow-hidden overflow-y-auto custom-scrollbar"
          >
            <CommonProductDetailsCard
              :current-product="selectedProduct"
              :modal="true"
              @close-modal="closeProductModal"
            />
          </div>

          <!-- Decorative elements -->
          <div
            class="absolute top-0 right-0 w-64 h-64 bg-primary-400/10 dark:bg-primary-400/5 rounded-full filter blur-3xl -z-10 transform translate-x-1/4 -translate-y-1/4"
          ></div>
          <div
            class="absolute bottom-0 left-0 w-64 h-64 bg-violet-400/10 dark:bg-violet-400/5 rounded-full filter blur-3xl -z-10 transform -translate-x-1/4 translate-y-1/4"
          ></div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
const { product } = defineProps({ product: { type: Object, required: true } });
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);

const loadingStates = ref({});
const cart = useStoreCart();

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
  if (!salePrice || !originalPrice) return 0;
  const discount = ((originalPrice - salePrice) / originalPrice) * 100;
  return Math.round(discount);
}

// Cart functionality
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

// Product modal
function openProductModal(product) {
  selectedProduct.value = product;
  quantity.value = 1;
  isModalOpen.value = true;
}

function closeProductModal() {
  isModalOpen.value = false;
}
</script>

<style scoped>
/* Minimal styling for core functionality */
.product-card {
  transition: transform 0.3s ease;
}

.product-card:hover {
  transform: translateY(-4px);
}

/* Custom scrollbar styling */
.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 20px;
}

.dark .custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(75, 85, 99, 0.5);
}

/* Animations */
@keyframes fade-in {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes modal-slide-up {
  from {
    opacity: 0;
    transform: translateY(30px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.animate-fade-in {
  animation: fade-in 0.3s ease-out forwards;
}

.animate-modal-slide-up {
  animation: modal-slide-up 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

/* Custom colors */
:root {
  --primary-400: #38bdf8;
  --primary-500: #0ea5e9;
}
</style>
