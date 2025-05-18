<template>  
<div id="home">
    <div class="max-w-7xl w-full mx-auto">
      <div
        class="rounded-xl overflow-hidden shadow-sm"
      >
        <div class="flex flex-col md:flex-row">          
          <!-- Left side - Image Slider with reduced height -->          
          <div 
            class="px-2 rounded-xl md:w-3/5 relative overflow-hidden touch-slider"
            ref="sliderContainer"
            @mouseenter="handleSliderHover(true)"
            @mouseleave="handleSliderHover(false)"
          >
            <!-- Mobile swipe indicator shown only on mobile -->
            <div class="md:hidden absolute top-1/2 left-0 right-0 -translate-y-1/2 flex justify-between px-3 z-20 opacity-60 pointer-events-none">
              <div class="swipe-indicator swipe-indicator-left">
                <ChevronLeft class="h-8 w-8 text-white" />
              </div>
              <div class="swipe-indicator swipe-indicator-right">
                <ChevronRight class="h-8 w-8 text-white" />
              </div>
            </div>
            <!-- Aspect ratio container - reduced by ~10% -->
            <div class="rounded-xl mt-4 sm:mt-8 overflow-hidden relative pb-[45%] md:pb-[45%] lg:pb-[45%]">
              <div
                v-for="({ id, image }, index) in sliderImages"
                :key="id"
                class="absolute inset-0 transition-all duration-500 ease-out transform"
                :class="{
                  'opacity-100 translate-x-0': index === currentSlide,
                  'opacity-0 translate-x-full': index > currentSlide,
                  'opacity-0 -translate-x-full': index < currentSlide
                }"
              >
                <!-- Gradient overlay -->
                <div
                  class="absolute inset-0 bg-gradient-to-r from-black/40 to-black/20 z-10"
                ></div>
                <img
                  v-if="image"
                  :src="image"
                  :alt="`Slide ${index + 1}`"
                  class="w-full h-full object-cover"
                />
              </div>
            </div>            
            <!-- Navigation arrows - hidden on mobile but visible on desktop on hover -->
            <button
              @click="prevSlide"
              class="hidden md:flex absolute left-3 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/80 to-blue-600/80 backdrop-blur-sm hover:from-emerald-600/90 hover:to-blue-600/90 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 shadow-sm opacity-0 transform -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0"
              :class="{ 'opacity-100 translate-x-0': isHovering }"
              aria-label="Previous slide"
            >
              <ChevronLeft class="h-5 w-5 text-white" />
            </button>

            <button
              @click="nextSlide"
              class="hidden md:flex absolute right-3 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/80 to-blue-600/80 backdrop-blur-sm hover:from-emerald-600/90 hover:to-blue-600/90 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 shadow-sm opacity-0 transform translate-x-2 group-hover:opacity-100 group-hover:translate-x-0"
              :class="{ 'opacity-100 translate-x-0': isHovering }"
              aria-label="Next slide"
            >
              <ChevronRight class="h-5 w-5 text-white" />
            </button>
            <!-- Slider indicators - improved -->
            <div
              class="absolute bottom-4 left-1/2 -translate-x-1/2 flex space-x-3 z-20 bg-black/20 backdrop-blur-md px-3 py-1.5 rounded-full"
            >
              <button
                v-for="(_, index) in sliderImages"
                :key="index"
                @click="goToSlide(index)"
                class="w-2.5 h-2.5 rounded-full transition-all duration-300 relative"
                :class="{
                  'bg-white scale-110': index === currentSlide,
                  'bg-white/40 hover:bg-white/60': index !== currentSlide,
                }"
                :aria-label="`Go to slide ${index + 1}`"
              >
              </button>
            </div>
          </div>
          <!-- Right side - Premium content area -->
          <div class="w-full md:w-2/5 max-sm:py-4 sm:pb-4 sm:px-4 flex flex-col justify-center rounded-xl bg-slate-50/80">
            <div class="relative text-center">
              <h1
                class="text-lg sm:text-base font-medium leading-tight text-gray-700 relative inline-block"
              >
                <span class="relative z-10">{{ $t("bangladesh_first_title") }}</span>
                <span class="absolute bottom-1 left-0 w-full h-2 bg-emerald-100 -z-10"></span>
              </h1>
              <!-- Service buttons grid with cool design -->
              <div class="grid grid-cols-4 gap-0 my-4 hidden md:grid border border-gray-100 rounded-lg overflow-hidden divide-x divide-y divide-gray-100">
                <!-- Business Network -->
                <NuxtLink to="/business-network" class="service-btn bg-white hover:bg-blue-50 text-gray-700">
                  <div class="icon-circle bg-blue-50">
                    <Globe class="icon text-blue-600" />
                  </div>
                  <span>Business Network</span>
                </NuxtLink>                  
                <!-- News -->
                <NuxtLink to="/adsy-news" class="service-btn bg-white hover:bg-amber-50 text-gray-700">
                  <div class="icon-circle bg-amber-50">
                    <Newspaper class="icon text-amber-600" />
                  </div>
                  <span>News</span>
                </NuxtLink>                  
                <!-- Earn Money -->
                <NuxtLink to="/#micro-gigs" class="service-btn bg-white hover:bg-emerald-50 text-gray-700">
                  <div class="icon-circle bg-emerald-50">
                    <BadgeDollarSign class="icon text-emerald-600" />
                  </div>
                  <span>Earn Money</span>
                </NuxtLink>                
                <!-- Eshop -->
                <NuxtLink to="/eshop" class="service-btn bg-white hover:bg-purple-50 text-gray-700">
                  <div class="icon-circle bg-purple-50">
                    <ShoppingCart class="icon text-purple-600" />
                  </div>
                  <span>Eshop</span>
                </NuxtLink>                
                <!-- Sale Listings -->
                <NuxtLink to="/#sale-category" class="service-btn bg-white hover:bg-indigo-50 text-gray-700">
                  <div class="icon-circle bg-indigo-50">
                    <ListFilter class="icon text-indigo-600" />
                  </div>
                  <span>Sale Listings</span>
                </NuxtLink>

                <!-- MindForce -->
                <NuxtLink to="/business-network/mindforce" class="service-btn bg-white hover:bg-cyan-50 text-gray-700">
                  <div class="icon-circle bg-cyan-50">
                    <Brain class="icon text-cyan-600" />
                  </div>
                  <span>MindForce</span>
                </NuxtLink>

                <!-- Amar Seba -->
                <NuxtLink to="/#classified-services" class="service-btn bg-white hover:bg-rose-50 text-gray-700">
                  <div class="icon-circle bg-rose-50">
                    <Cog class="icon text-rose-600" />
                  </div>
                  <span>Amar Seba</span>
                </NuxtLink>                
                <!-- Shastho Sheba (Coming Soon) - Disabled appearance -->
                <div class="service-btn bg-white/70 text-gray-500 relative opacity-80 cursor-not-allowed">
                  <div class="icon-circle bg-gray-100">
                    <HeartPulse class="icon text-gray-500" />
                  </div>
                  <div class="h-12 flex items-center justify-center">
                    <span>Shastho Sheba</span>
                  </div>
                  <span class="absolute top-1 -right-1 bg-gray-400 text-white text-[8px] px-1 py-0.5 rounded-sm">Coming Soon</span>
                </div>

                <!-- Bill Pay (Coming Soon) - Disabled appearance -->
                <div class="service-btn bg-white/70 text-gray-500 relative opacity-80 cursor-not-allowed">
                  <div class="icon-circle bg-gray-100">
                    <Receipt class="icon text-gray-500" />
                  </div>
                  <div class="h-12 flex items-center justify-center">
                    <span>Bill Pay</span>
                  </div>
                  <span class="absolute top-1 -right-1 bg-gray-400 text-white text-[8px] px-1 py-0.5 rounded-sm">Coming Soon</span>
                </div>
                <!-- Mobile Recharge -->
                <NuxtLink to="/mobile-recharge" class="service-btn bg-white hover:bg-orange-50 text-gray-700">
                  <div class="icon-circle bg-orange-50">
                    <Smartphone class="icon text-orange-600" />
                  </div>
                  <span>Mobile Recharge</span>
                </NuxtLink>                
                <!-- Transactions -->
                <NuxtLink to="/deposit-withdraw" class="service-btn bg-white hover:bg-lime-50 text-gray-700">
                  <div class="icon-circle bg-lime-50">
                    <CreditCard class="icon text-lime-600" />
                  </div>
                  <span>Transactions</span>
                </NuxtLink>

                <!-- Membership -->
                <NuxtLink to="/upgrade-to-pro" class="service-btn bg-white hover:bg-pink-50 text-gray-700">
                  <div class="icon-circle bg-pink-50">
                    <User class="icon text-pink-600" />
                  </div>
                  <span>Membership</span>
                </NuxtLink>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>    
    <!-- Mobile service buttons -->
    <div class="md:hidden text-center px-0.5 py-3 bg-gradient-to-br from-green-50 to-blue-50 rounded-sm shadow-sm relative overflow-hidden">
      <div class="grid grid-cols-4 gap-0 border border-gray-100 rounded-lg overflow-hidden divide-x divide-y divide-gray-100 shadow-sm relative z-10">        
        <!-- Business Network -->        
         <NuxtLink to="/business-network" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-blue-50">
            <Globe class="mobile-icon text-blue-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Business Network</span>
          </div>
        </NuxtLink>
          <!-- News -->        
           <NuxtLink to="/adsy-news" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-amber-50">
            <Newspaper class="mobile-icon text-amber-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Adsy News</span>
          </div>
        </NuxtLink>          
        <!-- Earn Money -->
        <NuxtLink to="/#micro-gigs" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-emerald-50">
            <BadgeDollarSign class="mobile-icon text-emerald-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Earn Money</span>
          </div>
        </NuxtLink>        
        <!-- Eshop -->
        <NuxtLink to="/eshop" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-purple-50">
            <ShoppingCart class="mobile-icon text-purple-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">eShop</span>
          </div>
        </NuxtLink>        
        <!-- Sale Listings -->
        <NuxtLink to="/#sale-category" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-indigo-50">
            <ListFilter class="mobile-icon text-indigo-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Sale Listings</span>
          </div>
        </NuxtLink>        
        <!-- MindForce -->
        <NuxtLink to="/business-network/mindforce" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-cyan-50">
            <Brain class="mobile-icon text-cyan-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">MindForce</span>
          </div>
        </NuxtLink>

        <!-- Amar Seba -->
        <NuxtLink to="/#classified-services" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-rose-50">
            <Cog class="mobile-icon text-rose-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Amar Seba</span>
          </div>
        </NuxtLink>
        <!-- Shastho Sheba (Coming Soon) - Disabled appearance -->
        <div class="mobile-btn bg-white/70 relative opacity-80 cursor-not-allowed">
          <div class="mobile-icon-circle bg-gray-100">
            <HeartPulse class="mobile-icon text-gray-500" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm leading-tight text-gray-500">Shastho Sheba</span>
          </div>
          <span class="absolute top-1 right-1 bg-gray-400 text-white text-[8px] px-0.5 rounded-sm">Coming Soon</span>
        </div>

        <!-- Bill Pay (Coming Soon) - Disabled appearance -->
        <div class="mobile-btn bg-white/70 relative opacity-80 cursor-not-allowed">
          <div class="mobile-icon-circle bg-gray-100">
            <Receipt class="mobile-icon text-gray-500" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm leading-tight text-gray-500">Bill Pay</span>
          </div>
          <span class="absolute top-1 right-1 bg-gray-400 text-white text-[8px] px-0.5 rounded-sm">Coming Soon</span>
        </div>        
        <!-- Mobile Recharge -->
        <NuxtLink to="/mobile-recharge" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-orange-50">
            <Smartphone class="mobile-icon text-orange-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Mobile Recharge</span>
          </div>
        </NuxtLink>       
        <!-- Transactions -->
        <NuxtLink to="/deposit-withdraw" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-lime-50">
            <CreditCard class="mobile-icon text-lime-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Transactions</span>
          </div>
        </NuxtLink>

        <!-- Membership -->
        <NuxtLink to="/upgrade-to-pro" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-pink-50">
            <User class="mobile-icon text-pink-600" />
          </div>
          <div class="h-10 flex items-center justify-center">
            <span class="text-sm font-medium leading-tight text-gray-700">Membership</span>
          </div>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import {
  ChevronLeft,
  ChevronRight,
  DollarSign,
  Globe,
  Newspaper,
  ShoppingBag,
  BadgeDollarSign,
  ShoppingCart,
  ListFilter,
  Brain,
  HeartPulse,
  Cog,
  Receipt,
  Smartphone,
  CreditCard,
  User,
} from "lucide-vue-next";
const { get } = useApi();

// Sample slider images - replace with your actual images
const sliderImages = ref([]);

async function getSlideImages() {
  try {
    const res = await get("/banner-images/");
    if (res && res.data) {
      sliderImages.value = res.data;
    } else {
      console.error("Failed to fetch slider images:", res);
    }
  } catch (error) {
    console.error("Error fetching slider images:", error);
  }
}

await getSlideImages();

const currentSlide = ref(0);
let intervalId = null;
const sliderContainer = ref(null);
let touchStartX = 0;
let touchEndX = 0;
let isHandlingTouch = false;

const nextSlide = () => {
  currentSlide.value = (currentSlide.value + 1) % sliderImages.value.length;
};

const prevSlide = () => {
  currentSlide.value =
    currentSlide.value === 0
      ? sliderImages.value.length - 1
      : currentSlide.value - 1;
};

const goToSlide = (index) => {
  currentSlide.value = index;
  resetAutoSlideTimer();
};

// Reset the auto slide timer
const resetAutoSlideTimer = () => {
  if (intervalId) {
    clearInterval(intervalId);
  }
  intervalId = setInterval(() => {
    if (!isHandlingTouch) {
      nextSlide();
    }
  }, 5000);
};

// Touch event handlers
const handleTouchStart = (e) => {
  isHandlingTouch = true;
  touchStartX = e.touches[0].clientX;
};

const handleTouchMove = (e) => {
  if (!isHandlingTouch) return;
  touchEndX = e.touches[0].clientX;

  // Add visual feedback during swiping
  const swipeDiff = touchEndX - touchStartX;
  if (Math.abs(swipeDiff) > 30) {
    e.preventDefault(); // Prevent default only if significant swipe detected
    
    // Add visual feedback with classes
    if (sliderContainer.value) {
      sliderContainer.value.classList.remove('swiping-left', 'swiping-right');
      if (swipeDiff > 0) {
        sliderContainer.value.classList.add('swiping-right');
      } else {
        sliderContainer.value.classList.add('swiping-left');
      }
    }
  }
};

const handleTouchEnd = () => {
  if (!isHandlingTouch) return;
  
  const swipeDiff = touchEndX - touchStartX;
  const minSwipeDistance = 50; // Minimum distance to consider it a swipe
  
  if (swipeDiff > minSwipeDistance) {
    prevSlide(); // Swipe right = previous slide
  } else if (swipeDiff < -minSwipeDistance) {
    nextSlide(); // Swipe left = next slide
  }
  
  // Remove swiping classes
  if (sliderContainer.value) {
    sliderContainer.value.classList.remove('swiping-left', 'swiping-right');
  }
  
  isHandlingTouch = false;
  resetAutoSlideTimer();
};

const isHovering = ref(false);

const handleSliderHover = (isHover) => {
  isHovering.value = isHover;
};

// Start auto-sliding when component is mounted
onMounted(() => {
  resetAutoSlideTimer();
  
  // Add touch event listeners
  if (sliderContainer.value) {
    sliderContainer.value.addEventListener('touchstart', handleTouchStart, { passive: false });
    sliderContainer.value.addEventListener('touchmove', handleTouchMove, { passive: false });
    sliderContainer.value.addEventListener('touchend', handleTouchEnd);
  }
});

// Clean up interval when component is unmounted
onUnmounted(() => {
  if (intervalId) {
    clearInterval(intervalId);
  }
  
  // Remove touch event listeners
  if (sliderContainer.value) {
    sliderContainer.value.removeEventListener('touchstart', handleTouchStart);
    sliderContainer.value.removeEventListener('touchmove', handleTouchMove);
    sliderContainer.value.removeEventListener('touchend', handleTouchEnd);
  }
});
</script>

<style scoped>
.btn-primary {
  height: 2.5rem;
  background-color: transparent;
  border: 2px solid #10b981;
  color: #059669;
  border-radius: 0.5rem;
  font-size: 0.75rem;
  font-weight: 500;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}
@media (min-width: 640px) {
  .btn-primary {
    height: 2.75rem;
    font-size: 0.875rem;
  }
}
.btn-primary:hover {
  background-color: #ecfdf5;
  border-color: #059669;
  color: #047857;
}

.btn-secondary {
  height: 2.5rem;
  background-color: transparent;
  border: 2px solid #f59e0b;
  color: #d97706;
  border-radius: 0.5rem;
  font-size: 0.75rem;
  font-weight: 500;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}
@media (min-width: 640px) {
  .btn-secondary {
    height: 2.75rem;
    font-size: 0.875rem;
  }
}
.btn-secondary:hover {
  background-color: #fffbeb;
  border-color: #d97706;
  color: #b45309;
}

.text-shadow {
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
}

/* Service buttons for desktop */
.service-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.5rem;
  border-radius: 0;
  font-size: 0.75rem;
  font-weight: 500;
  transition: all 0.3s;
  min-height: 70px;
  position: relative;
  overflow: hidden;
}
.service-btn:hover {
  box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.05);
  transform: translateY(-1px);
  background-color: rgba(249, 250, 251, 0.8);
}

.service-btn::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  width: 0;
  height: 2px;
  background: linear-gradient(to right, #10b981, #3b82f6);
  transition: width 0.3s ease, left 0.3s ease;
}

.service-btn:hover::after {
  width: 80%;
  left: 10%;
}

.icon-circle {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.5rem;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.service-btn:hover .icon-circle {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.service-btn .icon {
  height: 1.25rem;
  width: 1.25rem;
  transition: transform 0.3s;
}

/* Mobile buttons */
.mobile-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.375rem;
  border-radius: 0;
  transition: all 0.3s;
  min-height: 55px;
}

.mobile-btn:active {
  transform: scale(0.97);
  background-color: rgba(249, 250, 251, 0.8);
}

.mobile-icon-circle {
  width: 1.75rem;
  height: 1.75rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.25rem;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}

.mobile-btn:active .mobile-icon-circle {
  transform: scale(0.95);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.mobile-icon {
  height: 1rem;
  width: 1rem;
}

.touch-slider {
  touch-action: pan-y;
  user-select: none;
}

.swipe-indicator {
  opacity: 0;
  transform: translateX(0);
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.swipe-indicator-left {
  transform: translateX(-10px);
}

.swipe-indicator-right {
  transform: translateX(10px);
}

.touch-slider.swiping-left .swipe-indicator-left {
  opacity: 0.8;
  transform: translateX(0);
}

.touch-slider.swiping-right .swipe-indicator-right {
  opacity: 0.8;
  transform: translateX(0);
}

.bg-pattern {
  position: relative;
  overflow: hidden;
}

.bg-pattern::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.05'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
  pointer-events: none;
  opacity: 0.5;
}
</style>
