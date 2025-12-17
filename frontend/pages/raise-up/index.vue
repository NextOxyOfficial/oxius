<template>
  <div class="min-h-screen bg-gray-50 dark:bg-slate-900">
    <!-- Container -->
    <div class="max-w-7xl mx-auto px-2 lg:px-8 py-4 sm:py-6">
      <!-- Breadcrumb - Hidden on mobile -->
      <nav class="hidden sm:flex items-center gap-2 text-sm mb-4 sm:mb-6">
        <NuxtLink to="/" class="text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition">
          Home
        </NuxtLink>
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-slate-400" />
        <span class="text-gray-900 dark:text-white font-medium">Raise Up</span>
      </nav>

      <!-- Mobile Back -->
      <div class="sm:hidden flex items-center gap-2 mb-4">
        <NuxtLink to="/" class="inline-flex items-center gap-1.5 text-sm text-slate-600 dark:text-slate-400">
          <UIcon name="i-heroicons-arrow-left" class="w-4 h-4" />
          Home
        </NuxtLink>
      </div>

      <!-- Header Bar -->
      <div class="flex items-center justify-between gap-4 mb-4 sm:mb-6">
        <div class="flex items-center gap-2.5 sm:gap-3">
          <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-lg bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shrink-0 shadow-lg shadow-purple-500/25">
            <UIcon name="i-heroicons-rocket-launch" class="w-4 h-4 sm:w-5 sm:h-5 text-white" />
          </div>
          <h1 class="text-base sm:text-lg lg:text-xl font-bold text-gray-900 dark:text-white">
            Raise Up
          </h1>
        </div>
        <NuxtLink
          to="/raise-up/create"
          class="inline-flex items-center justify-center gap-1.5 px-3 sm:px-4 py-1.5 sm:py-2 rounded-full bg-gradient-to-r from-purple-500 to-indigo-600 text-white text-xs sm:text-sm font-semibold shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40 hover:scale-[1.02] transition-all duration-200"
        >
          <UIcon name="i-heroicons-plus" class="w-3.5 h-3.5 sm:w-4 sm:h-4" />
          <span class="hidden sm:inline">Post Your Idea</span>
          <span class="sm:hidden">Post</span>
        </NuxtLink>
      </div>

      <!-- Banner Slider -->
      <div class="mb-4 sm:mb-6 rounded-xl sm:rounded-2xl overflow-hidden relative">
        <div 
          class="flex transition-transform duration-500 ease-out"
          :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
        >
          <div 
            v-for="(banner, idx) in banners" 
            :key="idx"
            class="w-full shrink-0 relative aspect-[2.5/1] sm:aspect-[3.5/1] lg:aspect-[4/1]"
          >
            <img 
              :src="banner.image" 
              :alt="banner.title"
              class="absolute inset-0 w-full h-full object-cover"
            />
            <div class="absolute inset-0 bg-gradient-to-r from-purple-900/80 via-indigo-900/60 to-transparent"></div>
            <div class="absolute inset-0 flex items-center">
              <div class="px-4 sm:px-6 lg:px-8 max-w-lg">
                <h2 class="text-white text-sm sm:text-lg lg:text-xl font-bold mb-1 sm:mb-2 line-clamp-2">
                  {{ banner.title }}
                </h2>
                <p class="text-purple-100 text-[10px] sm:text-xs lg:text-sm line-clamp-2 hidden sm:block">
                  {{ banner.subtitle }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Slider Controls -->
        <button 
          v-if="banners.length > 1"
          type="button"
          class="absolute left-2 top-1/2 -translate-y-1/2 w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center text-white hover:bg-white/30 transition"
          @click="prevSlide"
        >
          <UIcon name="i-heroicons-chevron-left" class="w-4 h-4 sm:w-5 sm:h-5" />
        </button>
        <button 
          v-if="banners.length > 1"
          type="button"
          class="absolute right-2 top-1/2 -translate-y-1/2 w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center text-white hover:bg-white/30 transition"
          @click="nextSlide"
        >
          <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 sm:w-5 sm:h-5" />
        </button>

        <!-- Dots -->
        <div v-if="banners.length > 1" class="absolute bottom-2 sm:bottom-3 left-1/2 -translate-x-1/2 flex items-center gap-1.5">
          <button
            v-for="(_, idx) in banners"
            :key="idx"
            type="button"
            class="w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full transition-all duration-300"
            :class="idx === currentSlide ? 'bg-white w-4 sm:w-5' : 'bg-white/50 hover:bg-white/70'"
            @click="currentSlide = idx"
          ></button>
        </div>
      </div>

      <!-- Warning/Disclaimer Banner -->
      <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800/50 rounded-xl p-3 sm:p-4 mb-4 sm:mb-6">
        <div class="flex gap-2.5 sm:gap-3">
          <div class="shrink-0">
            <UIcon name="i-heroicons-exclamation-triangle" class="w-4 h-4 sm:w-5 sm:h-5 text-amber-500" />
          </div>
          <div>
            <h3 class="text-xs sm:text-sm font-semibold text-amber-800 dark:text-amber-200 mb-0.5">Investment Risk Warning</h3>
            <p class="text-[11px] sm:text-xs text-amber-700 dark:text-amber-300 leading-relaxed">
              Investing in early-stage businesses involves significant risk. You may lose some or all of your investment. 
              Only invest money you can afford to lose. Past performance is not indicative of future results.
            </p>
          </div>
        </div>
      </div>

      <!-- Featured Ideas Section -->
      <div class="mb-6 sm:mb-8">
        <!-- Section Title -->
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <h2 class="text-lg sm:text-xl font-bold text-gray-900 dark:text-white">
              {{ searchQuery || selectedStage ? 'Search Results' : 'Featured Ideas' }}
            </h2>
            <span class="px-2.5 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 text-sm font-medium rounded-full">
              {{ filteredPlans.length }}
            </span>
          </div>
          <button 
            v-if="searchQuery || selectedStage"
            type="button"
            class="text-sm text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 font-medium transition"
            @click="clearFilters"
          >
            Clear filters
          </button>
        </div>

        <!-- Search & Filter Bar -->
        <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-5 mb-6">
          <div class="flex flex-col lg:flex-row gap-4">
            <!-- Search Input -->
            <div class="flex-1 relative">
              <UIcon name="i-heroicons-magnifying-glass" class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search ideas by title, sector, or location..."
                class="w-full h-10 pl-12 pr-4 text-base bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-700 dark:text-slate-300 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition"
              />
            </div>
            <!-- Filters -->
            <div class="flex items-center gap-3">
              <select 
                v-model="selectedStage"
                class="h-10 text-base bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg px-4 text-slate-700 dark:text-slate-300 focus:outline-none focus:ring-2 focus:ring-purple-500 transition min-w-[140px]"
              >
                <option value="">All Stages</option>
                <option value="Seed">Seed</option>
                <option value="Early">Early</option>
                <option value="Growth">Growth</option>
              </select>
              <select 
                v-model="sortBy"
                class="h-10 text-base bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg px-4 text-slate-700 dark:text-slate-300 focus:outline-none focus:ring-2 focus:ring-purple-500 transition min-w-[160px]"
              >
                <option value="funded">Most Funded</option>
                <option value="newest">Newest</option>
                <option value="ending">Ending Soon</option>
              </select>
            </div>
          </div>
        </div> 

        <!-- Ideas Grid -->
        <div v-if="filteredPlans.length === 0" class="text-center py-12">
          <UIcon name="i-heroicons-magnifying-glass" class="w-12 h-12 text-slate-300 dark:text-slate-600 mx-auto mb-3" />
          <p class="text-slate-500 dark:text-slate-400 text-sm">No ideas found matching your criteria</p>
          <button 
            type="button"
            class="mt-2 text-purple-600 dark:text-purple-400 hover:underline text-sm"
            @click="clearFilters"
          >
            Clear filters to see all ideas
          </button>
        </div>
        
        <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 items-start">
          <IdeaCard
            v-for="plan in filteredPlans"
            :key="plan.id"
            :plan="plan"
          />
        </div>
      </div>

      <!-- Safety Tips Section -->
        <div class="bg-slate-100 dark:bg-slate-800/50 rounded-xl p-4 sm:p-5 mb-4 sm:mb-6">
          <div class="flex items-start gap-2.5 sm:gap-3 mb-3 sm:mb-4">
            <UIcon name="i-heroicons-shield-check" class="w-4 h-4 sm:w-5 sm:h-5 text-purple-600 dark:text-purple-400 shrink-0 mt-0.5" />
            <div>
              <h3 class="text-xs sm:text-sm font-bold text-gray-900 dark:text-white mb-0.5">Safety Tips for Investors</h3>
              <p class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Follow these guidelines to make informed investment decisions.</p>
            </div>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-1.5 sm:gap-2">
            <div class="flex items-start gap-2">
              <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
              <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Research the founder's background and track record</span>
            </div>
            <div class="flex items-start gap-2">
              <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
              <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Understand the business model and revenue plan</span>
            </div>
            <div class="flex items-start gap-2">
              <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
              <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Never invest more than you can afford to lose</span>
            </div>
            <div class="flex items-start gap-2">
              <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
              <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Diversify your investments across multiple ideas</span>
            </div>
          </div>
        </div>

        <!-- How It Works Section -->
        <div class="mb-4 sm:mb-6">
          <h2 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-3 sm:mb-4">How It Works</h2>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-2.5 sm:gap-3">
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
              <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                <UIcon name="i-heroicons-magnifying-glass" class="w-3.5 h-3.5 sm:w-4 sm:h-4 text-purple-600 dark:text-purple-400" />
              </div>
              <h3 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white mb-0.5">1. Discover</h3>
              <p class="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400">Browse verified business ideas from local entrepreneurs seeking funding.</p>
            </div>
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
              <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center mb-2">
                <UIcon name="i-heroicons-chat-bubble-left-right" class="w-3.5 h-3.5 sm:w-4 sm:h-4 text-indigo-600 dark:text-indigo-400" />
              </div>
              <h3 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white mb-0.5">2. Connect</h3>
              <p class="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400">Chat directly with founders to learn more about their vision and plans.</p>
            </div>
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
              <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
                <UIcon name="i-heroicons-banknotes" class="w-3.5 h-3.5 sm:w-4 sm:h-4 text-purple-600 dark:text-purple-400" />
              </div>
              <h3 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white mb-0.5">3. Support</h3>
              <p class="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400">Invest or donate to help bring promising ideas to life in your community.</p>
            </div>
          </div>
        </div>

        <!-- CTA Section -->
        <div class="bg-gradient-to-r from-purple-600 to-indigo-600 rounded-xl p-4 sm:p-6 text-white text-center">
          <h3 class="text-base sm:text-lg font-bold mb-2">Have a Business Idea?</h3>
          <p class="text-xs sm:text-sm text-purple-100 mb-4">Share your vision and get funding support from the community.</p>
          <NuxtLink
            to="/raise-up/create"
            class="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-white text-purple-600 text-sm font-semibold hover:shadow-lg transition"
          >
            <UIcon name="i-heroicons-light-bulb" class="w-5 h-5" />
            Submit Your Idea
          </NuxtLink>
        </div>
      </div>
    </div>
</template>

<script setup>
// Import the IdeaCard component
import IdeaCard from '~/components/raise-up/IdeaCard.vue'

// Use shared plans data
const { plans, loading, fetchAllPlans } = usePlans()

// Banner slider
const currentSlide = ref(0)
const banners = [
  {
    image: 'https://images.unsplash.com/photo-1559136555-9303baea8ebd?auto=format&fit=crop&w=1600&q=80',
    title: 'Support Local Entrepreneurs',
    subtitle: 'Invest in promising ideas and earn returns while making an impact in your community.'
  },
  {
    image: 'https://images.unsplash.com/photo-1553729459-efe14ef6055d?auto=format&fit=crop&w=1600&q=80',
    title: 'Grow Your Wealth',
    subtitle: 'Diversify your portfolio with early-stage investments in verified business ideas.'
  },
  {
    image: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1600&q=80',
    title: 'Make a Difference',
    subtitle: 'Your investment helps create jobs and drives economic growth in local communities.'
  }
]

const nextSlide = () => {
  currentSlide.value = (currentSlide.value + 1) % banners.length
}

const prevSlide = () => {
  currentSlide.value = (currentSlide.value - 1 + banners.length) % banners.length
}

// Auto-slide
let slideInterval = null
onMounted(() => {
  slideInterval = setInterval(nextSlide, 5000)
})
onUnmounted(() => {
  if (slideInterval) clearInterval(slideInterval)
})

// Search & Filter
const searchQuery = ref('')
const selectedStage = ref('')
const sortBy = ref('funded')

// Reactive data for API results
const allPlans = ref([])
const totalCount = ref(0)
const currentPage = ref(1)

const filteredPlans = computed(() => allPlans.value)

// Load plans from API
const loadPlans = async () => {
  try {
    const params = {
      page: currentPage.value,
      search: searchQuery.value || undefined,
      stage: selectedStage.value || undefined,
      sort_by: sortBy.value || undefined
    }
    
    const response = await fetchAllPlans(params)
    allPlans.value = response.results || []
    totalCount.value = response.count || 0
  } catch (error) {
    console.error('Error loading plans:', error)
    allPlans.value = []
  }
}

const clearFilters = () => {
  searchQuery.value = ''
  selectedStage.value = ''
  currentPage.value = 1
  loadPlans()
}

// Watch for filter changes (debounced)
let filterTimeout = null
watch([searchQuery, selectedStage, sortBy], () => {
  currentPage.value = 1
  if (filterTimeout) clearTimeout(filterTimeout)
  filterTimeout = setTimeout(() => {
    loadPlans()
  }, 300)
})

// Load initial data
onMounted(() => {
  loadPlans()
})
</script>
