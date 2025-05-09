<template>
  <div class="w-full max-w-7xl sm:px-4 mx-auto bg-gradient-to-br from-slate-50 via-white to-slate-50">
    <!-- Subtle Background Elements -->
    <div class="fixed inset-0 bg-pattern opacity-5 z-0"></div>
    <div class="fixed top-0 left-0 w-full h-64 bg-gradient-to-r from-rose-100/20 via-purple-100/20 to-cyan-100/20 z-0"></div>
    
    <!-- Content Container -->
    <div class="relative z-10">
      
      <!-- 1. Main Carousel -->
      <section class="mb-8 pt-2">
        <div class="relative w-full overflow-hidden rounded-xl shadow-lg">
          <!-- Carousel container -->
          <div 
            class="relative h-[200px] sm:h-[250px] md:h-[300px] w-full overflow-hidden"
            @mouseenter="pauseAutoplay"
            @mouseleave="startAutoplay"
          >
            <!-- Carousel slides -->
            <div 
              class="flex h-full transition-transform duration-500 ease-in-out"
              :style="{ transform: `translateX(-${currentIndex * 100}%)` }"
            >
              <!-- Dynamic Slides -->
              <div 
                v-for="(slide, index) in carouselSlides" 
                :key="index"
                class="min-w-full h-full relative"
              >
                <div class="absolute inset-0 bg-gradient-to-r" :class="slide.gradientClass" :style="slide.gradientStyle"></div>
                <div class="absolute inset-0 bg-cover bg-center" :style="{ backgroundImage: `url('${slide.backgroundImage}')` }"></div>
                <div class="absolute inset-0 flex items-center justify-center z-20 text-white text-center p-2">
                  <div class="animate-fade-in">
                    <h3 class="text-xl md:text-3xl font-bold mb-2">{{ slide.title }}</h3>
                    <p class="mb-4 text-sm md:text-base">{{ slide.description }}</p>
                    <button 
                      class="px-4 py-1 md:px-6 sm:px-6 md:py-2 rounded-full font-medium transition-colors text-sm shadow-md hover:shadow-lg"
                      :class="slide.buttonClass"
                    >
                      {{ slide.buttonText }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Navigation arrows -->
            <button 
              @click="prevSlide" 
              class="opacity-0 absolute left-2 top-1/2 -translate-y-1/2 bg-black/20 hover:bg-black/40 text-white rounded-full p-1.5 focus:outline-none transition-colors z-30 backdrop-blur-sm"
              aria-label="Previous slide"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-left"><path d="m15 18-6-6 6-6"/></svg>
            </button>
            <button 
              @click="nextSlide" 
              class="opacity-0 absolute right-2 top-1/2 -translate-y-1/2 bg-black/20 hover:bg-black/40 text-white rounded-full p-1.5 focus:outline-none transition-colors z-30 backdrop-blur-sm"
              aria-label="Next slide"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-right"><path d="m9 18 6-6-6-6"/></svg>
            </button>
          </div>

          <!-- Indicators -->
          <div class="absolute bottom-3 left-0 right-0 flex justify-center gap-1.5 z-30">
            <button 
              v-for="(_, index) in carouselSlides" 
              :key="index"
              @click="goToSlide(index)"
              :class="[
                'w-2 h-2 rounded-full transition-all focus:outline-none',
                currentIndex === index ? 'bg-white w-5' : 'bg-white/50'
              ]"
              :aria-label="`Go to slide ${index + 1}`"
            ></button>
          </div>
        </div>
      </section>

      <!-- 2. Hot Deals Categories with Static Background -->
      <section class="mb-4 relative">
        <!-- Static Background (no animations) -->
        <div class="absolute inset-0 bg-gradient-to-r from-rose-500 via-red-600 to-orange-500 rounded-xl overflow-hidden">
          <!-- Static Background Pattern (no animation) -->
          <div class="absolute inset-0 bg-deals-pattern opacity-10"></div>
          
          <!-- Static Glowing Effect (no animation) -->
          <div class="absolute -inset-2 bg-gradient-to-r from-yellow-500/30 via-orange-500/0 to-red-500/30 blur-3xl"></div>
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
            <div class="flex-shrink-0 w-20  sm:w-[12%] bg-white/90 backdrop-blur-sm rounded-lg overflow-visible shadow-[0_4px_20px_rgba(0,0,0,0.15)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.2)] transition-all duration-300 transform hover:-translate-y-1 hover:scale-105 border border-white/50 card-hover">
              <a :href="budgetFindsCard.link" class="block">
                <div class="relative h-[80px] overflow-hidden rounded-t-lg">
                  <div class="absolute inset-0 bg-gradient-to-b from-transparent" :class="budgetFindsCard.gradientClass"></div>
                  <!-- Animated GIF for Budget Finds -->
                  <img :src="budgetFindsCard.image" :alt="budgetFindsCard.title" class="w-full h-full object-cover" />
                  <div class="absolute top-0 left-0 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-br z-20" :class="budgetFindsCard.badgeClass">
                    {{ budgetFindsCard.badge }}
                  </div>
                </div>
                <div class="p-2 text-center">
                  <h3 class=" text-sm text-gray-800">{{ budgetFindsCard.title }}</h3>
                </div>
              </a>
            </div>
            
            <!-- Scrollable Cards Container -->
            <div class="flex-1 overflow-hidden">
              <div class="flex space-x-3 overflow-x-auto hide-scrollbar snap-x snap-mandatory hot-deals-container">
                <!-- Dynamic Hot Deals Cards -->
                <div 
                  v-for="(card, index) in hotDealsCards" 
                  :key="index"
                  class="flex-shrink-0 w-20 sm:w-[13%] bg-white/90 backdrop-blur-sm rounded-lg overflow-visible shadow-[0_4px_20px_rgba(0,0,0,0.15)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.2)] transition-all duration-300 transform hover:-translate-y-1 hover:scale-105 border border-white/50 snap-start card-hover"
                >
                  <a :href="card.link" class="block">
                    <div class="relative h-[80px] overflow-hidden rounded-t-lg">
                      <div class="absolute inset-0 bg-gradient-to-b from-transparent" :class="card.gradientClass"></div>
                      <img :src="card.image" :alt="card.title" class="w-full h-full object-cover transition-transform hover:scale-110 duration-500" />
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

      <!-- 3. New & Hot Arrivals (4 cards initially visible) -->
      <section class="mb-4 mt-6 relative">
        <div class="flex items-center justify-between mt-3 mb-2">
          <div class="flex items-center">
            <div class="w-1 h-6 bg-gradient-to-b from-emerald-400 to-emerald-600 rounded-full mr-2"></div>
            <h2 class="text-lg font-bold text-gray-800">New & Hot Arrivals</h2>
            <div class="ml-2 px-2 py-0.5 bg-emerald-100 text-emerald-600 text-xs font-semibold rounded-full">Just In</div>
          </div>
          <a href="#" class="text-emerald-600 hover:underline flex items-center text-sm font-medium">
            View All
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="ml-1"><path d="m9 18 6-6-6-6"/></svg>
          </a>
        </div>
        
        <!-- Card container - 4 cards initially visible -->
        <div class="relative overflow-hidden">
          <div class="flex space-x-2 overflow-x-auto pb-4 pt-2 px-2 -mx-2 hide-scrollbar snap-x snap-mandatory arrivals-container">
            <!-- Dynamic New Arrivals Cards -->
            <div 
              v-for="(card, index) in newArrivalsCards" 
              :key="index"
              class="flex-shrink-0 w-[calc(25%-1.5px)] md:w-[calc(12.5%-1.5px)] bg-white rounded-lg overflow-visible shadow-[0_4px_15px_rgba(0,0,0,0.07)] hover:shadow-[0_8px_25px_rgba(0,0,0,0.1)] transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 snap-start card-hover"
            >
              <a :href="card.link" class="block">
                <div class="relative h-[70px] overflow-hidden rounded-t-lg">
                  <div class="absolute inset-0 bg-gradient-to-b from-transparent" :class="card.gradientClass"></div>
                  <img :src="card.image" :alt="card.title" class="w-full h-full object-cover transition-transform hover:scale-110 duration-500" />
                  <div class="absolute top-0 right-0 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-bl z-20" :class="card.badgeClass">
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
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

// Carousel data
const carouselSlides = [
  {
    title: 'Summer Collection',
    description: 'Discover the hottest trends for the season',
    buttonText: 'Shop Now',
    buttonClass: 'bg-white text-purple-600 hover:bg-purple-100',
    backgroundImage: 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?q=80&w=2070',
    gradientClass: 'from-purple-500/80 to-indigo-600/80',
    gradientStyle: ''
  },
  {
    title: 'Tech Week',
    description: 'Exclusive deals on the latest gadgets',
    buttonText: 'Explore',
    buttonClass: 'bg-white text-orange-600 hover:bg-orange-100',
    backgroundImage: 'https://images.unsplash.com/photo-1526738549149-8e07eca6c147?q=80&w=2025',
    gradientClass: 'from-amber-500/80 to-orange-600/80',
    gradientStyle: ''
  },
  {
    title: 'Home Essentials',
    description: 'Transform your living space',
    buttonText: 'Discover',
    buttonClass: 'bg-white text-emerald-600 hover:bg-emerald-100',
    backgroundImage: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?q=80&w=2070',
    gradientClass: 'from-emerald-500/80 to-teal-600/80',
    gradientStyle: ''
  },
  {
    title: 'Flash Sale',
    description: '24 hours only - Up to 70% off',
    buttonText: 'Shop Sale',
    buttonClass: 'bg-white text-rose-600 hover:bg-rose-100',
    backgroundImage: 'https://images.unsplash.com/photo-1607083206968-13611e3d76db?q=80&w=2115',
    gradientClass: 'from-rose-500/80 to-pink-600/80',
    gradientStyle: ''
  },
  {
    title: 'New Arrivals',
    description: 'Be the first to shop our latest products',
    buttonText: 'View All',
    buttonClass: 'bg-white text-blue-600 hover:bg-blue-100',
    backgroundImage: 'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?q=80&w=2115',
    gradientClass: 'from-cyan-500/80 to-blue-600/80',
    gradientStyle: ''
  }
];

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

// New Arrivals Cards
const newArrivalsCards = [
  {
    title: 'AC',
    badge: 'NEW',
    badgeClass: 'bg-cyan-600',
    image: 'https://images.unsplash.com/photo-1580655653885-65763b2597d0?q=80&w=2070',
    link: '#/search?category=ac',
    gradientClass: 'to-cyan-500/70'
  },
  {
    title: 'Fashion',
    badge: 'HOT',
    badgeClass: 'bg-rose-600',
    image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=2071',
    link: '#/search?category=fashion',
    gradientClass: 'to-rose-500/70'
  },
  {
    title: 'Shoes',
    badge: 'NEW',
    badgeClass: 'bg-amber-600',
    image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=2070',
    link: '#/search?category=shoes',
    gradientClass: 'to-amber-500/70'
  },
  {
    title: 'Motorcycle',
    badge: 'HOT',
    badgeClass: 'bg-purple-600',
    image: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=2070',
    link: '#/search?category=motorcycle',
    gradientClass: 'to-purple-500/70'
  },
  {
    title: 'Mobile',
    badge: 'NEW',
    badgeClass: 'bg-emerald-600',
    image: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=2080',
    link: '#/search?category=mobile',
    gradientClass: 'to-emerald-500/70'
  },
  {
    title: 'Kitchen',
    badge: 'HOT',
    badgeClass: 'bg-orange-600',
    image: 'https://images.unsplash.com/photo-1556911220-bff31c812dba?q=80&w=2068',
    link: '#/search?category=kitchen',
    gradientClass: 'to-orange-500/70'
  },
  {
    title: 'Gadgets',
    badge: 'NEW',
    badgeClass: 'bg-gray-700',
    image: 'https://images.unsplash.com/photo-1519558260268-cde7e03a0152?q=80&w=2070',
    link: '#/search?category=gadgets',
    gradientClass: 'to-gray-700/70'
  },
  {
    title: 'Laptops',
    badge: 'NEW',
    badgeClass: 'bg-blue-600',
    image: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=2071',
    link: '#/search?category=laptops',
    gradientClass: 'to-blue-500/70'
  },
  {
    title: 'Watches',
    badge: 'HOT',
    badgeClass: 'bg-pink-600',
    image: 'https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=2088',
    link: '#/search?category=watches',
    gradientClass: 'to-pink-500/70'
  },
  {
    title: 'Cameras',
    badge: 'NEW',
    badgeClass: 'bg-indigo-600',
    image: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=2038',
    link: '#/search?category=cameras',
    gradientClass: 'to-indigo-500/70'
  },
  {
    title: 'Audio',
    badge: 'HOT',
    badgeClass: 'bg-red-600',
    image: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=2065',
    link: '#/search?category=audio',
    gradientClass: 'to-red-500/70'
  },
  {
    title: 'Gaming',
    badge: 'NEW',
    badgeClass: 'bg-violet-600',
    image: 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?q=80&w=2057',
    link: '#/search?category=gaming',
    gradientClass: 'to-violet-500/70'
  }
];

// Carousel functionality
const currentIndex = ref(0);
const autoplayInterval = ref(null);
const autoplayDelay = 5000; // 5 seconds

const nextSlide = () => {
  currentIndex.value = (currentIndex.value + 1) % carouselSlides.length;
};

const prevSlide = () => {
  currentIndex.value = (currentIndex.value - 1 + carouselSlides.length) % carouselSlides.length;
};

const goToSlide = (index) => {
  currentIndex.value = index;
};

const startAutoplay = () => {
  if (!autoplayInterval.value) {
    autoplayInterval.value = setInterval(nextSlide, autoplayDelay);
  }
};

const pauseAutoplay = () => {
  if (autoplayInterval.value) {
    clearInterval(autoplayInterval.value);
    autoplayInterval.value = null;
  }
};

// Mouse drag functionality
const isDragging = ref(false);
const startX = ref(0);
const scrollLeft = ref(0);

// Start drag
const startDrag = (e, container) => {
  isDragging.value = true;
  startX.value = e.pageX - container.offsetLeft;
  scrollLeft.value = container.scrollLeft;
  
  // Change cursor
  container.style.cursor = 'grabbing';
  container.style.userSelect = 'none';
};

// During drag
const onDrag = (e, container) => {
  if (!isDragging.value) return;
  e.preventDefault();
  
  const x = e.pageX - container.offsetLeft;
  const walk = (x - startX.value) * 2; // Scroll speed multiplier
  container.scrollLeft = scrollLeft.value - walk;
};

// End drag
const endDrag = (container) => {
  isDragging.value = false;
  
  container.style.cursor = 'grab';
  container.style.removeProperty('user-select');
};

onMounted(() => {
  startAutoplay();
  
  // Add entrance animations for sections
  const sections = document.querySelectorAll('section');
  sections.forEach((section, index) => {
    setTimeout(() => {
      section.classList.add('animate-section-enter');
    }, index * 200);
  });
  
  // Add mouse drag functionality to scrollable containers
  const hotDealsContainer = document.querySelector('.hot-deals-container');
  const arrivalsContainer = document.querySelector('.arrivals-container');

  if (hotDealsContainer) {
    hotDealsContainer.style.cursor = 'grab';
    
    hotDealsContainer.addEventListener('mousedown', (e) => startDrag(e, hotDealsContainer));
    hotDealsContainer.addEventListener('mousemove', (e) => onDrag(e, hotDealsContainer));
    hotDealsContainer.addEventListener('mouseup', () => endDrag(hotDealsContainer));
    hotDealsContainer.addEventListener('mouseleave', () => endDrag(hotDealsContainer));
  }

  if (arrivalsContainer) {
    arrivalsContainer.style.cursor = 'grab';
    
    arrivalsContainer.addEventListener('mousedown', (e) => startDrag(e, arrivalsContainer));
    arrivalsContainer.addEventListener('mousemove', (e) => onDrag(e, arrivalsContainer));
    arrivalsContainer.addEventListener('mouseup', () => endDrag(arrivalsContainer));
    arrivalsContainer.addEventListener('mouseleave', () => endDrag(arrivalsContainer));
  }
});

onUnmounted(() => {
  pauseAutoplay();
  
  // Remove event listeners
  const hotDealsContainer = document.querySelector('.hot-deals-container');
  const arrivalsContainer = document.querySelector('.arrivals-container');

  if (hotDealsContainer) {
    hotDealsContainer.removeEventListener('mousedown', (e) => startDrag(e, hotDealsContainer));
    hotDealsContainer.removeEventListener('mousemove', (e) => onDrag(e, hotDealsContainer));
    hotDealsContainer.removeEventListener('mouseup', () => endDrag(hotDealsContainer));
    hotDealsContainer.removeEventListener('mouseleave', () => endDrag(hotDealsContainer));
  }

  if (arrivalsContainer) {
    arrivalsContainer.removeEventListener('mousedown', (e) => startDrag(e, arrivalsContainer));
    arrivalsContainer.removeEventListener('mousemove', (e) => onDrag(e, arrivalsContainer));
    arrivalsContainer.removeEventListener('mouseup', () => endDrag(arrivalsContainer));
    arrivalsContainer.removeEventListener('mouseleave', () => endDrag(arrivalsContainer));
  }
});
</script>

<style scoped>
/* Background pattern */
.bg-pattern {
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%239C92AC' fill-opacity='0.1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

/* Hot Deals pattern - static, no animation */
.bg-deals-pattern {
  background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z' fill='%23ffffff' fill-opacity='1' fill-rule='evenodd'/%3E%3C/svg%3E");
  background-size: 150px 150px;
}

section {
  opacity: 0;
  transform: translateY(10px);
  transition: opacity 0.5s ease-out, transform 0.5s ease-out;
}

.animate-section-enter {
  opacity: 1;
  transform: translateY(0);
}

/* Smooth image zoom effect */
img {
  transition: transform 0.5s ease-in-out;
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
}

.snap-start {
  scroll-snap-align: start;
}

/* Improved card hover effect */
.card-hover {
  position: relative;
  z-index: 1;
  transform-origin: center center;
  will-change: transform, box-shadow;
  isolation: isolate;
}

.card-hover:hover {
  z-index: 50;
}

.hover\:-translate-y-1:hover {
  transform: translateY(-4px);
}

.hover\:scale-105:hover {
  transform: scale(1.05);
}

.hover\:-translate-y-1.hover\:scale-105:hover {
  transform: translateY(-4px) scale(1.05);
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fadeIn 0.5s ease-out forwards;
}

/* Desktop layout adjustments */
@media (min-width: 768px) {
  .hide-scrollbar {
    overflow-x: auto;
    display: flex;
    flex-wrap: nowrap;
  }
}

/* Cursor styles for draggable containers */
.hot-deals-container, .arrivals-container {
  cursor: grab;
}

.hot-deals-container:active, .arrivals-container:active {
  cursor: grabbing;
}
</style>
