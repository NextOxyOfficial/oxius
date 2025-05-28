<template>
  <UContainer class="pt-4">
    <div
      class="bg-gradient-to-r from-blue-600 to-indigo-700 py-6 rounded-lg shadow-sm px-2 md:px-4"
    >
      <div
        class="flex flex-col md:flex-row justify-between items-start md:items-center"
      >
        <div class="text-white">
          <h1 class="text-3xl font-bold flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8 mr-2"
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
            {{ $t("elearning") }}
          </h1>
          <p class="mt-1 text-blue-100">{{ $t("interactive_education") }}</p>
          <div class="mt-3 flex items-center">
            <span
              class="bg-white bg-opacity-20 text-xs uppercase tracking-wider font-semibold py-1 px-2 rounded-md"
            >
              {{ $t("video_lessons") }}
            </span>
            <span class="mx-2 text-blue-200">•</span>
            <span class="text-sm text-blue-100">{{
              $t("learn_at_your_pace")
            }}</span>
          </div>
        </div>

        <!-- Progress Indicator Pills -->
        <div
          class="bg-white py-2 px-3 rounded-lg shadow-md mt-4 md:mt-0 flex items-center space-x-1.5"
        >
          <div class="flex items-center">
            <div
              :class="[
                'w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium',
                selectedBatch
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-400',
              ]"
            >
              1
            </div>
            <span
              class="ml-1 text-xs font-medium"
              :class="selectedBatch ? 'text-blue-600' : 'text-gray-600'"
              >{{ $t("batch") }}</span
            >
          </div>

          <svg
            class="h-3 w-3 text-gray-300"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5l7 7-7 7"
            />
          </svg>

          <div class="flex items-center">
            <div
              :class="[
                'w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium',
                selectedDivision
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-400',
              ]"
            >
              2
            </div>
            <span
              class="ml-1 text-xs font-medium"
              :class="selectedDivision ? 'text-blue-600' : 'text-gray-600'"
              >{{ $t("division") }}</span
            >
          </div>

          <svg
            class="h-3 w-3 text-gray-300"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5l7 7-7 7"
            />
          </svg>

          <div class="flex items-center">
            <div
              :class="[
                'w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium',
                selectedSubject
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-400',
              ]"
            >
              3
            </div>
            <span
              class="ml-1 text-xs font-medium"
              :class="selectedSubject ? 'text-blue-600' : 'text-gray-600'"
              >{{ $t("subject") }}</span
            >
          </div>

          <svg
            class="h-3 w-3 text-gray-300"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5l7 7-7 7"
            />
          </svg>

          <div class="flex items-center">
            <div
              :class="[
                'w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium',
                selectedSubject
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-400',
              ]"
            >
              4
            </div>
            <span
              class="ml-1 text-xs font-medium"
              :class="selectedSubject ? 'text-blue-600' : 'text-gray-600'"
              >{{ $t("videos") }}</span
            >
          </div>
        </div>
      </div>
    </div>
  </UContainer>
  <!-- Hero header section -->

  <!-- Content section -->
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    <div class="space-y-3">
      <!-- Selection Components -->
      <BatchSelector
        :selectedBatch="selectedBatch"
        @select-batch="handleBatchSelection"
      />

      <DivisionSelector
        :batch="selectedBatch"
        :selectedDivision="selectedDivision"
        @select-division="handleDivisionSelection"
      />

      <SubjectSelector
        :batch="selectedBatch"
        :division="selectedDivision"
        :selectedSubject="selectedSubject"
        @select-subject="handleSubjectSelection"
      />

      <VideoLessons :subject="selectedSubject" />

      <!-- Helpful resources section when nothing is selected -->
      <div
        v-if="!selectedBatch"
        class="bg-white rounded-lg shadow-md p-4 border-l-4 border-blue-500"
      >
        <div class="flex items-start">
          <div class="flex-shrink-0 mt-0.5">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-blue-500"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-gray-900">
              {{ $t("getting_started") }}
            </h3>
            <div class="mt-2 text-sm text-gray-600">
              <p>{{ $t("getting_started_desc") }}</p>
              <ul
                class="mt-2 space-y-1 list-disc list-inside text-xs text-gray-600"
              >
                <li>
                  {{ $t("step_1_of_4") }}: {{ $t("select_your_batch") }} ({{
                    $t("ssc")
                  }}/{{ $t("hsc") }})
                </li>
                <li>
                  {{ $t("step_2_of_4") }}: {{ $t("select_your_division") }} ({{
                    $t("science")
                  }}/{{ $t("commerce") }}/{{ $t("humanities") }})
                </li>
                <li>
                  {{ $t("step_3_of_4") }}: {{ $t("select_your_subject") }}
                </li>
                <li>{{ $t("step_4_of_4") }}: {{ $t("videos") }}</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

import { ref } from "vue";
import BatchSelector from "~/components/courses/BatchSelector.vue";
import DivisionSelector from "~/components/courses/DivisionSelector.vue";
import SubjectSelector from "~/components/courses/SubjectSelector.vue";
import VideoLessons from "~/components/courses/VideoLessons.vue";

const selectedBatch = ref(null);
const selectedDivision = ref(null);
const selectedSubject = ref(null);

function handleBatchSelection(batch) {
  selectedBatch.value = batch;
  // Reset subsequent selections
  selectedDivision.value = null;
  selectedSubject.value = null;
}

function handleDivisionSelection(division) {
  selectedDivision.value = division;
  // Reset subject selection
  selectedSubject.value = null;
}

function handleSubjectSelection(subject) {
  selectedSubject.value = subject;
}
</script>

<style scoped>
/* Add a subtle pattern background */
.bg-gradient-to-r {
  background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z' fill='%23ffffff' fill-opacity='0.05' fill-rule='evenodd'/%3E%3C/svg%3E"),
    linear-gradient(to right, var(--tw-gradient-stops));
}
</style>
