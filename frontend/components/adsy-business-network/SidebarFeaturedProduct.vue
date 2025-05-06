<template>
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
          @click="$emit('refresh')"
        >
          <RefreshCw class="h-3 w-3" />
        </button>
      </div>
    </h3>
    <div class="px-3 relative">
      <div
        v-if="isLoading"
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
          v-if="product"
          :href="`/product-details/${product.slug}`"
          class="block w-full h-full"
          @click.prevent="$emit('navigation', `/product-details/${product.slug}`)"
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
                  >৳
                  {{
                    product.sale_price &&
                    parseFloat(product.sale_price) > 0
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
                  class="text-xs bg-red-500 text-white px-1.5 py-0.5 rounded-sm"
                  >{{ calculateDiscount(product) }}% OFF</span
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
  </div>
</template>

<script setup>
import { ShoppingBag, RefreshCw } from "lucide-vue-next";

const props = defineProps({
  product: {
    type: Object,
    default: () => null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  }
});

const emit = defineEmits(['refresh', 'navigation']);

// Calculate discount percent
const calculateDiscount = (product) => {
  if (!product.sale_price || !product.regular_price) return 0;

  const regular = parseFloat(product.regular_price);
  const sale = parseFloat(product.sale_price);

  if (regular <= 0 || sale <= 0) return 0;

  return Math.round(((regular - sale) / regular) * 100);
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
</script>

<style scoped>
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-clamp: 1; /* Standard property for compatibility */
}
</style>