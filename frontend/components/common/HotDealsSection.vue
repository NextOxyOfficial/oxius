<template>
  <!-- Hot Deals Categories with Static Background -->
  <section class="mb-4 relative">
    <!-- Static Background (no animations) - Optimized rendering -->
    <div class="absolute inset-0 bg-gradient-to-r from-rose-500 via-red-600 to-orange-500 rounded-xl overflow-hidden">
      <!-- Static Background Pattern (reduced opacity, no animation) -->
      <div class="absolute inset-0 bg-deals-pattern opacity-10"></div>
      
      <!-- Static Glowing Effect (reduced blur intensity, no animation) -->
      <div class="absolute -inset-2 bg-gradient-to-r from-yellow-500/30 via-orange-500/0 to-red-500/30 blur-2xl"></div>
    </div>
    
    <!-- Content Container with extra padding for hover effects -->
    <div class="relative z-10 px-2 py-6">
      <!-- Section Header -->
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center">
          <div class="flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-white mr-2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
            <h2 class="text-xl font-bold text-white drop-shadow-md">Hot Deals</h2>
          </div>
          <div class="ml-3 px-2 py-0.5 bg-white/20 backdrop-blur-sm text-white text-xs font-semibold rounded-full">Limited Time</div>
        </div>
      </div>
      
      <!-- Two-column layout: Fixed Budget Finds + Scrollable Cards -->
      <div class="flex space-x-2">
        <!-- Fixed Budget Finds Card (Always visible on left) -->
        <div class="flex-shrink-0 w-20 sm:w-[12%] bg-white/90 backdrop-blur-sm rounded-lg overflow-visible shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 hover:scale-105 border border-white/50 card-hover">
          <a :href="budgetFindsCard.link" class="block">
            <div class="relative h-[80px] overflow-hidden rounded-t-lg">
              <div class="absolute inset-0 bg-gradient-to-b from-transparent" :class="budgetFindsCard.gradientClass"></div>
              <!-- Static image instead of animated GIF for better performance -->
              <img :src="budgetFindsCard.image" :alt="budgetFindsCard.title" class="w-full h-full object-cover" loading="eager" />
              <div class="absolute top-0 left-0 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-br z-20" :class="budgetFindsCard.badgeClass">
                {{ budgetFindsCard.badge }}
              </div>
            </div>
            <div class="p-2 text-center">
              <h3 class="text-sm text-gray-800">{{ budgetFindsCard.title }}</h3>
            </div>
          </a>
        </div>
        
        <!-- Scrollable Cards Container - Optimized for performance -->
        <div class="flex-1 overflow-hidden">
          <div 
            ref="hotDealsContainer"
            class="flex py-2 space-x-3 overflow-x-auto hide-scrollbar snap-x snap-mandatory hot-deals-container">
            <!-- Dynamic Hot Deals Cards -->
            <div 
              v-for="(card, index) in hotDealsCards" 
              :key="index"
              class="flex-shrink-0 w-20 sm:w-[13%] bg-white/90 backdrop-blur-sm rounded-lg overflow-visible shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-1 hover:scale-105 border border-white/50 snap-start card-hover"
            >
              <a :href="card.link" class="block">
                <div class="relative h-[80px] overflow-hidden rounded-t-lg">
                  <div class="absolute inset-0 bg-gradient-to-b from-transparent" :class="card.gradientClass"></div>
                  <img :src="card.image" :alt="card.title" class="w-full h-full object-cover" loading="lazy" />
                  <div class="absolute top-0 left-0 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-br z-20" :class="card.badgeClass">
                    {{ card.badge }}
                  </div>
                </div>
                <div class="p-2 text-center">
                  <h3 class="font-medium text-sm text-gray-800">{{ card.title }}</h3>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Subtle scroll indicator -->
      <div class="absolute right-0 top-1/2 -translate-y-1/2 pointer-events-none">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-white/70"><path d="m9 18 6-6-6-6"/></svg>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

// Budget Finds Card (Fixed)
const budgetFindsCard = {
  title: '1 - 99 Deals',
  badge: '1 - 99',
  badgeClass: 'bg-emerald-600',
  image: 'https://i.giphy.com/media/3o7TKTDn976rzVgky4/giphy.webp',
  link: '#/search?category=budget-finds',
  gradientClass: 'to-emerald-500/70'
};

// Hot Deals Cards
const hotDealsCards = [
  {
    title: 'Flash Deals',
    badge: 'FLASH',
    badgeClass: 'bg-rose-600',
    image: 'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?q=80&w=2115',
    link: '#/search?category=flash-deals',
    gradientClass: 'to-rose-500/70'
  },
  {
    title: 'Up to 80% Off',
    badge: '80% OFF',
    badgeClass: 'bg-amber-600',
    image: 'https://images.unsplash.com/photo-1607083206968-13611e3d76db?q=80&w=2115',
    link: '#/search?category=discounts',
    gradientClass: 'to-amber-500/70'
  },
  {
    title: 'Buy 1 Get 1',
    badge: 'B1G1',
    badgeClass: 'bg-purple-600',
    image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=2070',
    link: '#/search?category=buy-one-get-one',
    gradientClass: 'to-purple-500/70'
  },
  {
    title: 'Clearance',
    badge: 'CLEAR',
    badgeClass: 'bg-cyan-600',
    image: 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?q=80&w=2070',
    link: '#/search?category=clearance',
    gradientClass: 'to-cyan-500/70'
  },
  {
    title: 'Combo Deals',
    badge: 'COMBO',
    badgeClass: 'bg-blue-600',
    image: 'https://images.unsplash.com/photo-1556740738-b6a63e27c4df?q=80&w=2070',
    link: '#/search?category=combo-deals',
    gradientClass: 'to-blue-500/70'
  },
  {
    title: 'Last Chance',
    badge: 'LAST',
    badgeClass: 'bg-pink-600',
    image: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?q=80&w=2101',
    link: '#/search?category=last-chance',
    gradientClass: 'to-pink-500/70'
  },
  {
    title: 'Season End',
    badge: 'SEASON',
    badgeClass: 'bg-indigo-600',
    image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=2070',
    link: '#/search?category=season-end',
    gradientClass: 'to-indigo-500/70'
  }
];

// Get reference to hot deals container
const hotDealsContainer = ref(null);

// Optimized drag functionality with better performance
// Uses passive event listeners where possible and requestAnimationFrame for smoother scrolling
const isDragging = ref(false);
const startX = ref(0);
const scrollLeft = ref(0);

// Optimized start drag
const startDrag = (e) => {
  if (!hotDealsContainer.value) return;
  
  isDragging.value = true;
  startX.value = e.pageX - hotDealsContainer.value.offsetLeft;
  scrollLeft.value = hotDealsContainer.value.scrollLeft;
  
  // Change cursor
  hotDealsContainer.value.style.cursor = 'grabbing';
  hotDealsContainer.value.style.userSelect = 'none';
};

// Optimized drag with requestAnimationFrame for better performance
const onDrag = (e) => {
  if (!isDragging.value || !hotDealsContainer.value) return;
  e.preventDefault();
  
  const x = e.pageX - hotDealsContainer.value.offsetLeft;
  const walk = (x - startX.value) * 1.5; // Reduced multiplier for smoother scrolling
  
  requestAnimationFrame(() => {
    if (hotDealsContainer.value) {
      hotDealsContainer.value.scrollLeft = scrollLeft.value - walk;
    }
  });
};

// End drag
const endDrag = () => {
  isDragging.value = false;
  
  if (hotDealsContainer.value) {
    hotDealsContainer.value.style.cursor = 'grab';
    hotDealsContainer.value.style.removeProperty('user-select');
  }
};

onMounted(() => {
  if (hotDealsContainer.value) {
    hotDealsContainer.value.style.cursor = 'grab';
    
    // Use passive event listeners where possible for better performance
    hotDealsContainer.value.addEventListener('mousedown', startDrag, { passive: false });
    document.addEventListener('mousemove', onDrag, { passive: false });
    document.addEventListener('mouseup', endDrag, { passive: true });
    hotDealsContainer.value.addEventListener('mouseleave', endDrag, { passive: true });
  }
  
  // Add entrance animation
  setTimeout(() => {
    const sectionElement = document.querySelector('section');
    if (sectionElement) {
      sectionElement.classList.add('animate-section-enter');
    }
  }, 100);
});

onUnmounted(() => {
  if (hotDealsContainer.value) {
    hotDealsContainer.value.removeEventListener('mousedown', startDrag);
  }
  document.removeEventListener('mousemove', onDrag);
  document.removeEventListener('mouseup', endDrag);
  if (hotDealsContainer.value) {
    hotDealsContainer.value.removeEventListener('mouseleave', endDrag);
  }
});
</script>

<style scoped>
/* Hot Deals pattern - static, no animation */
.bg-deals-pattern {
  background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z' fill='%23ffffff' fill-opacity='1' fill-rule='evenodd'/%3E%3C/svg%3E");
  background-size: 150px 150px;
}

/* Animation and state classes */
section {
  opacity: 0;
  transform: translateY(10px);
  transition: opacity 0.5s ease-out, transform 0.5s ease-out;
  will-change: opacity, transform;
}

.animate-section-enter {
  opacity: 1;
  transform: translateY(0);
}

/* Performance optimized image transforms */
img {
  transition: transform 0.5s ease-in-out;
  will-change: transform;
}

/* Hide scrollbar but keep functionality */
.hide-scrollbar {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;  /* Chrome, Safari and Opera */
}

/* Snap scrolling */
.snap-x {
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
}

.snap-start {
  scroll-snap-align: start;
}

/* Improved card hover effect with hardware acceleration */
.card-hover {
  position: relative;
  z-index: 1;
  transform-origin: center center;
  will-change: transform, box-shadow;
  isolation: isolate;
  transform: translateZ(0); /* Enable hardware acceleration */
  backface-visibility: hidden;
}

.card-hover:hover {
  z-index: 2;
}

.hover\:-translate-y-1:hover {
  transform: translateY(-4px) translateZ(0);
}

.hover\:scale-105:hover {
  transform: scale(1.05) translateZ(0);
}

.hover\:-translate-y-1.hover\:scale-105:hover {
  transform: translateY(-4px) scale(1.05) translateZ(0);
}

/* Reduced shadow intensity for better performance */
.shadow-md {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.hover\:shadow-lg:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

/* Cursor styles for draggable containers */
.hot-deals-container {
  cursor: grab;
}

.hot-deals-container:active {
  cursor: grabbing;
}
</style>