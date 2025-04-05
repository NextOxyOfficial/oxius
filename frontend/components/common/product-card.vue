<template>
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
            @click="openModal(product)"
            class="px-3 py-1.5 bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm text-sm font-medium rounded-lg"
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
            class="font-medium text-slate-800 dark:text-white mb-1 line-clamp-2 flex-grow text-base"
          >
            {{ product.name }}
          </h3>
        </NuxtLink>
        <NuxtLink
          :to="`https://adsyclub.com/eshop/${product?.owner_details?.store_username}`"
          class="text-blue-400 text-sm mb-1.5 inline-flex items-center gap-1 cursor-pointer"
        >
          <UIcon
            name="i-material-symbols-storefront-outline-rounded"
            class="size-4"
          />
          <span>
            {{ product?.owner_details?.store_name }}
          </span>
        </NuxtLink>
        <!-- Rating -->
        <div class="flex items-center gap-1 mb-1.5">
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
        </div>

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
            @click="addToCart(product)"
            :loading="loadingStates[product.id]"
            :disabled="loadingStates[product.id]"
          >
            {{ !loadingStates[product.id] ? "Buy" : "" }}
          </UButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { product } = defineProps({ product: { type: Object, required: true } });

const emit = defineEmits(["open-modal"]);

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

function openModal(item) {
  emit("open-modal", item);
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
</style>
