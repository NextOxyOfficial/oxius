<template>
  <div class="sponsored-products-section">
    <h2 class="text-lg font-semibold text-gray-800 mb-4">Sponsored Products</h2>
    <div class="relative">
      <!-- Custom Positioning for Mobile -->
      <div class="mobile-layout !lg:hidden !sm:hidden">
        <CommonProductCard
          v-for="(product, productIndex) in products"
          :key="`mobile-${product.id || productIndex}`"
          :product="product"
          class="product-card"
        />
      </div>

      <!-- Custom Positioning for Desktop -->
      <div class="desktop-layout hidden !lg:block">
        <CommonProductCard
          v-for="(product, productIndex) in products"
          :key="`desktop-${product.id || productIndex}`"
          :product="product"
          class="product-card"
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
  padding: 8px;
  margin: 0 auto;
  border-radius: 10px;
  box-shadow: 0 3px 5px rgba(0, 0, 0, 0.08);
  margin-top: 20px;
  width: 100%;
  box-sizing: border-box;
  overflow-x: hidden;
}

/* Custom Positioning for Mobile */
.mobile-layout {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
}

.mobile-layout .product-card {
  width: 49%;
  margin-bottom: 10px;
}

/* Custom Positioning for Desktop */
.desktop-layout {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
}

.desktop-layout .product-card {
  width: 30%;
  margin-bottom: 15px;
}
</style>
