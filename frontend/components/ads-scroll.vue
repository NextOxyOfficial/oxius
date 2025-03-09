<template>
  <UContainer>
    <div class="ads-container">
      <div class="ads-header">
        <div class="ads-title">
          <UIcon
            name="i-fluent-clock-20-regular"
            class="clock-icon"
            size="18"
          />
          <h2>FEATURED ADS</h2>
        </div>
        <div class="pagination-dots">
          <span
            v-for="(_, index) in Math.ceil(ads.length / 2)"
            :key="index"
            :class="['dot', { active: index === activeDotIndex }]"
          ></span>
        </div>
      </div>

      <div
        ref="carouselRef"
        class="ads-carousel"
        @touchstart="handleTouchStart"
        @touchmove="handleTouchMove"
        @touchend="handleTouchEnd"
        @mouseenter="pauseAutoScroll"
        @mouseleave="resumeAutoScroll"
      >
        <div
          ref="carouselInnerRef"
          class="carousel-inner"
          :style="carouselStyle"
        >
          <div v-for="(ad, index) in displayedAds" :key="index" class="ad-card">
            <div class="ad-image">
              <img :src="ad.image" :alt="ad.title" />
            </div>
            <div class="ad-content">
              <h3>{{ ad.title }}</h3>
              <div class="ad-location">{{ ad.location }}</div>
              <div class="ad-footer">
                <div class="ad-price">${{ formatPrice(ad.price) }}</div>
                <div class="ad-date">
                  <UIcon
                    name="i-uit-calender"
                    class="w-3.5 h-3.5 text-gray-500"
                  />
                  <span>{{ ad.date }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from "vue";

// Sample data - in a real app, this would come from an API
const initialAds = [
  {
    id: 1,
    title: "Audi R8",
    location: "New York, US",
    price: 4850000,
    date: "5 Aug",
    image:
      "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/WhatsApp%20Image%202025-03-09%20at%201.51.03%20PM-UamQHftOoT8mzSm9X2ss9noKhTuuJb.jpeg",
  },
  {
    id: 2,
    title: "Luxury Home Near New York",
    location: "New York, US",
    price: 4850000,
    date: "25 Aug",
    image:
      "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=2070",
  },
  {
    id: 3,
    title: "Waterfront Villa",
    location: "Miami, US",
    price: 3250000,
    date: "12 Aug",
    image:
      "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=2075",
  },
  {
    id: 4,
    title: "Tesla Model S",
    location: "Los Angeles, US",
    price: 89000,
    date: "3 Aug",
    image:
      "https://images.unsplash.com/photo-1617788138017-80ad40651399?q=80&w=2070",
  },
];

// State
const ads = ref([...initialAds]);
const carouselRef = ref(null);
const carouselInnerRef = ref(null);
const cardWidth = ref(220);
const scrollPosition = ref(0);
const isDragging = ref(false);
const startX = ref(0);
const startScrollPos = ref(0);
const isPaused = ref(false);
const activeDotIndex = ref(0);
const animationSpeed = ref(0.5); // pixels per frame
let animationId = null;

// For infinite scroll effect, duplicate the ads multiple times
const displayedAds = computed(() => {
  // Create a circular array by duplicating the ads multiple times
  return [...ads.value, ...ads.value, ...ads.value, ...ads.value];
});

// Computed style for the carousel
const carouselStyle = computed(() => {
  if (isDragging.value) {
    return {
      transform: `translateX(${-scrollPosition.value}px)`,
      transition: "none",
    };
  }

  return {
    transform: `translateX(${-scrollPosition.value}px)`,
    transition: isPaused.value ? "transform 0.5s ease-out" : "none",
  };
});

// Touch handling
const handleTouchStart = (e) => {
  isDragging.value = true;
  startX.value = e.touches[0].clientX;
  startScrollPos.value = scrollPosition.value;
  pauseAutoScroll();
};

const handleTouchMove = (e) => {
  if (!isDragging.value) return;

  const currentX = e.touches[0].clientX;
  const diff = currentX - startX.value;

  // Move in the opposite direction of the drag
  scrollPosition.value = startScrollPos.value - diff;
};

const handleTouchEnd = (e) => {
  if (!isDragging.value) return;

  isDragging.value = false;

  // Resume auto-scrolling after a delay
  setTimeout(() => {
    resumeAutoScroll();
  }, 1000);
};

// Auto-scroll functionality
const animateScroll = () => {
  if (isPaused.value) {
    animationId = requestAnimationFrame(animateScroll);
    return;
  }

  scrollPosition.value += animationSpeed.value;

  // Check if we need to reset the scroll position for infinite loop
  if (carouselInnerRef.value) {
    const totalWidth = (cardWidth.value + 16) * ads.value.length;

    // When we've scrolled past the first set of items, reset to the beginning
    if (scrollPosition.value >= totalWidth) {
      scrollPosition.value = 0;
    }

    // Update active dot based on current position
    const newActiveDotIndex = Math.floor(
      (scrollPosition.value % totalWidth) / (totalWidth / ads.value.length)
    );
    if (newActiveDotIndex !== activeDotIndex.value) {
      activeDotIndex.value = newActiveDotIndex;
    }
  }

  animationId = requestAnimationFrame(animateScroll);
};

const pauseAutoScroll = () => {
  isPaused.value = true;
};

const resumeAutoScroll = () => {
  isPaused.value = false;
};

// Format price with commas
const formatPrice = (price) => {
  return price.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
};

// Lifecycle hooks
onMounted(() => {
  // Get the actual card width based on the container
  if (carouselRef.value) {
    const containerWidth = carouselRef.value.clientWidth;

    // For mobile screens (width < 640px), show 1.5 cards
    if (containerWidth < 640) {
      cardWidth.value = containerWidth * 0.7 - 16; // 70% of container width minus margin
      // Adjust animation speed based on screen size
      animationSpeed.value = 0.3;
    } else {
      cardWidth.value = containerWidth / 2 - 16; // 2 cards per view
      animationSpeed.value = 0.5;
    }
  }

  // Start the continuous animation
  animationId = requestAnimationFrame(animateScroll);
});

onUnmounted(() => {
  // Clean up animation frame on component unmount
  if (animationId) {
    cancelAnimationFrame(animationId);
  }
});

// Watch for window resize to adjust card width
window.addEventListener("resize", () => {
  if (carouselRef.value) {
    const containerWidth = carouselRef.value.clientWidth;

    // For mobile screens (width < 640px), show 1.5 cards
    if (containerWidth < 640) {
      cardWidth.value = containerWidth * 0.7 - 16; // 70% of container width minus margin
      animationSpeed.value = 0.3;
    } else {
      cardWidth.value = containerWidth / 2 - 16;
      animationSpeed.value = 0.5;
    }
  }
});
</script>

<style scoped>
.ads-container {
  width: 100%;
  max-width: 100%;
  overflow: hidden;
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  padding: 16px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
    Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;
}

.ads-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.ads-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.clock-icon {
  color: #666;
}

h2 {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.pagination-dots {
  display: flex;
  gap: 4px;
}

.dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #ddd;
  transition: background-color 0.3s ease;
}

.dot.active {
  background-color: #ff6b00;
}

.ads-carousel {
  position: relative;
  overflow: hidden;
  touch-action: pan-y;
}

.carousel-inner {
  display: flex;
  gap: 16px;
  will-change: transform;
}

.ad-card {
  flex: 0 0 auto;
  width: calc(50% - 8px);
  min-width: 200px;
  max-width: 300px;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  background-color: white;
}

.ad-image {
  width: 100%;
  height: 120px;
  overflow: hidden;
}

.ad-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ad-content {
  padding: 10px;
}

h3 {
  margin: 0 0 4px 0;
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

.ad-location {
  font-size: 12px;
  color: #666;
  margin-bottom: 10px;
}

.ad-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ad-price {
  font-weight: 700;
  font-size: 14px;
  color: #333;
}

.ad-date {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #888;
}

@media (max-width: 640px) {
  .ad-card {
    width: 70%;
  }
}

@media (min-width: 641px) and (max-width: 1024px) {
  .ad-card {
    width: calc(50% - 16px);
  }
}

@media (min-width: 1025px) {
  .ad-card {
    width: calc(33.333% - 16px);
  }
}
</style>
