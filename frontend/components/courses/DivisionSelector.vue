<template>
  <div
    v-if="batch"
    class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mt-3"
  >
    <div class="flex items-center justify-between mb-3">
      <h2 class="text-lg font-semibold text-gray-800">
        {{ $t("select_your_division") }}
      </h2>
      <span class="bg-blue-100 text-blue-700 text-xs px-2 py-1 rounded-full">{{
        $t("step_2_of_4")
      }}</span>
    </div>

    <!-- Loading state -->
    <div v-if="loading" class="flex justify-center items-center py-8">
      <div
        class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"
      ></div>
    </div>
    <!-- Error state -->
    <div
      v-else-if="error"
      class="bg-red-50 border border-red-200 rounded-md p-4 text-center"
    >
      <p class="text-sm text-red-600">{{ error }}</p>
      <button
        @click="loadDivisions"
        class="mt-2 text-xs text-blue-600 hover:underline"
      >
        {{ $t("try_again") }}
      </button>
    </div>

    <!-- Division grid -->
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
      <div
        v-for="division in divisions"
        :key="division.id"
        @click="$emit('select-division', division.id)"
        class="p-3 border rounded-lg cursor-pointer transition-all hover:shadow-md hover:border-blue-300"
        :class="{
          'border-blue-500 bg-blue-50 shadow-sm':
            selectedDivision === division.id,
          'border-gray-200': selectedDivision !== division.id,
        }"
      >
        <div class="flex flex-col items-center text-center">
          <div class="p-2 mb-1 rounded-full" :class="division.bgColor">
            <UIcon
              v-if="division.icon"
              :name="String(division.icon)"
              :class="division.iconColor"
            />
          </div>
          <h3 class="font-medium text-sm">{{ division.name }}</h3>
          <p class="text-xs text-gray-600 mt-0.5 line-clamp-1">
            {{ division.description }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch, onMounted } from "vue";
import { fetchDivisionsForBatch } from "~/services/elearningApi";

const props = defineProps({
  batch: {
    type: String,
    default: null,
  },
  selectedDivision: {
    type: String,
    default: null,
  },
});

defineEmits(["select-division"]);

// Get runtime config for API base URL
const config = useRuntimeConfig();

// Default icons
const ScienceIcon = {
  template: `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
    </svg>
  `,
};

const HumanitiesIcon = {
  template: `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
    </svg>
  `,
};

const CommerceIcon = {
  template: `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  `,
};

// Default icon map
const iconComponents = {
  science: ScienceIcon,
  humanities: HumanitiesIcon,
  commerce: CommerceIcon,
};

// Default colors
const colorMap = {
  science: { bg: "bg-green-100", text: "text-green-600" },
  humanities: { bg: "bg-blue-100", text: "text-blue-600" },
  commerce: { bg: "bg-amber-100", text: "text-amber-600" },
};

// State variables
const apiDivisions = ref([]);
const loading = ref(false);
const error = ref(null);

// Computed divisions with styling
const divisions = computed(() => {
  // If we have API divisions, use them
  if (apiDivisions.value.length > 0) {
    return apiDivisions.value.map((div) => {
      const defaultColor = colorMap[div.code.toLowerCase()] || {
        bg: "bg-gray-100",
        text: "text-gray-600",
      };

      return {
        id: div.code,
        name: div.name,
        description: div.description || `${div.name} division courses`,
        icon: div.icon,

        bgColor: defaultColor.bg,
        iconColor: defaultColor.text,
      };
    });
  }

  // Return empty array instead of fallback static data
  return [];
});

// Function to load divisions from API
async function loadDivisions() {
  if (!props.batch) return;

  try {
    loading.value = true;
    error.value = null;
    apiDivisions.value = await fetchDivisionsForBatch(
      props.batch,
      config.public.baseURL
    );
  } catch (err) {
    console.error(`Error loading divisions for batch ${props.batch}:`, err);
    error.value = "Failed to load divisions. Please try again.";
    apiDivisions.value = [];
  } finally {
    loading.value = false;
  }
}

// Watch for batch changes
watch(
  () => props.batch,
  (newBatch) => {
    if (newBatch) {
      loadDivisions();
    }
  }
);

// Initial load if batch is already available
onMounted(() => {
  if (props.batch) {
    loadDivisions();
  }
});
</script>
