<template>
  <div v-if="selectedDivision && (loading || error || products.length > 0)" class="bg-white rounded-lg shadow-sm border border-gray-200 py-4 mt-4">    
    <div class="flex-block items-center justify-between px-2 mb-4">
      <h3 class="text-lg mb-3 font-medium text-gray-800">
        <Icon name="heroicons:shopping-bag" class="w-5 h-5 inline mr-2 text-blue-600" />
        {{ selectedDivision }} বিভাগের গুরুত্বপূর্ণ বই ও শিক্ষা সামগ্রী
      </h3>
      <span class="bg-blue-100 text-blue-700 text-sm px-2 py-1 rounded-full">
        {{ selectedDivision }}
      </span>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="flex justify-center items-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
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

    <!-- Products horizontal scroll -->
    <div v-else class="relative">
      <!-- Scroll buttons for desktop -->
      <button
        v-if="canScrollLeft"
        @click="scrollLeft"
        class="hidden md:flex absolute left-0 top-1/2 -translate-y-1/2 z-10 items-center justify-center w-8 h-8 bg-white border border-gray-200 rounded-full shadow-sm hover:shadow-md transition-all duration-200"
        aria-label="Scroll left"
      >
        <Icon name="heroicons:chevron-left" class="w-4 h-4 text-gray-600" />
      </button>
      
      <button
        v-if="canScrollRight"
        @click="scrollRight"
        class="hidden md:flex absolute right-0 top-1/2 -translate-y-1/2 z-10 items-center justify-center w-8 h-8 bg-white border border-gray-200 rounded-full shadow-sm hover:shadow-md transition-all duration-200"
        aria-label="Scroll right"
      >
        <Icon name="heroicons:chevron-right" class="w-4 h-4 text-gray-600" />
      </button>

      <!-- Scrollable products container -->
      <div 
        ref="scrollContainer"
        class="flex gap-2 overflow-x-auto scroll-smooth scrollbar-hide px-2 py-2"
        @scroll="updateScrollButtons"
      >
        <div 
          v-for="product in randomizedProducts" 
          :key="product.id"
          class="flex-shrink-0 w-48 sm:w-52"
        >
          <ProductCard 
            :product="product"
            :compact="true"
          />
        </div>
      </div>

      <!-- View all products link -->
      <div v-if="products.length > 0" class="mt-4 text-center">
        <NuxtLink
          :to="`/eshop/category/${selectedDivision}`"
          class="inline-flex items-center gap-2 text-sm text-blue-600 hover:text-blue-700 font-medium"
        >
          {{ $t('view_all_products') }}
          <Icon name="heroicons:arrow-right" class="w-4 h-4" />
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed, onMounted, nextTick } from 'vue'
import { fetchDivisionProducts } from '~/services/elearningApi'
import ProductCard from '~/components/common/product-card.vue'

const props = defineProps({
  selectedDivision: {
    type: String,
    default: null
  }
})

const config = useRuntimeConfig()
const products = ref([])
const loading = ref(false)
const error = ref(null)
const scrollContainer = ref(null)
const canScrollLeft = ref(false)
const canScrollRight = ref(false)

// Randomize products array
const randomizedProducts = computed(() => {
  if (!products.value.length) return []
  
  // Create a copy and shuffle it
  const shuffled = [...products.value]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
})

// Scroll functions
function scrollLeft() {
  if (scrollContainer.value) {
    const scrollAmount = 240 // Approximate width of one product card
    scrollContainer.value.scrollBy({ 
      left: -scrollAmount, 
      behavior: 'smooth' 
    })
  }
}

function scrollRight() {
  if (scrollContainer.value) {
    const scrollAmount = 240 // Approximate width of one product card
    scrollContainer.value.scrollBy({ 
      left: scrollAmount, 
      behavior: 'smooth' 
    })
  }
}

function updateScrollButtons() {
  if (!scrollContainer.value) return
  
  const { scrollLeft, scrollWidth, clientWidth } = scrollContainer.value
  canScrollLeft.value = scrollLeft > 0
  canScrollRight.value = scrollLeft < scrollWidth - clientWidth - 1
}

// Load products when division changes
watch(() => props.selectedDivision, (newDivision) => {
  if (newDivision) {
    loadProducts()
  } else {
    products.value = []
  }
}, { immediate: true })

async function loadProducts() {
  if (!props.selectedDivision) return

  try {
    loading.value = true
    error.value = null

    const fetchedProducts = await fetchDivisionProducts(config.public.baseURL, props.selectedDivision, {
      limit: 50 // Get all available products for the division
    })

    products.value = fetchedProducts || []
    
    // Update scroll buttons after products are loaded
    await nextTick()
    updateScrollButtons()
  } catch (err) {
    console.error('Error loading division products:', err)
    error.value = 'Failed to load products'
    products.value = []
  } finally {
    loading.value = false
  }
}

// Initialize scroll buttons on mount
onMounted(() => {
  if (scrollContainer.value) {
    updateScrollButtons()
  }
})
</script>

<style scoped>
/* Hide scrollbar for Chrome, Safari and Opera */
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

/* Hide scrollbar for IE, Edge and Firefox */
.scrollbar-hide {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}

/* Smooth scrolling behavior */
.scroll-smooth {
  scroll-behavior: smooth;
}
</style>
