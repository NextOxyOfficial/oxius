<template>
  <div class="w-full max-w-7xl sm:px-2 mx-auto bg-slate-50">
    <!-- Content Container -->
    <div class="relative z-10">
      <!-- 1. Main Carousel -->
      <section class="mb-8 pt-2">
        <CommonEshopBanner
          :customHeight="{
            mobile: '38%',
            tablet: '25%',
            desktop: '22%',
          }"
          endpoint="/eshop-banner/"
          :autoplayInterval="5000"
        />
      </section>

      <!-- 2. Hot Deals Section - Using the new separated component -->
      <CommonHotDealsSection />

      <!-- 3. New & Hot Arrivals (4 cards initially visible) -->
      <section class="mb-4 mt-6 relative">
        <div class="flex items-center justify-between mt-3 mb-2 sm:px-6">
          <div class="flex items-center">
            <div
              class="w-1 h-6 bg-gradient-to-b from-emerald-400 to-emerald-600 rounded-full mr-2"
            ></div>
            <h2 class="text-lg font-medium text-gray-800">
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
            {{ $t("view_all") }}
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
        <!-- Optimized card container -->
        <div class="relative overflow-hidden">
          <div
            ref="arrivalsContainer"
            class="flex space-x-2 overflow-x-auto pb-4 pt-2 px-2 -mx-2 hide-scrollbar snap-x arrivals-container"
          >
            <!-- Optimized New Arrivals Cards -->
            <div
              v-for="(card, index) in hotArrivals"
              :key="card.id"
              class="flex-shrink-0 w-[26%] sm:w-[11%] bg-white rounded-lg overflow-hidden border border-gray-100 snap-start card-hover"
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
import { ref, onMounted, onUnmounted } from "vue";

const { get } = useApi();

const hotArrivals = ref([]);

async function fetchHotArrivals() {
  try {
    const response = await get("/product-categories/?hot_arrival=true");
    hotArrivals.value = response.data;
  } catch (error) {
    console.error("Error fetching hot deals:", error);
  }
}

await fetchHotArrivals();

// Optimized drag functionality
const arrivalsContainer = ref(null);
const isDragging = ref(false);
const startX = ref(0);
const scrollLeft = ref(0);

const startDrag = (e) => {
  if (!arrivalsContainer.value) return;
  isDragging.value = true;
  startX.value = e.pageX - arrivalsContainer.value.offsetLeft;
  scrollLeft.value = arrivalsContainer.value.scrollLeft;
};

const onDrag = (e) => {
  if (!isDragging.value || !arrivalsContainer.value) return;
  e.preventDefault();
  const x = e.pageX - arrivalsContainer.value.offsetLeft;
  const walk = (x - startX.value) * 1.2;
  arrivalsContainer.value.scrollLeft = scrollLeft.value - walk;
};

const endDrag = () => {
  isDragging.value = false;
};

onMounted(() => {
  if (arrivalsContainer.value) {
    arrivalsContainer.value.addEventListener("mousedown", startDrag);
    document.addEventListener("mousemove", onDrag);
    document.addEventListener("mouseup", endDrag);
    arrivalsContainer.value.addEventListener("mouseleave", endDrag);
  }
});

onUnmounted(() => {
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
/* Optimized and minified CSS for better performance */
.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
.snap-x {
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
}
.snap-start {
  scroll-snap-align: start;
}
.card-hover {
  transition: transform 0.2s ease;
  cursor: pointer;
}
.card-hover:hover {
  transform: translateY(-2px);
}
.arrivals-container {
  cursor: grab;
  user-select: none;
}
.arrivals-container:active {
  cursor: grabbing;
}
@media (min-width: 768px) {
  .hide-scrollbar {
    overflow-x: auto;
    display: flex;
    flex-wrap: nowrap;
  }
}
</style>
