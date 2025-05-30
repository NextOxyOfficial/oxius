<template>
  <div
    class="w-full max-w-7xl sm:px-2 mx-auto bg-gradient-to-br from-slate-50 via-white to-slate-50"
  >
    <!-- Content Container -->

    <div class="relative z-10">      <!-- 1. Main Carousel -->
      <section class="mb-8 pt-2">
        <CommonEshopBanner 
          :customHeight="{
            mobile: '38%',
            tablet: '25%',
            desktop: '22%'
          }"
          endpoint="/eshop-banner/"
          :autoplayInterval="5000"
        />
      </section>

      <!-- 2. Hot Deals Section - Using the new separated component -->
      <CommonHotDealsSection />

      <!-- 3. New & Hot Arrivals (4 cards initially visible) -->
      <section class="mb-4 mt-6 relative">
        <div class="flex items-center justify-between mt-3 mb-2">
          <div class="flex items-center">
            <div
              class="w-1 h-6 bg-gradient-to-b from-emerald-400 to-emerald-600 rounded-full mr-2"
            ></div>
            <h2 class="text-lg font-semibold text-gray-800">
              New & Hot Arrivals
            </h2>
            <div
              class="ml-2 px-2 py-0.5 bg-emerald-100 text-emerald-600 text-xs font-semibold rounded-full"
            >
              Just In
            </div>
          </div>
          <a
            href="/eshop"
            class="text-emerald-600 hover:underline flex items-center text-sm font-medium"
          >
            View All
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="ml-1"
            >
              <path d="m9 18 6-6-6-6" />
            </svg>
          </a>
        </div>

        <!-- Card container - 4 cards initially visible -->
        <div class="relative overflow-hidden">
          <div
            ref="arrivalsContainer"
            class="flex space-x-2 overflow-x-auto pb-4 pt-2 px-2 -mx-2 hide-scrollbar snap-x snap-mandatory arrivals-container"
          >
            <!-- Dynamic New Arrivals Cards -->
            <div
              v-for="(card, index) in hotArrivals"
              :key="card.id"
              class="flex-shrink-0 w-[26%] sm:w-[11%] space-x-2 bg-white rounded-lg overflow-visible shadow-sm hover:shadow-sm transition-all duration-300 transform hover:-translate-y-1 border border-gray-100 snap-start card-hover"
            >
              <NuxtLink :to="`/eshop/category/${card.slug}`" class="block">
                <div class="relative h-[70px] overflow-hidden rounded-t-lg">
                  <div
                    class="absolute inset-0 bg-gradient-to-b from-transparent"
                    :class="card.badge_color"
                  ></div>
                  <img
                    :src="card.image"
                    :alt="card.name"
                    class="w-full h-full object-contain"
                    loading="lazy"
                  />
                  <div
                    class="absolute top-0 right-0 text-white text-xs font-semibold px-1.5 py-0.5 rounded-bl z-20"
                    :class="card.badge_color"
                  >
                    {{ card.badge }}
                  </div>
                </div>
                <div class="p-2 text-center">
                  <h3 class="font-medium text-sm text-gray-800">
                    {{ card.name }}
                  </h3>
                </div>
              </NuxtLink>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ca } from "date-fns/locale";
import { ref, onMounted, onUnmounted } from "vue";

const { get } = useApi();

const hotArrivals = ref([]);

async function fetchHotArrivals() {
  try {
    const response = await get("/product-categories/?hot_arrival=true");
    hotArrivals.value = response.data;
    console.log("Hot Arrivals:", hotArrivals.value);
  } catch (error) {
    console.error("Error fetching hot deals:", error);
  }
}

await fetchHotArrivals();

// New Arrivals Cards
const newArrivalsCards = [
  {
    title: "AC",
    badge: "NEW",
    badgeClass: "bg-cyan-600",
    image:
      "https://images.unsplash.com/photo-1580655653885-65763b2597d0?q=80&w=2070",
    link: "#/search?category=ac",
    gradientClass: "to-cyan-500/70",
  },
  {
    title: "Fashion",
    badge: "HOT",
    badgeClass: "bg-rose-600",
    image:
      "https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=2071",
    link: "#/search?category=fashion",
    gradientClass: "to-rose-500/70",
  },
  {
    title: "Shoes",
    badge: "NEW",
    badgeClass: "bg-amber-600",
    image:
      "https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=2070",
    link: "#/search?category=shoes",
    gradientClass: "to-amber-500/70",
  },
  {
    title: "Motorcycle",
    badge: "HOT",
    badgeClass: "bg-purple-600",
    image:
      "https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=2070",
    link: "#/search?category=motorcycle",
    gradientClass: "to-purple-500/70",
  },
  {
    title: "Mobile",
    badge: "NEW",
    badgeClass: "bg-emerald-600",
    image:
      "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=2080",
    link: "#/search?category=mobile",
    gradientClass: "to-emerald-500/70",
  },
  {
    title: "Kitchen",
    badge: "HOT",
    badgeClass: "bg-orange-600",
    image:
      "https://images.unsplash.com/photo-1556911220-bff31c812dba?q=80&w=2068",
    link: "#/search?category=kitchen",
    gradientClass: "to-orange-500/70",
  },
  {
    title: "Gadgets",
    badge: "NEW",
    badgeClass: "bg-gray-700",
    image:
      "https://images.unsplash.com/photo-1519558260268-cde7e03a0152?q=80&w=2070",
    link: "#/search?category=gadgets",
    gradientClass: "to-gray-700/70",
  },
  {
    title: "Laptops",
    badge: "NEW",
    badgeClass: "bg-blue-600",
    image:
      "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=2071",
    link: "#/search?category=laptops",
    gradientClass: "to-blue-500/70",
  },
  {
    title: "Watches",
    badge: "HOT",
    badgeClass: "bg-pink-600",
    image:
      "https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=2088",
    link: "#/search?category=watches",
    gradientClass: "to-pink-500/70",
  },
  {
    title: "Cameras",
    badge: "NEW",
    badgeClass: "bg-indigo-600",
    image:
      "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=2038",
    link: "#/search?category=cameras",
    gradientClass: "to-indigo-500/70",
  },
  {
    title: "Audio",
    badge: "HOT",
    badgeClass: "bg-red-600",
    image:
      "https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=2065",
    link: "#/search?category=audio",
    gradientClass: "to-red-500/70",
  },
  {
    title: "Gaming",
    badge: "NEW",
    badgeClass: "bg-violet-600",
    image:
      "https://images.unsplash.com/photo-1593305841991-05c297ba4575?q=80&w=2057",
    link: "#/search?category=gaming",
    gradientClass: "to-violet-500/70",
  },
];

// Carousel functionality was moved to the EshopBanner component

// Mouse drag functionality with better performance
// Using requestAnimationFrame for smoother scrolling
const arrivalsContainer = ref(null);
const isDragging = ref(false);
const startX = ref(0);
const scrollLeft = ref(0);

// Start drag with improved handling
const startDrag = (e) => {
  if (!arrivalsContainer.value) return;

  isDragging.value = true;
  startX.value = e.pageX - arrivalsContainer.value.offsetLeft;
  scrollLeft.value = arrivalsContainer.value.scrollLeft;

  // Change cursor
  arrivalsContainer.value.style.cursor = "grabbing";
  arrivalsContainer.value.style.userSelect = "none";
};

// During drag with requestAnimationFrame for smoother performance
const onDrag = (e) => {
  if (!isDragging.value || !arrivalsContainer.value) return;
  e.preventDefault();

  const x = e.pageX - arrivalsContainer.value.offsetLeft;
  const walk = (x - startX.value) * 1.5; // Reduced multiplier for smoother scrolling

  requestAnimationFrame(() => {
    if (arrivalsContainer.value) {
      arrivalsContainer.value.scrollLeft = scrollLeft.value - walk;
    }
  });
};

// End drag
const endDrag = () => {
  isDragging.value = false;

  if (arrivalsContainer.value) {
    arrivalsContainer.value.style.cursor = "grab";
    arrivalsContainer.value.style.removeProperty("user-select");
  }
};

onMounted(() => {
  // Add entrance animations for sections with staggered timing
  const sections = document.querySelectorAll("section");
  sections.forEach((section, index) => {
    setTimeout(() => {
      section.classList.add("animate-section-enter");
    }, index * 150); // Reduced timing for smoother appearance
  });

  // Add optimized mouse drag functionality to arrivals container
  if (arrivalsContainer.value) {
    arrivalsContainer.value.style.cursor = "grab";

    // Use passive event listeners where possible for better performance
    arrivalsContainer.value.addEventListener("mousedown", startDrag, {
      passive: false,
    });
    document.addEventListener("mousemove", onDrag, { passive: false });
    document.addEventListener("mouseup", endDrag, { passive: true });
    arrivalsContainer.value.addEventListener("mouseleave", endDrag, {
      passive: true,
    });
  }
});

onUnmounted(() => {
  // Remove event listeners
  if (arrivalsContainer.value) {
    arrivalsContainer.value.removeEventListener("mousedown", startDrag);
  }
  document.removeEventListener("mousemove", onDrag);
  document.removeEventListener("mouseup", endDrag);
  if (arrivalsContainer.value) {
    arrivalsContainer.value.removeEventListener("mouseleave", endDrag);
  }
});
</script>

<style scoped>
/* Background pattern */
.bg-pattern {
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%239C92AC' fill-opacity='0.1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

section {
  opacity: 0;
  transform: translateY(10px);
  transition: opacity 0.5s ease-out, transform 0.5s ease-out;
  will-change: opacity, transform; /* Enables hardware acceleration */
}

.animate-section-enter {
  opacity: 1;
  transform: translateY(0);
}

/* Performance optimized image handling */
img {
  transition: transform 0.5s ease-in-out;
  will-change: transform;
  transform: translateZ(0); /* Force GPU rendering */
  backface-visibility: hidden;
}

/* Hide scrollbar but keep functionality */
.hide-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
}

/* Snap scrolling with improved performance */
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
.shadow-sm {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1),
    0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.hover\:shadow-sm:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05);
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
.arrivals-container {
  cursor: grab;
}

.arrivals-container:active {
  cursor: grabbing;
}
</style>
