<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="flex items-center justify-between mb-3">
      <h2 class="text-lg font-medium text-gray-800">
        {{ $t("select_your_batch") }}
      </h2>
      <span class="bg-blue-100 text-blue-700 text-sm px-2 py-1 rounded-full">{{
        $t("step_1_of_4")
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
        @click="loadBatches"
        class="mt-2 text-sm text-blue-600 hover:underline"
      >
        {{ $t("try_again") }}
      </button>    </div>

    <!-- Batch grid -->
    <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 justify-items-center">
      <div
        v-for="batch in batches"
        :key="batch.id"
        @click="$emit('select-batch', batch.code)"
        class="p-3 border rounded-lg cursor-pointer transition-all hover:shadow-sm hover:border-blue-300 w-full max-w-xs"
        :class="{
          'border-blue-500 bg-blue-50 shadow-sm': selectedBatch === batch.code,
          'border-gray-200': selectedBatch !== batch.code,
        }"
      >
        <div class="flex flex-col items-center space-y-2 text-center">
          <div class="p-1.5 rounded-lg" :class="getBatchColor(batch.name)">
            <UIcon v-if="batch.icon" :name="String(batch.icon)" />

            <svg
              v-else
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              :class="getBatchTextColor(batch.code)"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
              />
            </svg>
          </div>
          <div>
            <h3 class="font-medium text-sm">{{ batch.name }}</h3>
            <p class="text-sm text-gray-600">{{ batch.description }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { fetchBatches } from "~/services/elearningApi";

const props = defineProps({
  selectedBatch: {
    type: String,
    default: null,
  },
});

defineEmits(["select-batch"]);

// Get runtime config for API base URL
const config = useRuntimeConfig();

// State variables
const batches = ref([]);
const loading = ref(true);
const error = ref(null); // Function to load batches from API
async function loadBatches() {
  try {
    loading.value = true;
    error.value = null;
    const fetchedBatches = await fetchBatches(config.public.baseURL);

    // Sort batches by class number (extract number from name and sort)
    batches.value = fetchedBatches.sort((a, b) => {
      // Extract numbers from batch names (e.g., "Class 6" -> 6, "SSC" -> 999 for end)
      const getClassNumber = (name) => {
        // Look for patterns like "Class 6", "Class 7", etc.
        const classMatch = name.match(/class\s+(\d+)/i);
        if (classMatch) {
          return parseInt(classMatch[1]);
        }
        
        // Handle special cases - put them at the end
        if (name.toLowerCase().includes('ssc')) return 998;
        if (name.toLowerCase().includes('hsc')) return 999;
        
        // For any other format, try to extract first number
        const numberMatch = name.match(/(\d+)/);
        if (numberMatch) {
          return parseInt(numberMatch[1]);
        }
        
        // If no number found, put at the very end
        return 1000;
      };
      
      const aNumber = getClassNumber(a.name);
      const bNumber = getClassNumber(b.name);
      
      return aNumber - bNumber;
    });

    // If API call is successful but returned no batches, show the error
    if (batches.value.length === 0) {
      error.value = "No batches found. Please contact administrator.";
    }
  } catch (err) {
    console.error("Error loading batches:", err);
    error.value = "Failed to load batches. Please try again.";
  } finally {
    loading.value = false;
  }
}

// Helper functions for styling
function getBatchColor(code) {
  switch (code) {
    case "SSC":
      return "bg-blue-100";
    case "HSC":
      return "bg-purple-100";
    default:
      return "bg-gray-100";
  }
}

function getBatchTextColor(code) {
  switch (code) {
    case "SSC":
      return "text-blue-600";
    case "HSC":
      return "text-purple-600";
    default:
      return "text-gray-600";
  }
}

// Load batches when component mounts
onMounted(() => {
  loadBatches();
});
</script>
