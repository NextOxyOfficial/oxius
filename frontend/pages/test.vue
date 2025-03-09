<template>
  <div class="classified-ads-container w-full overflow-hidden bg-gray-50 py-6">
    <h2 class="text-center text-2xl font-bold mb-4">Classified Ads</h2>

    <!-- First row of ads -->
    <div class="relative overflow-hidden mb-4">
      <div
        class="ads-row flex animate-scroll"
        :style="{
          animationDuration: `${firstRowDuration}s`,
          animationPlayState: isPaused ? 'paused' : 'running',
        }"
        @mouseenter="isPaused = true"
        @mouseleave="isPaused = false"
      >
        <div
          v-for="(ad, index) in firstRowAds"
          :key="`row1-${index}`"
          class="ad-card"
        >
          <div
            class="bg-white rounded-lg shadow-md p-4 mx-2 min-w-[280px] h-[160px] flex flex-col"
          >
            <div class="flex items-center mb-2">
              <div
                class="w-12 h-12 bg-gray-200 rounded-full overflow-hidden mr-3"
              >
                <img
                  :src="`/placeholder.svg?height=48&width=48&text=${ad.category}`"
                  alt=""
                  class="w-full h-full object-cover"
                />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">{{ ad.title }}</h3>
                <p class="text-xs text-gray-500">{{ ad.category }}</p>
              </div>
            </div>
            <p class="text-sm text-gray-600 flex-grow">{{ ad.description }}</p>
            <div class="flex justify-between items-center mt-2">
              <span class="text-primary font-bold"
                >${{ ad.price.toFixed(2) }}</span
              >
              <button
                class="text-xs bg-primary text-white px-3 py-1 rounded-full hover:bg-primary/90 transition-colors"
              >
                Contact
              </button>
            </div>
          </div>
        </div>
        <!-- Duplicate the ads for seamless looping -->
        <div
          v-for="(ad, index) in firstRowAds"
          :key="`row1-dup-${index}`"
          class="ad-card"
        >
          <div
            class="bg-white rounded-lg shadow-md p-4 mx-2 min-w-[280px] h-[160px] flex flex-col"
          >
            <div class="flex items-center mb-2">
              <div
                class="w-12 h-12 bg-gray-200 rounded-full overflow-hidden mr-3"
              >
                <img
                  :src="`/placeholder.svg?height=48&width=48&text=${ad.category}`"
                  alt=""
                  class="w-full h-full object-cover"
                />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">{{ ad.title }}</h3>
                <p class="text-xs text-gray-500">{{ ad.category }}</p>
              </div>
            </div>
            <p class="text-sm text-gray-600 flex-grow">{{ ad.description }}</p>
            <div class="flex justify-between items-center mt-2">
              <span class="text-primary font-bold"
                >${{ ad.price.toFixed(2) }}</span
              >
              <button
                class="text-xs bg-primary text-white px-3 py-1 rounded-full hover:bg-primary/90 transition-colors"
              >
                Contact
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Second row of ads (scrolling in opposite direction) -->
    <div class="relative overflow-hidden">
      <div
        class="ads-row flex animate-scroll-reverse"
        :style="{
          animationDuration: `${secondRowDuration}s`,
          animationPlayState: isPaused ? 'paused' : 'running',
        }"
        @mouseenter="isPaused = true"
        @mouseleave="isPaused = false"
      >
        <div
          v-for="(ad, index) in secondRowAds"
          :key="`row2-${index}`"
          class="ad-card"
        >
          <div
            class="bg-white rounded-lg shadow-md p-4 mx-2 min-w-[280px] h-[160px] flex flex-col"
          >
            <div class="flex items-center mb-2">
              <div
                class="w-12 h-12 bg-gray-200 rounded-full overflow-hidden mr-3"
              >
                <img
                  :src="`/placeholder.svg?height=48&width=48&text=${ad.category}`"
                  alt=""
                  class="w-full h-full object-cover"
                />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">{{ ad.title }}</h3>
                <p class="text-xs text-gray-500">{{ ad.category }}</p>
              </div>
            </div>
            <p class="text-sm text-gray-600 flex-grow">{{ ad.description }}</p>
            <div class="flex justify-between items-center mt-2">
              <span class="text-primary font-bold"
                >${{ ad.price.toFixed(2) }}</span
              >
              <button
                class="text-xs bg-primary text-white px-3 py-1 rounded-full hover:bg-primary/90 transition-colors"
              >
                Contact
              </button>
            </div>
          </div>
        </div>
        <!-- Duplicate the ads for seamless looping -->
        <div
          v-for="(ad, index) in secondRowAds"
          :key="`row2-dup-${index}`"
          class="ad-card"
        >
          <div
            class="bg-white rounded-lg shadow-md p-4 mx-2 min-w-[280px] h-[160px] flex flex-col"
          >
            <div class="flex items-center mb-2">
              <div
                class="w-12 h-12 bg-gray-200 rounded-full overflow-hidden mr-3"
              >
                <img
                  :src="`/placeholder.svg?height=48&width=48&text=${ad.category}`"
                  alt=""
                  class="w-full h-full object-cover"
                />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">{{ ad.title }}</h3>
                <p class="text-xs text-gray-500">{{ ad.category }}</p>
              </div>
            </div>
            <p class="text-sm text-gray-600 flex-grow">{{ ad.description }}</p>
            <div class="flex justify-between items-center mt-2">
              <span class="text-primary font-bold"
                >${{ ad.price.toFixed(2) }}</span
              >
              <button
                class="text-xs bg-primary text-white px-3 py-1 rounded-full hover:bg-primary/90 transition-colors"
              >
                Contact
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Controls -->
    <div class="flex justify-center mt-4">
      <button
        @click="togglePause"
        class="flex items-center gap-2 px-4 py-2 bg-gray-200 rounded-full hover:bg-gray-300 transition-colors"
      >
        <span v-if="isPaused">▶ Resume</span>
        <span v-else>⏸️ Pause</span>
      </button>
    </div>
  </div>
</template>

<script setup>
// Control the animation state
const isPaused = ref(false);
const firstRowDuration = ref(40); // seconds for first row to complete one cycle
const secondRowDuration = ref(35); // seconds for second row to complete one cycle

// Toggle pause/play
const togglePause = () => {
  isPaused.value = !isPaused.value;
};

// Sample data for the first row
const firstRowAds = ref([
  {
    title: "2019 Honda Civic",
    category: "Vehicles",
    description:
      "Excellent condition, low mileage, one owner, all service records available.",
    price: 15999.99,
  },
  {
    title: "iPhone 13 Pro",
    category: "Electronics",
    description:
      "Like new, 256GB, Pacific Blue, includes original box and accessories.",
    price: 799.99,
  },
  {
    title: "Modern Apartment",
    category: "Real Estate",
    description:
      "2BR/2BA downtown apartment, newly renovated, all utilities included.",
    price: 1850.0,
  },
  {
    title: "Graphic Designer",
    category: "Jobs",
    description:
      "Seeking experienced graphic designer for full-time position, remote work available.",
    price: 65000.0,
  },
  {
    title: "Vintage Guitar",
    category: "Music",
    description:
      "1970s Fender Stratocaster, excellent condition, original hardware.",
    price: 2499.99,
  },
  {
    title: "Mountain Bike",
    category: "Sports",
    description:
      'Trek Fuel EX 8, carbon frame, 29" wheels, hydraulic disc brakes.',
    price: 1299.99,
  },
]);

// Sample data for the second row
const secondRowAds = ref([
  {
    title: "Antique Desk",
    category: "Furniture",
    description:
      "Solid oak writing desk from the 1920s, excellent condition, original hardware.",
    price: 850.0,
  },
  {
    title: "Web Developer",
    category: "Jobs",
    description:
      "Full-stack developer needed, React/Node.js experience required, competitive salary.",
    price: 95000.0,
  },
  {
    title: "Labrador Puppies",
    category: "Pets",
    description:
      "AKC registered yellow lab puppies, 8 weeks old, vaccinated and dewormed.",
    price: 1200.0,
  },
  {
    title: "Luxury Watch",
    category: "Fashion",
    description:
      "Omega Seamaster, automatic movement, stainless steel, box and papers included.",
    price: 3999.99,
  },
  {
    title: "Beachfront Condo",
    category: "Real Estate",
    description:
      "3BR/2BA oceanfront property, private balcony, community pool and gym.",
    price: 499000.0,
  },
  {
    title: "Professional Camera",
    category: "Electronics",
    description:
      "Sony Alpha a7 III, 24.2MP, 4K video, includes 3 lenses and carrying case.",
    price: 2199.99,
  },
]);
</script>

<style scoped>
.ads-row {
  width: fit-content;
}

.ad-card {
  flex-shrink: 0;
}

@keyframes scroll {
  0% {
    transform: translateX(0);
  }
  100% {
    transform: translateX(-50%);
  }
}

@keyframes scroll-reverse {
  0% {
    transform: translateX(-50%);
  }
  100% {
    transform: translateX(0);
  }
}

.animate-scroll {
  animation: scroll linear infinite;
}

.animate-scroll-reverse {
  animation: scroll-reverse linear infinite;
}
</style>
