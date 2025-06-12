<template>
  <div v-if="selectedBatch" class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mt-4">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-medium text-gray-800">
        <Icon name="heroicons:shopping-bag" class="w-5 h-5 inline mr-2 text-emerald-600" />
        {{ $t('recommended_products') }}
      </h3>
      <span class="bg-emerald-100 text-emerald-700 text-sm px-2 py-1 rounded-full">
        {{ selectedBatch }}
      </span>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="flex justify-center items-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-emerald-500"></div>
    </div>

    <!-- Error state -->
    <div
      v-else-if="error"
      class="bg-red-50 border border-red-200 rounded-md p-4 text-center"
    >
      <p class="text-sm text-red-600">{{ error }}</p>
      <button
        @click="loadProducts"
        class="mt-2 text-sm text-blue-600 hover:underline"
      >
        {{ $t('try_again') }}
      </button>
    </div>

    <!-- No products state -->
    <div
      v-else-if="products.length === 0"
      class="text-center py-8 text-gray-500"
    >
      <Icon name="heroicons:shopping-bag" class="w-12 h-12 mx-auto mb-2 text-gray-300" />
      <p class="text-sm">{{ $t('no_products_available') }}</p>
    </div>

    <!-- Products grid -->
    <div v-else>
      <!-- Mobile: 2x2 grid -->
      <div class="grid grid-cols-2 gap-3 sm:hidden">
        <ProductCard 
          v-for="product in products.slice(0, 4)" 
          :key="product.id" 
          :product="product"
          :compact="true"
        />
      </div>

      <!-- Desktop: 1x5 grid -->
      <div class="hidden sm:grid sm:grid-cols-5 gap-4">
        <ProductCard 
          v-for="product in products.slice(0, 5)" 
          :key="product.id" 
          :product="product"
          :compact="true"
        />
      </div>

      <!-- View all products link -->
      <div v-if="products.length > 0" class="mt-4 text-center">
        <NuxtLink
          :to="`/eshop/category/${selectedBatch}`"
          class="inline-flex items-center gap-2 text-sm text-emerald-600 hover:text-emerald-700 font-medium"
        >
          {{ $t('view_all_products') }}
          <Icon name="heroicons:arrow-right" class="w-4 h-4" />
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { fetchBatchProducts } from '~/services/elearningApi'
import ProductCard from '~/components/common/product-card.vue'

const props = defineProps({
  selectedBatch: {
    type: String,
    default: null
  }
})

const config = useRuntimeConfig()
const products = ref([])
const loading = ref(false)
const error = ref(null)

// Load products when batch changes
watch(() => props.selectedBatch, (newBatch) => {
  if (newBatch) {
    loadProducts()
  } else {
    products.value = []
  }
}, { immediate: true })

async function loadProducts() {
  if (!props.selectedBatch) return

  try {
    loading.value = true
    error.value = null

    const fetchedProducts = await fetchBatchProducts(config.public.baseURL, props.selectedBatch, {
      limit: 10 // Get enough products for mobile and desktop display
    })

    products.value = fetchedProducts || []
  } catch (err) {
    console.error('Error loading batch products:', err)
    error.value = 'Failed to load products'
    products.value = []
  } finally {
    loading.value = false
  }
}
</script>
