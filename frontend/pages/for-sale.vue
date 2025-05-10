<template>
  <div class="for-sale-page">
    <div class="hero-section bg-gradient-to-r from-primary to-primary-dark text-white py-12">
      <div class="container mx-auto px-4">
        <h1 class="text-3xl md:text-4xl font-bold mb-4">Browse Items For Sale</h1>
        <p class="text-xl opacity-90 mb-6">Find great deals on local items or list your own for sale</p>
        
        <div class="search-container max-w-2xl bg-white rounded-lg overflow-hidden shadow-lg flex items-center">
          <input 
            type="text" 
            placeholder="Search for items..." 
            class="flex-1 px-6 py-4 text-gray-700 focus:outline-none"
          >
          <button class="bg-primary hover:bg-primary-dark text-white px-6 py-4 transition-colors">
            <Icon name="heroicons:magnifying-glass" size="24px" />
          </button>
        </div>
      </div>
    </div>
    
    <ForSale />
    
    <div class="featured-items-section py-12 bg-gray-50">
      <div class="container mx-auto px-4">
        <h2 class="text-2xl md:text-3xl font-bold text-center mb-8">Featured Items</h2>
        
        <!-- Featured items grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div v-for="i in 4" :key="i" class="card bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
            <div class="relative">
              <div class="h-48 bg-gray-200"></div>
              <span class="absolute top-3 left-3 bg-primary text-white text-sm py-1 px-2 rounded">Featured</span>
            </div>
            <div class="p-4">
              <h3 class="font-bold text-lg mb-2">Product Name</h3>
              <div class="flex justify-between items-center">
                <span class="text-primary font-bold">$99.99</span>
                <span class="text-sm text-gray-500">Posted 2 days ago</span>
              </div>
              <p class="text-gray-600 mt-2 line-clamp-2">Short description of the item for sale, showing only two lines maximum.</p>
              <div class="flex justify-between items-center mt-4">
                <span class="text-sm flex items-center">
                  <Icon name="heroicons:map-pin" size="16px" class="mr-1" />
                  New York
                </span>
                <button class="text-primary hover:underline font-medium">View Details</button>
              </div>
            </div>
          </div>
        </div>
        
        <div class="text-center mt-8">
          <button class="bg-primary hover:bg-primary-dark text-white px-6 py-3 rounded-lg font-medium transition-colors">
            View All Items
          </button>
        </div>
      </div>
    </div>
    
    <div class="sell-cta-section py-12 bg-gray-100">
      <div class="container mx-auto px-4 max-w-4xl text-center">
        <h2 class="text-2xl md:text-3xl font-bold mb-4">Have Something To Sell?</h2>
        <p class="text-gray-600 mb-8 text-lg">List your items quickly and easily, and reach thousands of potential buyers.</p>
        
        <div class="grid md:grid-cols-3 gap-6 mb-8">
          <div class="feature p-4">
            <div class="icon-wrapper mx-auto bg-primary/10 p-4 rounded-full mb-4 w-16 h-16 flex items-center justify-center">
              <Icon name="heroicons:photo" size="24px" class="text-primary" />
            </div>
            <h3 class="font-bold mb-2">Add Photos</h3>
            <p class="text-gray-600">Upload clear photos to attract more buyers</p>
          </div>
          
          <div class="feature p-4">
            <div class="icon-wrapper mx-auto bg-primary/10 p-4 rounded-full mb-4 w-16 h-16 flex items-center justify-center">
              <Icon name="heroicons:document-text" size="24px" class="text-primary" />
            </div>
            <h3 class="font-bold mb-2">Describe Item</h3>
            <p class="text-gray-600">Add details to help buyers find your listing</p>
          </div>
          
          <div class="feature p-4">
            <div class="icon-wrapper mx-auto bg-primary/10 p-4 rounded-full mb-4 w-16 h-16 flex items-center justify-center">
              <Icon name="heroicons:currency-dollar" size="24px" class="text-primary" />
            </div>
            <h3 class="font-bold mb-2">Set Price</h3>
            <p class="text-gray-600">Choose a competitive price to sell quickly</p>
          </div>
        </div>
        
        <button class="bg-primary hover:bg-primary-dark text-white px-8 py-4 rounded-lg font-bold text-lg transition-colors">
          Post an Item for Sale
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import ForSale from '~/components/common/SaleCategory.vue';
</script>

<style scoped>
.hero-section {
  position: relative;
}

.hero-section::after {
  content: '';
  position: absolute;
  bottom: -20px;
  left: 0;
  right: 0;
  height: 40px;
  background: linear-gradient(to bottom right, transparent 50%, #fff 50%);
}
</style>