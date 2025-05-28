<template>
  <div v-if="division" class="bg-white rounded-lg shadow-sm p-4 mt-3">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center">
        <div class="bg-blue-100 text-blue-600 rounded-full p-1 mr-2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
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
        <h2 class="text-lg font-bold">{{ $t("select_your_subject") }}</h2>
      </div>
      <div class="flex items-center text-sm text-gray-500">
        <span
          class="bg-gray-200 text-gray-800 rounded-full w-5 h-5 flex items-center justify-center mr-1"
          >3</span
        >
        <span>{{ $t("step_3_of_4") }}</span>
      </div>
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
        @click="loadSubjects"
        class="mt-2 text-sm text-blue-600 hover:underline"
      >
        {{ $t("try_again") }}
      </button>
    </div>

    <!-- Empty state -->
    <div v-else-if="filteredSubjects.length === 0" class="text-center py-8">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="h-10 w-10 mx-auto text-gray-300 mb-2"
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
      <p class="text-sm text-gray-500">{{ $t("no_subjects_found") }}</p>
    </div>

    <!-- Subject grid -->
    <div
      v-else
      class="grid grid-cols-3 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2"
    >
      <div
        v-for="subject in filteredSubjects"
        :key="subject.id"
        @click="$emit('select-subject', subject.id)"
        class="border rounded-lg cursor-pointer transition-all hover:shadow-sm overflow-hidden"
        :class="{
          'border-blue-500 ring-2 ring-blue-200':
            selectedSubject === subject.id,
        }"
      >
        <!-- Responsive layout for subject cards -->
        <div class="flex flex-col sm:flex-row items-center p-2 sm:p-3">
          <!-- Icon centered for mobile (stacked layout), left-aligned for larger screens -->
          <div
            class="p-1.5 rounded-lg mb-1 sm:mb-0 sm:mr-2"
            :class="subject.bgColor"
          >
            <UIcon
              v-if="subject.icon"
              :name="String(subject.icon)"
              class="w-5 h-5"
            />

            <svg
              v-else
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              :class="subject.iconColor"
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
          <div class="text-center sm:text-left">
            <h3 class="font-medium text-sm sm:text-sm">{{ subject.name }}</h3>
            <p class="text-sm text-gray-500 hidden sm:block">
              {{ subject.description }}
            </p>
          </div>
        </div>
        <div
          v-if="selectedSubject === subject.id"
          class="bg-blue-50 py-1 px-2 text-sm text-blue-600 border-t border-blue-200 flex items-center justify-center"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-3 w-3 sm:mr-1"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M5 13l4 4L19 7"
            />
          </svg>
          <span class="hidden sm:inline">{{ $t("selected") }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from "vue";
import { fetchSubjectsForDivision } from "~/services/elearningApi";

const props = defineProps({
  batch: {
    type: String,
    default: null,
  },
  division: {
    type: String,
    default: null,
  },
  selectedSubject: {
    type: String,
    default: null,
  },
});

defineEmits(["select-subject"]);

// Get runtime config for API base URL
const config = useRuntimeConfig();

// State variables
const apiSubjects = ref([]);
const loading = ref(false);
const error = ref(null);

// Function to load subjects from API
async function loadSubjects() {
  if (!props.division) return;

  try {
    loading.value = true;
    error.value = null;
    apiSubjects.value = await fetchSubjectsForDivision(
      props.division,
      config.public.baseURL
    );
    console.log("Loaded subjects:", apiSubjects.value);
  } catch (err) {
    console.error(
      `Error loading subjects for division ${props.division}:`,
      err
    );
    error.value = "Failed to load subjects. Please try again.";
    apiSubjects.value = [];
  } finally {
    loading.value = false;
  }
}

// Watch for division changes
watch(
  () => props.division,
  (newDivision) => {
    if (newDivision) {
      loadSubjects();
    }
  }
);

// Initial load if division is already available
onMounted(() => {
  if (props.division) {
    loadSubjects();
  }
});

// No static subjects - we'll use the API data only

// Color map for subject backgrounds and icons
const colorOptions = [
  { bg: "bg-blue-100", text: "text-blue-600" },
  { bg: "bg-green-100", text: "text-green-600" },
  { bg: "bg-purple-100", text: "text-purple-600" },
  { bg: "bg-cyan-100", text: "text-cyan-600" },
  { bg: "bg-amber-100", text: "text-amber-600" },
  { bg: "bg-rose-100", text: "text-rose-600" },
  { bg: "bg-emerald-100", text: "text-emerald-600" },
  { bg: "bg-violet-100", text: "text-violet-600" },
  { bg: "bg-teal-100", text: "text-teal-600" },
  { bg: "bg-indigo-100", text: "text-indigo-600" },
  { bg: "bg-orange-100", text: "text-orange-600" },
  { bg: "bg-pink-100", text: "text-pink-600" },
];

// Filter subjects based on selected batch and division
const filteredSubjects = computed(() => {
  if (!props.batch || !props.division) return [];

  // If we have API subjects, use those
  if (apiSubjects.value.length > 0) {
    return apiSubjects.value.map((subject, index) => {
      // Assign a color from the options, cycling through the available colors
      const colorIndex = index % colorOptions.length;
      const colorChoice = subject.color
        ? { bg: `bg-[${subject.color}]`, text: "text-white" }
        : colorOptions[colorIndex];

      return {
        id: subject.code,
        name: subject.name,
        description: subject.description || `${props.batch} level`,
        division: props.division,
        batch: props.batch,
        icon: subject.icon || null,
        bgColor: colorChoice.bg,
        iconColor: colorChoice.text,
      };
    });
  }

  // Return empty array instead of using static data
  return [];
});
</script>
