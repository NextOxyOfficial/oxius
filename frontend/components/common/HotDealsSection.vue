<template>
  <!-- Hot Deals Categories - Optimized for Performance -->
  <section class="mb-4 relative">
    <!-- Simplified Background -->
    <div
      class="absolute inset-0 bg-gradient-to-r from-rose-500 to-orange-500 rounded-xl"
    ></div>
    <!-- Content Container -->
    <div class="relative z-10 px-2 py-3">
      <!-- Section Header -->
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center">
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="text-white mr-2"
            >
              <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
            </svg>
            <h2 class="text-xl font-semibold text-white drop-shadow-sm">
              Special Deals
            </h2>
          </div>
          <div
            class="ml-3 px-2 py-0.5 bg-white/20 text-white text-xs font-semibold rounded-full"
          >
            Limited Time
          </div>
        </div>
      </div>

      <!-- Two-column layout: Fixed Budget Finds + Scrollable Cards -->
      <div class="flex space-x-2">
        <!-- Optimized Cards Container -->
        <div class="flex-1 overflow-hidden">
          <div
            ref="hotDealsContainer"
            class="flex py-2 space-x-3 overflow-x-auto hide-scrollbar snap-x hot-deals-container"
          >
            <!-- Simplified Hot Deals Cards -->
            <div
              v-for="(deal, index) in specialDeals"
              :key="deal.id"
              class="flex-shrink-0 w-24 sm:w-[13%] bg-white/90 rounded-lg overflow-hidden border border-white/50 snap-start card-hover"
              @click="handleCardClick(deal)"
            >
              <NuxtLink :to="`/eshop/category/${deal.slug}`" class="block">
                <div class="relative h-[80px] overflow-hidden rounded-t-lg">
                  <div
                    class="absolute inset-0 bg-gradient-to-b from-transparent"
                    :class="deal.badge_color"
                  ></div>
                  <img
                    :src="deal.image"
                    :alt="deal.name"
                    class="w-full h-full object-contain md:object-contain"
                    loading="lazy"
                  />

                  <div
                    class="absolute top-0 left-0 text-white text-xs font-semibold px-1.5 py-0.5 rounded-br z-20"
                    :class="deal.badge_color"
                  >
                    {{ deal.badge }}
                  </div>
                </div>
                <div class="p-2 text-center">
                  <h3 class="font-medium text-sm text-gray-800">
                    {{ deal.name }}
                  </h3>
                </div>
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
      <!-- Simple scroll indicator -->
      <div
        class="absolute right-2 top-1/2 -translate-y-1/2 pointer-events-none"
      >
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
          class="text-white/50"
        >
          <path d="m9 18 6-6-6-6" />
        </svg>
      </div>
    </div>
  </section>
</template>

<script setup>
const { get } = useApi();
const emit = defineEmits(["setCategory"]);
const specialDeals = ref([]);

async function fetchSpecialDeals() {
  try {
    const response = await get("/product-categories/?special_offer=true");
    specialDeals.value = response.data;
  } catch (error) {
    console.error("Error fetching hot deals:", error);
  }
}

await fetchSpecialDeals();

function handleCardClick(deal) {
  emit("setCategory", deal.id);
}

// Get reference to hot deals container
const hotDealsContainer = ref(null);

// Optimized drag functionality
const isDragging = ref(false);
const startX = ref(0);
const scrollLeft = ref(0);

const startDrag = (e) => {
  if (!hotDealsContainer.value) return;
  isDragging.value = true;
  startX.value = e.pageX - hotDealsContainer.value.offsetLeft;
  scrollLeft.value = hotDealsContainer.value.scrollLeft;
};

const onDrag = (e) => {
  if (!isDragging.value || !hotDealsContainer.value) return;
  e.preventDefault();
  const x = e.pageX - hotDealsContainer.value.offsetLeft;
  const walk = (x - startX.value) * 1.2;
  hotDealsContainer.value.scrollLeft = scrollLeft.value - walk;
};

const endDrag = () => {
  isDragging.value = false;
};

onMounted(() => {
  if (hotDealsContainer.value) {
    hotDealsContainer.value.addEventListener("mousedown", startDrag);
    document.addEventListener("mousemove", onDrag);
    document.addEventListener("mouseup", endDrag);
    hotDealsContainer.value.addEventListener("mouseleave", endDrag);
  }
});

onUnmounted(() => {
  if (hotDealsContainer.value) {
    hotDealsContainer.value.removeEventListener("mousedown", startDrag);
  }
  document.removeEventListener("mousemove", onDrag);
  document.removeEventListener("mouseup", endDrag);
  if (hotDealsContainer.value) {
    hotDealsContainer.value.removeEventListener("mouseleave", endDrag);
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
.hot-deals-container {
  cursor: grab;
  user-select: none;
}
.hot-deals-container:active {
  cursor: grabbing;
}
</style>
