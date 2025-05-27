<template>
  <div v-if="batch" class="bg-white rounded-lg shadow-md p-6 mt-4">
    <h2 class="text-xl font-bold mb-4">Select Your Division</h2>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div 
        v-for="division in divisions" 
        :key="division.id"
        @click="$emit('select-division', division.id)" 
        class="p-4 border rounded-lg cursor-pointer transition-all hover:bg-blue-50"
        :class="{ 'border-blue-500 bg-blue-50': selectedDivision === division.id }"
      >
        <div class="flex items-center space-x-3">
          <div class="p-2" :class="division.bgColor">
            <component :is="division.icon" class="h-6 w-6" :class="division.iconColor" />
          </div>
          <div>
            <h3 class="font-medium">{{ division.name }}</h3>
            <p class="text-sm text-gray-600">{{ division.description }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  batch: {
    type: String,
    default: null
  },
  selectedDivision: {
    type: String,
    default: null
  }
});

defineEmits(['select-division']);

const ScienceIcon = {
  template: `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
    </svg>
  `
};

const HumanitiesIcon = {
  template: `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
    </svg>
  `
};

const CommerceIcon = {
  template: `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  `
};

const divisions = computed(() => [
  {
    id: 'science',
    name: 'Science',
    description: 'Physics, Chemistry, Biology, etc.',
    icon: ScienceIcon,
    bgColor: 'bg-green-100',
    iconColor: 'text-green-600'
  },
  {
    id: 'humanities',
    name: 'Humanities',
    description: 'History, Geography, Literature, etc.',
    icon: HumanitiesIcon,
    bgColor: 'bg-blue-100',
    iconColor: 'text-blue-600'
  },
  {
    id: 'commerce',
    name: 'Commerce',
    description: 'Accounting, Business Studies, etc.',
    icon: CommerceIcon,
    bgColor: 'bg-amber-100',
    iconColor: 'text-amber-600'
  }
]);
</script>
