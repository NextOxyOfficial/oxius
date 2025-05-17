<template>  <div id="home" class="mb-4 py-6 bg-gradient-to-br from-emerald-800 to-blue-900 relative bg-pattern">
    <div class="max-w-7xl w-full mx-auto px-3">
      <div
        class="rounded-3xl overflow-hidden shadow-xl"
      >
        <div class="flex flex-col md:flex-row">          <!-- Left side - Image Slider with reduced height -->
          <div class="w-full md:w-3/5 relative overflow-hidden touch-slider" ref="sliderContainer">
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
            <div class="relative pb-[45%] md:pb-[45%] lg:pb-[45%]">
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
            </div>            <!-- Navigation arrows - hidden on mobile but visible on desktop -->
            <button
              @click="prevSlide"
              class="hidden md:flex absolute left-3 top-1/2 -translate-y-1/2 bg-white/20 backdrop-blur-sm hover:bg-white/40 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 border border-white/30 shadow-lg"
              aria-label="Previous slide"
            >
              <ChevronLeft class="h-5 w-5 text-white" />
            </button>

            <button
              @click="nextSlide"
              class="hidden md:flex absolute right-3 top-1/2 -translate-y-1/2 bg-white/20 backdrop-blur-sm hover:bg-white/40 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 border border-white/30 shadow-lg"
              aria-label="Next slide"
            >
              <ChevronRight class="h-5 w-5 text-white" />
            </button>

            <!-- Slider indicators - improved -->
            <div
              class="absolute bottom-4 left-1/2 -translate-x-1/2 flex space-x-3 z-20"
            >
              <button
                v-for="(_, index) in sliderImages"
                :key="index"
                @click="goToSlide(index)"
                class="w-2.5 h-2.5 rounded-full transition-all duration-300"
                :class="{
                  'bg-white scale-110': index === currentSlide,
                  'bg-white/40 hover:bg-white/60': index !== currentSlide,
                }"
                :aria-label="`Go to slide ${index + 1}`"
              ></button>
            </div>
          </div>          <!-- Right side - Premium content area -->
          <div class="w-full md:w-2/5 p-4 sm:p-8 flex flex-col justify-center bg-white">
            <div class="relative">
              <h1
                class="text-lg sm:text-2xl font-bold leading-tight text-gray-800 mb-6 relative inline-block"
              >
                <span class="relative z-10">{{ $t("bangladesh_first_title") }}</span>
                <span class="absolute bottom-1 left-0 w-full h-2 bg-emerald-100 -z-10"></span>
              </h1>
              <!-- Service buttons grid with cool design -->
              <div class="grid grid-cols-4 gap-0 mt-4 hidden md:grid border border-gray-100 rounded-lg overflow-hidden divide-x divide-y divide-gray-100">
                <!-- Business Network -->
                <NuxtLink to="/business-network" class="service-btn bg-white hover:bg-blue-50 text-gray-700">
                  <div class="icon-circle bg-blue-50">
                    <Globe class="icon text-blue-600" />
                  </div>
                  <span>Business Network</span>
                </NuxtLink>                  <!-- News -->
                <NuxtLink to="/adsy-news" class="service-btn bg-white hover:bg-amber-50 text-gray-700">
                  <div class="icon-circle bg-amber-50">
                    <Newspaper class="icon text-amber-600" />
                  </div>
                  <span>News</span>
                </NuxtLink>                  <!-- Earn Money -->
                <NuxtLink to="/earn-money" class="service-btn bg-white hover:bg-emerald-50 text-gray-700">
                  <div class="icon-circle bg-emerald-50">
                    <BadgeDollarSign class="icon text-emerald-600" />
                  </div>
                  <span>Earn Money</span>
                </NuxtLink>                <!-- Eshop -->
                <NuxtLink to="/eshop" class="service-btn bg-white hover:bg-purple-50 text-gray-700">
                  <div class="icon-circle bg-purple-50">
                    <ShoppingCart class="icon text-purple-600" />
                  </div>
                  <span>Eshop</span>
                </NuxtLink>                <!-- Sale Listings -->
                <NuxtLink to="/sale-listings" class="service-btn bg-white hover:bg-indigo-50 text-gray-700">
                  <div class="icon-circle bg-indigo-50">
                    <ListFilter class="icon text-indigo-600" />
                  </div>
                  <span>Sale Listings</span>
                </NuxtLink>

                <!-- Mindforce -->
                <NuxtLink to="/mindforce" class="service-btn bg-white hover:bg-cyan-50 text-gray-700">
                  <div class="icon-circle bg-cyan-50">
                    <Brain class="icon text-cyan-600" />
                  </div>
                  <span>Mindforce</span>
                </NuxtLink>

                <!-- Amar Seba -->
                <NuxtLink to="/amar-seba" class="service-btn bg-white hover:bg-rose-50 text-gray-700">
                  <div class="icon-circle bg-rose-50">
                    <Cog class="icon text-rose-600" />
                  </div>
                  <span>Amar Seba</span>
                </NuxtLink>                <!-- Shastho Sheba (Coming Soon) -->
                <div class="service-btn bg-white text-gray-700 relative">
                  <div class="icon-circle bg-red-50">
                    <HeartPulse class="icon text-red-500" />
                  </div>
                  <span>Shastho Sheba</span>
                  <span class="absolute -top-1 -right-1 bg-red-500 text-white text-[8px] px-1 py-0.5 rounded-sm">Coming soon</span>
                </div>

                <!-- Bill Pay (Coming Soon) -->
                <div class="service-btn bg-white text-gray-700 relative">
                  <div class="icon-circle bg-gray-50">
                    <Receipt class="icon text-gray-500" />
                  </div>
                  <span>Bill Pay</span>
                  <span class="absolute -top-1 -right-1 bg-red-500 text-white text-[8px] px-1 py-0.5 rounded-sm">Coming soon</span>
                </div>                <!-- Mobile Recharge -->
                <NuxtLink to="/mobile-recharge" class="service-btn bg-white hover:bg-orange-50 text-gray-700">
                  <div class="icon-circle bg-orange-50">
                    <Smartphone class="icon text-orange-600" />
                  </div>
                  <span>Mobile Recharge</span>
                </NuxtLink>                <!-- Transactions -->
                <NuxtLink to="/transactions" class="service-btn bg-white hover:bg-lime-50 text-gray-700">
                  <div class="icon-circle bg-lime-50">
                    <CreditCard class="icon text-lime-600" />
                  </div>
                  <span>Transactions</span>
                </NuxtLink>

                <!-- Membership -->
                <NuxtLink to="/membership" class="service-btn bg-white hover:bg-pink-50 text-gray-700">
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
    </div>    <!-- Mobile service buttons -->
    <div class="md:hidden px-3 py-4 bg-gradient-to-br from-emerald-50 to-blue-50 rounded-lg shadow-lg my-4">
      <h2 class="text-base font-semibold text-gray-800 mb-3 text-center">Our Services</h2>
      <div class="grid grid-cols-4 gap-0 border border-gray-100 rounded-lg overflow-hidden divide-x divide-y divide-gray-100"><!-- Business Network -->        <NuxtLink to="/business-network" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-blue-50">
            <Globe class="mobile-icon text-blue-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Network</span>
        </NuxtLink>
          <!-- News -->        <NuxtLink to="/adsy-news" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-amber-50">
            <Newspaper class="mobile-icon text-amber-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">News</span>
        </NuxtLink>
          <!-- Earn Money -->
        <NuxtLink to="/earn-money" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-emerald-50">
            <BadgeDollarSign class="mobile-icon text-emerald-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Earn</span>
        </NuxtLink>        <!-- Eshop -->
        <NuxtLink to="/eshop" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-purple-50">
            <ShoppingCart class="mobile-icon text-purple-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Eshop</span>
        </NuxtLink>        <!-- Sale Listings -->
        <NuxtLink to="/sale-listings" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-indigo-50">
            <ListFilter class="mobile-icon text-indigo-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Sale</span>
        </NuxtLink>

        <!-- Mindforce -->
        <NuxtLink to="/mindforce" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-cyan-50">
            <Brain class="mobile-icon text-cyan-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Mindforce</span>
        </NuxtLink>

        <!-- Amar Seba -->
        <NuxtLink to="/amar-seba" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-rose-50">
            <Cog class="mobile-icon text-rose-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Amar Seba</span>
        </NuxtLink>        <!-- Shastho Sheba (Coming Soon) -->
        <div class="mobile-btn bg-white relative">
          <div class="mobile-icon-circle bg-red-50">
            <HeartPulse class="mobile-icon text-red-500" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Shastho</span>
          <span class="absolute -top-1 -right-1 bg-red-500 text-white text-[6px] px-0.5 rounded-sm">Soon</span>
        </div>

        <!-- Bill Pay (Coming Soon) -->
        <div class="mobile-btn bg-white relative">
          <div class="mobile-icon-circle bg-gray-50">
            <Receipt class="mobile-icon text-gray-500" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Bill Pay</span>
          <span class="absolute -top-1 -right-1 bg-red-500 text-white text-[6px] px-0.5 rounded-sm">Soon</span>
        </div>

        <!-- Mobile Recharge -->
        <NuxtLink to="/mobile-recharge" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-orange-50">
            <Smartphone class="mobile-icon text-orange-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Recharge</span>
        </NuxtLink>        <!-- Transactions -->
        <NuxtLink to="/transactions" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-lime-50">
            <CreditCard class="mobile-icon text-lime-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Transactions</span>
        </NuxtLink>

        <!-- Membership -->
        <NuxtLink to="/membership" class="mobile-btn bg-white">
          <div class="mobile-icon-circle bg-pink-50">
            <User class="mobile-icon text-pink-600" />
          </div>
          <span class="text-[10px] leading-tight text-gray-700">Member</span>
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
}
.service-btn:hover {
  box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
}

.icon-circle {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.5rem;
  transition: transform 0.2s;
}

.service-btn:hover .icon-circle {
  transform: scale(1.1);
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
</style>
