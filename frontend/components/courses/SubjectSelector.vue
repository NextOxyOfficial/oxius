<template>
  <div v-if="division" class="bg-white rounded-lg shadow-md p-6 mt-4">
    <h2 class="text-xl font-bold mb-4">Select Your Subject</h2>
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
      <div 
        v-for="subject in filteredSubjects" 
        :key="subject.id"
        @click="$emit('select-subject', subject.id)" 
        class="p-4 border rounded-lg cursor-pointer transition-all hover:bg-blue-50"
        :class="{ 'border-blue-500 bg-blue-50': selectedSubject === subject.id }"
      >
        <div class="flex items-center space-x-3">
          <div class="p-2 rounded-lg" :class="subject.bgColor">
            <img v-if="subject.icon" :src="subject.icon" class="w-6 h-6" alt="Subject Icon" />
            <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" :class="subject.iconColor" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <div>
            <h3 class="font-medium">{{ subject.name }}</h3>
            <p class="text-sm text-gray-600">{{ subject.description }}</p>
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
  division: {
    type: String,
    default: null
  },
  selectedSubject: {
    type: String,
    default: null
  }
});

defineEmits(['select-subject']);

// This is a sample list of subjects. In a real application, you would fetch this from an API
const subjects = [
  // Science subjects for SSC
  {
    id: 'physics-ssc',
    name: 'Physics',
    description: 'Class 9-10',
    division: 'science',
    batch: 'SSC',
    bgColor: 'bg-cyan-100',
    iconColor: 'text-cyan-600'
  },
  {
    id: 'chemistry-ssc',
    name: 'Chemistry',
    description: 'Class 9-10',
    division: 'science',
    batch: 'SSC',
    bgColor: 'bg-purple-100',
    iconColor: 'text-purple-600'
  },
  {
    id: 'biology-ssc',
    name: 'Biology',
    description: 'Class 9-10',
    division: 'science',
    batch: 'SSC',
    bgColor: 'bg-green-100',
    iconColor: 'text-green-600'
  },
  {
    id: 'math-ssc',
    name: 'Mathematics',
    description: 'Class 9-10',
    division: 'science',
    batch: 'SSC',
    bgColor: 'bg-blue-100',
    iconColor: 'text-blue-600'
  },
  
  // Science subjects for HSC
  {
    id: 'physics-hsc',
    name: 'Physics',
    description: 'Class 11-12',
    division: 'science',
    batch: 'HSC',
    bgColor: 'bg-cyan-100',
    iconColor: 'text-cyan-600'
  },
  {
    id: 'chemistry-hsc',
    name: 'Chemistry',
    description: 'Class 11-12',
    division: 'science',
    batch: 'HSC',
    bgColor: 'bg-purple-100',
    iconColor: 'text-purple-600'
  },
  {
    id: 'biology-hsc',
    name: 'Biology',
    description: 'Class 11-12',
    division: 'science',
    batch: 'HSC',
    bgColor: 'bg-green-100',
    iconColor: 'text-green-600'
  },
  {
    id: 'math-hsc',
    name: 'Mathematics',
    description: 'Class 11-12',
    division: 'science',
    batch: 'HSC',
    bgColor: 'bg-blue-100',
    iconColor: 'text-blue-600'
  },
  
  // Humanities subjects for SSC
  {
    id: 'history-ssc',
    name: 'History',
    description: 'Class 9-10',
    division: 'humanities',
    batch: 'SSC',
    bgColor: 'bg-amber-100',
    iconColor: 'text-amber-600'
  },
  {
    id: 'geography-ssc',
    name: 'Geography',
    description: 'Class 9-10',
    division: 'humanities',
    batch: 'SSC',
    bgColor: 'bg-emerald-100',
    iconColor: 'text-emerald-600'
  },
  {
    id: 'civics-ssc',
    name: 'Civics',
    description: 'Class 9-10',
    division: 'humanities',
    batch: 'SSC',
    bgColor: 'bg-rose-100',
    iconColor: 'text-rose-600'
  },
  
  // Humanities subjects for HSC
  {
    id: 'history-hsc',
    name: 'History',
    description: 'Class 11-12',
    division: 'humanities',
    batch: 'HSC',
    bgColor: 'bg-amber-100',
    iconColor: 'text-amber-600'
  },
  {
    id: 'geography-hsc',
    name: 'Geography',
    description: 'Class 11-12',
    division: 'humanities',
    batch: 'HSC',
    bgColor: 'bg-emerald-100',
    iconColor: 'text-emerald-600'
  },
  {
    id: 'logic-hsc',
    name: 'Logic',
    description: 'Class 11-12',
    division: 'humanities',
    batch: 'HSC',
    bgColor: 'bg-violet-100',
    iconColor: 'text-violet-600'
  },
  {
    id: 'sociology-hsc',
    name: 'Sociology',
    description: 'Class 11-12',
    division: 'humanities',
    batch: 'HSC',
    bgColor: 'bg-rose-100',
    iconColor: 'text-rose-600'
  },
  
  // Commerce subjects for SSC
  {
    id: 'business-studies-ssc',
    name: 'Business Studies',
    description: 'Class 9-10',
    division: 'commerce',
    batch: 'SSC',
    bgColor: 'bg-indigo-100',
    iconColor: 'text-indigo-600'
  },
  {
    id: 'accounting-ssc',
    name: 'Accounting',
    description: 'Class 9-10',
    division: 'commerce',
    batch: 'SSC',
    bgColor: 'bg-blue-100',
    iconColor: 'text-blue-600'
  },
  
  // Commerce subjects for HSC
  {
    id: 'business-studies-hsc',
    name: 'Business Studies',
    description: 'Class 11-12',
    division: 'commerce',
    batch: 'HSC',
    bgColor: 'bg-indigo-100',
    iconColor: 'text-indigo-600'
  },
  {
    id: 'accounting-hsc',
    name: 'Accounting',
    description: 'Class 11-12',
    division: 'commerce',
    batch: 'HSC',
    bgColor: 'bg-blue-100',
    iconColor: 'text-blue-600'
  },
  {
    id: 'finance-hsc',
    name: 'Finance',
    description: 'Class 11-12',
    division: 'commerce',
    batch: 'HSC',
    bgColor: 'bg-teal-100',
    iconColor: 'text-teal-600'
  },
  {
    id: 'economics-hsc',
    name: 'Economics',
    description: 'Class 11-12',
    division: 'commerce',
    batch: 'HSC',
    bgColor: 'bg-pink-100',
    iconColor: 'text-pink-600'
  }
];

// Filter subjects based on selected batch and division
const filteredSubjects = computed(() => {
  if (!props.batch || !props.division) return [];
  return subjects.filter(subject => 
    subject.batch === props.batch && 
    subject.division === props.division
  );
});
</script>
