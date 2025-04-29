<template>
  <div class="sponsored-products-section">
    <h2 class="text-lg font-semibold text-gray-800 mb-4">Sponsored Products</h2>
    <div class="relative">
      <!-- Carousel Container for Mobile -->
      <div class="carousel flex overflow-x-auto gap-2 my-2 pb-2 lg:hidden sm:hidden">
        <CommonProductCard
          v-for="(product, productIndex) in products"
          :key="`mobile-${product.id || productIndex}`"
          :product="product"
          class="flex-shrink-0 w-[49%]"
        />
      </div>

      <!-- Grid Layout for Desktop -->
      <div class="hidden lg:hidden sm:grid sm:grid-cols-3 my-2 gap-4">
        <CommonProductCard
          v-for="(product, productIndex) in products"
          :key="`desktop-${product.id || productIndex}`"
          :product="product"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  products: {
    type: Array,
    required: true,
  },
});
</script>

<style scoped>
.sponsored-products-section {
  background-color: #f9f9f9;
  padding: 15px;
  margin: 0 auto;
  border-radius: 10px;
  box-shadow: 0 3px 5px rgba(0, 0, 0, 0.08);
  margin-top: 20px;
  width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}

/* Hide scrollbar for mobile screens and ensure no overflow */
.carousel {
  -ms-overflow-style: none;
  scrollbar-width: none;
  max-width: 100%;
  box-sizing: border-box;
  padding-bottom: 5px;
}

.carousel::-webkit-scrollbar {
  display: none;
}
</style>
