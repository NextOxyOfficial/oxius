<template>
  <UContainer>
    <div class="flex flex-col gap-4 py-12">
      <h1 class="text-center text-2xl font-semibold my-8 text-primary-800 relative">
        <span class="relative z-10">Frequently Asked Questions</span>
        <span
          class="absolute -bottom-2 left-1/2 transform -translate-x-1/2 h-2 bg-primary-300 w-40 rounded-full opacity-70"
        ></span>
      </h1>

      <div class="max-w-3xl mx-auto w-full">
        <!-- Loading state -->
        <div v-if="isLoading" class="flex justify-center py-12">
          <div class="loading-ripple">
            <div></div>
            <div></div>
          </div>
        </div>

        <!-- Custom accordion -->
        <div v-else class="space-y-4">
          <div
            v-for="(item, index) in items"
            :key="index"
            class="custom-accordion-item overflow-hidden rounded-lg border border-gray-200 shadow-sm"
          >
            <div
              class="accordion-header flex items-center justify-between w-full px-6 py-4 cursor-pointer transition-all duration-300"
              :class="[
                activeIndex === index
                  ? 'bg-gradient-to-r from-primary-50 to-primary-100'
                  : 'bg-white hover:bg-gray-50',
              ]"
              @click="toggleAccordion(index)"
            >
              <h3 class="text-lg font-medium" v-html="item.label"></h3>

              <div
                class="accordion-icon transition-transform duration-500 ease-in-out"
                :class="{ 'transform rotate-180': activeIndex === index }"
              >
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
                  :class="[
                    activeIndex === index
                      ? 'text-primary-700'
                      : 'text-gray-500',
                  ]"
                >
                  <polyline points="6 9 12 15 18 9"></polyline>
                </svg>
              </div>
            </div>

            <div
              class="accordion-content bg-white border-t border-gray-100 transition-all duration-500 ease-in-out"
              :class="{
                'max-h-0 opacity-0 p-0': activeIndex !== index,
                'max-h-[500px] opacity-100 p-6': activeIndex === index,
              }"
            >
              <div class="prose prose-primary" v-html="item.content"></div>

              <!-- Decorative elements -->
              <div v-if="activeIndex === index" class="decorative-elements">
                <div class="decorative-circle"></div>
                <div class="decorative-line"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Empty state -->
        <div
          v-if="!isLoading && items.length === 0"
          class="text-center py-12 text-gray-500"
        >
          No FAQ items available
        </div>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const items = ref([]);
const isLoading = ref(true);
const activeIndex = ref(null);
const { get } = useApi();

function toggleAccordion(index) {
  // If clicking the active accordion item, close it
  if (activeIndex.value === index) {
    activeIndex.value = null;
  } else {
    // Open the clicked accordion item
    activeIndex.value = index;
  }
}

async function getFaq() {
  try {
    isLoading.value = true;
    const response = await get("/faq/");

    // Transform the data if needed
    items.value = response.data.map((item) => ({
      label: item.label || item.question || item.title || "",
      content: item.content || item.answer || item.description || "",
    }));
  } catch (error) {
    console.error("Failed to fetch FAQ items:", error);
    items.value = [];
  } finally {
    isLoading.value = false;
  }
}

onMounted(async () => {
  await getFaq();
});
</script>

<style scoped>
.custom-accordion-item {
  transition: all 0.3s ease;
}

.custom-accordion-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.accordion-content {
  overflow: hidden;
}

/* Ripple loading animation */
.loading-ripple {
  display: inline-block;
  position: relative;
  width: 80px;
  height: 80px;
}

.loading-ripple div {
  position: absolute;
  border: 4px solid var(--color-primary-500, #3b82f6);
  opacity: 1;
  border-radius: 50%;
  animation: loading-ripple 1s cubic-bezier(0, 0.2, 0.8, 1) infinite;
}

.loading-ripple div:nth-child(2) {
  animation-delay: -0.5s;
}

@keyframes loading-ripple {
  0% {
    top: 36px;
    left: 36px;
    width: 0;
    height: 0;
    opacity: 0;
  }
  4.9% {
    top: 36px;
    left: 36px;
    width: 0;
    height: 0;
    opacity: 0;
  }
  5% {
    top: 36px;
    left: 36px;
    width: 0;
    height: 0;
    opacity: 1;
  }
  100% {
    top: 0px;
    left: 0px;
    width: 72px;
    height: 72px;
    opacity: 0;
  }
}

/* Decorative elements */
.decorative-elements {
  position: relative;
  opacity: 0;
  animation: fade-in 0.8s ease forwards;
  animation-delay: 0.3s;
}

.decorative-circle {
  position: absolute;
  bottom: -50px;
  right: -20px;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: 2px dashed var(--color-primary-200, #bfdbfe);
  opacity: 0.5;
}

.decorative-line {
  position: absolute;
  top: -40px;
  left: 20px;
  width: 60px;
  height: 3px;
  background: linear-gradient(
    90deg,
    transparent,
    var(--color-primary-300, #93c5fd),
    transparent
  );
  transform: rotate(45deg);
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
