<template>
  <div class="gold-sponsors-slider relative mt-2 px-3 bg-gradient-to-r from-amber-50/50 to-yellow-50/50 dark:from-amber-900/10 dark:to-yellow-900/10 rounded-xl border border-amber-100/50 dark:border-amber-900/30 backdrop-blur-sm shadow-sm">
    <!-- Top pattern decoration -->
    <div class="absolute top-0 left-0 right-0 h-1.5 overflow-hidden">
      <div class="h-full w-full bg-gradient-to-r from-amber-500/0 via-amber-500 to-amber-500/0 animate-shimmer"></div>
    </div>    <div class="flex items-center justify-between px-2 mb-2">
      <h3 class="text-sm font-semibold flex items-center">
        <div class="w-5 h-5 flex items-center justify-center mr-1.5 relative">
          <div class="absolute inset-0 rounded-full golden-border"></div>
          <UIcon
            name="i-heroicons-star"
            class="w-4 h-4 text-amber-500 relative z-10"
          />
        </div>
        <span class="text-gold-gradient">
          {{ $t('gold_sponsors') }}
        </span>
      </h3>
      <NuxtLink 
        to="/business-network/gold-sponsors"
        class="text-xs text-amber-600 dark:text-amber-400 hover:text-amber-700 dark:hover:text-amber-300 font-medium flex items-center group transition-colors"
      >
        {{ $t('view_all') }}
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 ml-0.5 group-hover:translate-x-0.5 transition-transform" />
      </NuxtLink>
    </div>    
    <!-- Sponsors Grid -->
    <div class="sponsors-container overflow-hidden relative">        <!-- Loading state -->
      <div v-if="isLoading" class="flex py-3 gap-4 px-2 overflow-hidden">
        <div v-for="i in 3" :key="i" class="flex-shrink-0 animate-pulse md:hidden" style="width: 90px">
          <div class="flex flex-col items-center">
            <div class="w-14 h-14 rounded-full bg-amber-100 dark:bg-amber-900/30 mb-2 relative overflow-hidden">
              <div class="absolute inset-0 golden-border opacity-30"></div>
            </div>
            <div class="h-4 bg-amber-100 dark:bg-amber-900/30 rounded w-16"></div>
          </div>
        </div>
        <div v-for="i in 5" :key="i + 3" class="flex-shrink-0 animate-pulse hidden md:block" style="width: 90px">
          <div class="flex flex-col items-center">
            <div class="w-14 h-14 rounded-full bg-amber-100 dark:bg-amber-900/30 mb-2 relative overflow-hidden">
              <div class="absolute inset-0 golden-border opacity-30"></div>
            </div>
            <div class="h-4 bg-amber-100 dark:bg-amber-900/30 rounded w-16"></div>
          </div>
        </div>
      </div>
      
      <!-- Error state -->
      <div v-else-if="error" class="py-3 px-4">
        <div class="text-center text-amber-600 dark:text-amber-400">
          <UIcon name="i-heroicons-exclamation-triangle" class="w-5 h-5 mx-auto mb-2" />
          <p class="text-sm">{{ error }}</p>
        </div>
      </div>
        <!-- Content -->
      <div v-else class="flex py-2 gap-3 justify-between md:justify-between overflow-hidden">
        <!-- Mobile View (3 sponsors) -->
        <div 
          v-for="(sponsor, index) in sponsors.slice(0, 3)" 
          :key="'mobile-' + index"
          class="sponsor-item md:hidden"
        >
          <NuxtLink 
            :to="`/business-network/profile/${sponsor.id}`"
            class="block p-2"
          >
            <div class="flex flex-col items-center">
              <!-- Profile image with gold border -->
              <div class="relative mb-2 group-hover:scale-105 transition-transform duration-300">
                <div class="absolute inset-0 rounded-full golden-border"></div>
                <img 
                  :src="sponsor.image || '/static/frontend/avatar.png'" 
                  :alt="sponsor.name"
                  class="size-20 rounded-full object-cover border-2 border-white dark:border-slate-700 relative z-10"
                />
                <!-- Gold badge -->
                <div class="absolute -bottom-1 -right-1 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-sm z-20 transform transition-transform group-hover:scale-110 group-hover:rotate-12">
                  <UIcon
                    name="i-heroicons-star"
                    class="w-3 h-3 text-white"
                  />
                </div>
              </div>
              <!-- Name with hover underline -->
              <h4 class="text-base font-medium text-gray-800 dark:text-gray-200 text-center group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors relative">
                {{ sponsor.name }}
                <span class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-0 h-0.5 bg-amber-500 group-hover:w-full transition-all duration-300"></span>
              </h4>
            </div>
          </NuxtLink>
        </div>

        <!-- Desktop View (5 sponsors) -->
        <div 
          v-for="(sponsor, index) in sponsors.slice(0, 5)" 
          :key="'desktop-' + index"
          class="sponsor-item hidden md:block"
        >
          <NuxtLink 
            :to="`/business-network/profile/${sponsor.id}`"
            class="block p-2"
          >
            <div class="flex flex-col items-center">
              <!-- Profile image with gold border -->
              <div class="relative mb-2 group-hover:scale-105 transition-transform duration-300">
                <div class="absolute inset-0 rounded-full golden-border"></div>
                <img 
                  :src="sponsor.image || '/static/frontend/avatar.png'" 
                  :alt="sponsor.name"
                  class="w-14 h-14 rounded-full object-cover border-2 border-white dark:border-slate-700 relative z-10"
                />
                <!-- Gold badge -->
                <div class="absolute -bottom-1 -right-1 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-sm z-20 transform transition-transform group-hover:scale-110 group-hover:rotate-12">
                  <UIcon
                    name="i-heroicons-star"
                    class="w-3 h-3 text-white"
                  />
                </div>
              </div>
              <!-- Name with hover underline -->
              <h4 class="text-sm font-medium text-gray-800 dark:text-gray-200 text-center group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors relative">
                {{ sponsor.name }}
                <span class="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-0 h-0.5 bg-amber-500 group-hover:w-full transition-all duration-300"></span>
              </h4>
            </div>
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useApi } from '~/composables/useApi';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const { get } = useApi();

// Sample data (will be replaced with API call)
const sponsors = ref([]);
const isLoading = ref(true);
const error = ref(null);

// Fetch gold sponsors
async function fetchGoldSponsors() {
  try {
    isLoading.value = true;
    
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
    
    // Shuffle the sponsors array (Fisher-Yates algorithm)
    function shuffleArray(array) {
      for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
      }
      return array;
    }
    
    // Simulate API delay
    setTimeout(() => {
      // Shuffle and limit based on screen size (handled in template with CSS)
      sponsors.value = shuffleArray([...dummySponsors]);
      isLoading.value = false;
    }, 1000);
    
    // Uncomment this code when ready to use the real API
    /*
    const { data } = await get('/bn/top-contributors/');
    sponsors.value = data.filter(contributor => contributor.is_pro).slice(0, 10);
    isLoading.value = false;
    */
  } catch (err) {
    console.error('Error fetching gold sponsors:', err);
    error.value = 'Failed to load gold sponsors';
    isLoading.value = false;
  }
}

// Initialize
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

@keyframes pulse-subtle {
  0%, 100% {
    opacity: 0.6;
  }
  50% {
    opacity: 0.8;
  }
}

@keyframes spin {
  100% {
    transform: scale(1.1) rotate(360deg);
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Enhanced styling for gold sponsor items */
.sponsor-slide:hover {
  transform: translateY(-4px);
  transition: transform 0.3s ease-out;
}

/* Gradient text effect for gold sponsors heading */
.text-gold-gradient {
  background: linear-gradient(to right, #d97706, #fbbf24, #d97706);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

/* Hide scrollbar */
.sponsors-container {
  scrollbar-width: none;
  -webkit-overflow-scrolling: touch; /* Smooth scrolling on iOS */
  touch-action: pan-x; /* Optimize for horizontal touch */
}
.sponsors-container::-webkit-scrollbar {
  display: none;
}

/* Ensure smoother animations */
.sponsors-track {
  will-change: transform;
  cursor: grab;
  user-select: none;
}

.sponsors-track:active {
  cursor: grabbing;
}

/* Shimmer animation for the top border */
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}

/* Optimize for touch devices */
@media (pointer: coarse) {
  .sponsors-container {
    touch-action: pan-x;
  }
  
  /* Make the slides slightly larger on touch devices for better tapping */
  .sponsor-slide img {
    min-width: 56px;
    min-height: 56px;
  }
}
</style>
