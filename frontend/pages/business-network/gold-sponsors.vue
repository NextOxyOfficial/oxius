<template>
  <div>
    <div class="container mx-auto py-8 px-4">
      <!-- Page header with gold gradient styling -->
      <div class="mb-8 text-center">
        <h1 class="text-2xl sm:text-3xl font-bold my-3 relative inline-block">
          <span class="text-gold-gradient">{{ $t('gold_sponsors') }}</span>
          <div class="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-amber-500/0 via-amber-500 to-amber-500/0"></div>
        </h1>
        <p class="text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
          Meet our prestigious gold sponsors who support and contribute to our business network community.
        </p>      </div>

      <!-- Gold Sponsors Grid -->
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 sm:gap-6">
        <!-- Loading state -->
        <template v-if="isLoading">
          <div v-for="i in 12" :key="i" class="animate-pulse">            <div class="flex flex-col items-center p-4 bg-white dark:bg-slate-800/90 rounded-xl border border-amber-100/50 dark:border-amber-900/30">
              <div class="w-20 h-20 rounded-full bg-amber-100 dark:bg-amber-900/30 mb-3 relative overflow-hidden">
                <div class="absolute inset-0 golden-border opacity-30"></div>
              </div>
              <div class="h-4 bg-amber-100 dark:bg-amber-900/30 rounded w-24"></div>
            </div>
          </div>
        </template>

        <!-- Error state -->
        <template v-else-if="error">
          <div class="col-span-full py-10">
            <div class="text-center text-amber-600 dark:text-amber-400 max-w-md mx-auto">
              <UIcon name="i-heroicons-exclamation-triangle" class="w-10 h-10 mx-auto mb-4" />
              <p class="text-lg font-medium mb-2">{{ error }}</p>
              <p class="text-gray-600 dark:text-gray-400">
                Please try again later or contact support if the problem persists.
              </p>
              <button 
                @click="fetchGoldSponsors"
                class="mt-4 px-4 py-2 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full hover:from-amber-600 hover:to-yellow-600 transition-all duration-300"
              >
                <UIcon name="i-heroicons-arrow-path" class="w-4 h-4 mr-2 inline" />
                Retry
              </button>
            </div>
          </div>
        </template>

        <!-- Empty state -->
        <template v-else-if="sponsors.length === 0">
          <div class="col-span-full py-10">
            <div class="text-center text-gray-600 dark:text-gray-400 max-w-md mx-auto">
              <UIcon name="i-heroicons-star" class="w-10 h-10 mx-auto mb-4 text-amber-400" />
              <p class="text-lg font-medium mb-2">No gold sponsors yet</p>
              <p>Be the first to become a gold sponsor and get featured prominently in our business network!</p>
              <NuxtLink 
                to="/contact"
                class="mt-4 inline-block px-4 py-2 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full hover:from-amber-600 hover:to-yellow-600 transition-all duration-300"
              >
                Contact Us
              </NuxtLink>
            </div>
          </div>
        </template>

        <!-- Gold Sponsors -->
        <template v-else>          <div 
            v-for="(sponsor, index) in sponsors" 
            :key="index"
            class="transform transition-all duration-300 hover:-translate-y-1"
          >
            <NuxtLink 
              :to="`/business-network/profile/${sponsor.id}`"
              class="flex flex-col items-center p-4 bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm rounded-xl border border-amber-100/50 dark:border-amber-900/30 hover:shadow-md group h-full"
            >
              <!-- Profile image with gold border -->
              <div class="relative mb-3">
                <div class="absolute inset-0 rounded-full golden-border"></div>
                <img 
                  :src="sponsor.image || '/static/frontend/avatar.png'" 
                  :alt="sponsor.name"
                  class="w-20 h-20 rounded-full object-cover border-2 border-white dark:border-slate-700 relative z-10"
                />
                <!-- Gold badge -->
                <div class="absolute -bottom-1 -right-1 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-6 h-6 flex items-center justify-center shadow-sm z-20 transform transition-transform group-hover:scale-110 group-hover:rotate-12">
                  <UIcon
                    name="i-heroicons-star"
                    class="w-4 h-4 text-white"
                  />
                </div>
              </div>
              
              <!-- Name with hover underline -->
              <h4 class="text-base font-medium text-center group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors relative">
                {{ sponsor.name }}
                <span class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-0 h-0.5 bg-amber-500 group-hover:w-full transition-all duration-300"></span>
              </h4>
            </NuxtLink>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useApi } from '~/composables/useApi';

const { get } = useApi();

// Data
const sponsors = ref([]);
const isLoading = ref(true);
const error = ref(null);

// Fetch gold sponsors
async function fetchGoldSponsors() {
  try {
    isLoading.value = true;
    error.value = null;
    
    // For design testing, use dummy sponsors data
    // This will be replaced with actual API call later
    const dummySponsors = [
      { id: 1, name: 'Ahmed Hassan', image: 'https://randomuser.me/api/portraits/men/32.jpg' },
      { id: 2, name: 'Sarah Rahman', image: 'https://randomuser.me/api/portraits/women/44.jpg' },
      { id: 3, name: 'Kamal Ahmed', image: 'https://randomuser.me/api/portraits/men/62.jpg' },
      { id: 4, name: 'Nusrat Jahan', image: 'https://randomuser.me/api/portraits/women/68.jpg' },
      { id: 5, name: 'Zubair Khan', image: 'https://randomuser.me/api/portraits/men/77.jpg' },
      { id: 6, name: 'Tahmina Akter', image: 'https://randomuser.me/api/portraits/women/54.jpg' },
      { id: 7, name: 'Rahim Uddin', image: 'https://randomuser.me/api/portraits/men/41.jpg' },
      { id: 8, name: 'Fahmida Khatun', image: 'https://randomuser.me/api/portraits/women/33.jpg' },
      { id: 9, name: 'Jahangir Alam', image: 'https://randomuser.me/api/portraits/men/21.jpg' },
      { id: 10, name: 'Sabina Yasmin', image: 'https://randomuser.me/api/portraits/women/29.jpg' }
    ];
    
    // Simulate API delay
    setTimeout(() => {
      sponsors.value = dummySponsors;
      isLoading.value = false;
    }, 1000);
    
  } catch (err) {
    console.error('Error fetching gold sponsors:', err);
    error.value = 'Failed to load gold sponsors';
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchGoldSponsors();
});
</script>

<style scoped>
.golden-border {
  background: linear-gradient(45deg, #f59e0b, #f59e0b 25%, #eab308 50%, #f59e0b 75%, #f59e0b);
  opacity: 0.7;
  border-radius: 9999px;
  transform: scale(1.1);
  z-index: -1;
  animation: spin 12s linear infinite;
}

@keyframes spin {
  100% {
    transform: scale(1.1) rotate(360deg);
  }
}

/* Gradient text effect for gold sponsors heading */
.text-gold-gradient {
  background: linear-gradient(to right, #d97706, #fbbf24, #d97706);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
</style>
