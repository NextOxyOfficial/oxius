<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="text-center mb-10">
      <h1 class="text-3xl font-bold text-gray-900">Online Course Portal</h1>
      <p class="mt-3 max-w-2xl mx-auto text-xl text-gray-500 sm:mt-4">
        Learn at your own pace with our high-quality video lessons
      </p>
    </div>

    <div class="space-y-6">
      <!-- Progress tracker -->
      <div class="bg-white shadow-sm rounded-lg p-4 mb-8">
        <div class="flex flex-wrap items-center justify-center gap-2">
          <div class="flex items-center">
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              selectedBatch ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-500'
            ]">
              1
            </div>
            <span class="ml-2 text-sm font-medium text-gray-900">Batch</span>
          </div>
          
          <div class="h-1 w-8 bg-gray-200">
            <div class="h-full bg-blue-500" :style="{width: selectedBatch ? '100%' : '0%'}"></div>
          </div>
          
          <div class="flex items-center">
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              selectedDivision ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-500'
            ]">
              2
            </div>
            <span class="ml-2 text-sm font-medium text-gray-900">Division</span>
          </div>
          
          <div class="h-1 w-8 bg-gray-200">
            <div class="h-full bg-blue-500" :style="{width: selectedDivision ? '100%' : '0%'}"></div>
          </div>
          
          <div class="flex items-center">
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              selectedSubject ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-500'
            ]">
              3
            </div>
            <span class="ml-2 text-sm font-medium text-gray-900">Subject</span>
          </div>
          
          <div class="h-1 w-8 bg-gray-200">
            <div class="h-full bg-blue-500" :style="{width: selectedSubject ? '100%' : '0%'}"></div>
          </div>
          
          <div class="flex items-center">
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              selectedSubject ? 'bg-blue-500 text-white' : 'bg-gray-200 text-gray-500'
            ]">
              4
            </div>
            <span class="ml-2 text-sm font-medium text-gray-900">Videos</span>
          </div>
        </div>
      </div>
      
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
      
      <VideoLessons 
        :subject="selectedSubject" 
      />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import BatchSelector from '~/components/courses/BatchSelector.vue';
import DivisionSelector from '~/components/courses/DivisionSelector.vue';
import SubjectSelector from '~/components/courses/SubjectSelector.vue';
import VideoLessons from '~/components/courses/VideoLessons.vue';

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
