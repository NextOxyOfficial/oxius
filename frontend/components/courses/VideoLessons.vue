<template>  <div v-if="subject" class="bg-white rounded-lg shadow-md p-6 mt-4">
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-4">
      <h2 class="text-xl font-bold">Video Lessons</h2>
      <div class="flex flex-col md:flex-row gap-3 mt-2 md:mt-0">
        <!-- Search by keyword input -->
        <div class="relative">          <input
            v-model="searchKeyword"
            type="text"
            placeholder="Search by keyword... / কীওয়ার্ড দিয়ে অনুসন্ধান করুন..."
            class="border rounded-lg pl-9 pr-3 py-2 text-sm w-full focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <div class="absolute left-3 top-2.5 text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
          <!-- Filter by lesson dropdown -->
        <div class="flex items-center">
          <label class="text-sm text-gray-600 mr-2 whitespace-nowrap">
            {{ isBanglaSearch ? 'পাঠ অনুসারে ফিল্টার:' : 'Filter by Lesson:' }}
          </label>
          <select 
            v-model="selectedLesson" 
            class="border rounded-lg p-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">{{ isBanglaSearch ? 'সমস্ত পাঠ' : 'All Lessons' }}</option>
            <option v-for="lesson in lessons" :key="lesson" :value="lesson">
              {{ lesson }}
            </option>
          </select>
        </div>
      </div>
    </div>    <!-- Search results summary -->
    <div v-if="searchKeyword.trim() || selectedLesson !== 'all'" class="mb-4 bg-gray-50 p-3 rounded-lg border border-gray-200">
      <div class="flex flex-wrap items-center gap-2">
        <span class="text-sm font-medium">{{ isBanglaSearch ? 'অনুসন্ধানের ফলাফল:' : 'Search results:' }}</span>
        <span class="text-sm">
          {{ filteredVideos.length }} 
          {{ isBanglaSearch 
            ? 'টি ভিডিও পাওয়া গেছে' 
            : (filteredVideos.length === 1 ? 'video' : 'videos') + ' found' }}
        </span>
        
        <div v-if="searchKeyword.trim()" class="flex items-center ml-2">
          <span class="text-sm text-gray-600 mr-1">{{ isBanglaSearch ? 'কীওয়ার্ড:' : 'for keyword:' }}</span>
          <span class="text-xs bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full">
            "{{ searchKeyword }}"
          </span>
        </div>
          <div v-if="selectedLesson !== 'all'" class="flex items-center ml-2">
          <span class="text-sm text-gray-600 mr-1">{{ isBanglaSearch ? 'পাঠ:' : 'in lesson:' }}</span>
          <span class="text-xs bg-green-100 text-green-800 px-2 py-0.5 rounded-full">
            {{ selectedLesson }}
          </span>
        </div>
          <!-- Clear filters button -->
        <button 
          v-if="searchKeyword.trim() || selectedLesson !== 'all'"
          @click="clearFilters" 
          class="ml-auto text-xs text-gray-500 hover:text-blue-600 flex items-center"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
          {{ isBanglaSearch ? 'ফিল্টার মুছুন' : 'Clear filters' }}
        </button>
      </div>
    </div>
    
    <div v-if="filteredVideos.length === 0" class="text-center py-8">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
      </svg>      <p class="mt-4 text-gray-500">
        {{ searchKeyword.trim() ? 'No videos match your search criteria' : 'No videos available for this lesson' }}
        <span v-if="isBanglaSearch" class="block mt-1">
          কোন ভিডিও আপনার অনুসন্ধান মানদণ্ড মেলে না
        </span>
      </p>
    </div>
    
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div 
        v-for="video in filteredVideos" 
        :key="video.id"
        class="overflow-hidden rounded-lg border transition-all hover:shadow-md"
      >
        <div class="aspect-w-16 aspect-h-9 bg-gray-100">
          <youtube-player :video-id="getYoutubeId(video.url)" :video="video" />
        </div>        <div class="p-4">
          <h3 class="font-medium text-gray-900" v-html="highlightText(video.title)"></h3>
          <p class="text-sm text-gray-600 mt-1">Lesson: <span v-html="highlightText(video.lesson)"></span></p>
          <p class="text-sm text-gray-600 mt-2 line-clamp-2" v-html="highlightText(video.description)"></p>
            <!-- Show match indicators when searching -->
          <div v-if="searchKeyword.trim()" class="flex flex-wrap gap-1 mt-2">
            <span v-if="hasMatch(video.title)" 
                  class="text-xs px-2 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200">
              {{ isBanglaSearch ? 'শিরোনাম মিল' : 'Title match' }}
            </span>
            <span v-if="hasMatch(video.description)" 
                  class="text-xs px-2 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200">
              {{ isBanglaSearch ? 'বিবরণে মিল' : 'Description match' }}
            </span>
            <span v-if="hasMatch(video.lesson)" 
                  class="text-xs px-2 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200">
              {{ isBanglaSearch ? 'পাঠ মিল' : 'Lesson match' }}
            </span>
          </div>
          
          <div class="flex items-center mt-3">
            <span class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded-full">
              {{ video.duration }}
            </span>
            <span class="ml-2 text-xs text-gray-500">
              {{ video.views }} views
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import YoutubePlayer from '~/components/courses/YoutubePlayer.vue';

const props = defineProps({
  subject: {
    type: String,
    default: null
  }
});

// Example video data - in a real application, this would be fetched from an API
const videos = [
  // Physics SSC
  {
    id: 'phys-ssc-1',
    subjectId: 'physics-ssc',
    title: 'Introduction to Motion',
    lesson: 'Motion and Forces',
    description: 'Learn the basic concepts of motion including displacement, velocity, and acceleration. This lesson covers the fundamental principles that form the basis of mechanics.',
    url: 'https://www.youtube.com/watch?v=ZM8ECpBuQYE',
    duration: '12:45',
    views: '1.2k'
  },
  {
    id: 'phys-ssc-2',
    subjectId: 'physics-ssc',
    title: 'Newton\'s Laws of Motion',
    lesson: 'Motion and Forces',
    description: 'Comprehensive explanation of Isaac Newton\'s three laws of motion: inertia, force and acceleration, and action-reaction. These principles explain how forces interact with objects.',
    url: 'https://www.youtube.com/watch?v=kKKM8Y-u7ds',
    duration: '15:30',
    views: '2.5k'
  },
  {
    id: 'phys-ssc-3',
    subjectId: 'physics-ssc',
    title: 'Understanding Gravity',
    lesson: 'Gravitation',
    description: 'Explore the concept of gravity as a fundamental force in the universe. Learn about gravitational fields, acceleration due to gravity, and Newton\'s law of universal gravitation.',
    url: 'https://www.youtube.com/watch?v=EwY6p-r_hyU',
    duration: '10:15',
    views: '1.8k'
  },
    // Chemistry SSC
  {
    id: 'chem-ssc-1',
    subjectId: 'chemistry-ssc',
    title: 'Atomic Structure',
    lesson: 'Atoms and Molecules',
    description: 'Explore the structure of atoms including protons, neutrons, and electrons. Learn about atomic numbers, mass numbers, and how electrons are arranged in shells.',
    url: 'https://www.youtube.com/watch?v=LhAobPugvsk',
    duration: '14:20',
    views: '3.1k'
  },
  {
    id: 'chem-ssc-2',
    subjectId: 'chemistry-ssc',
    title: 'Periodic Table',
    lesson: 'Elements',
    description: 'Understand how elements are organized in the periodic table. Learn about periods, groups, and the patterns of properties across the table including electronegativity and atomic radius.',
    url: 'https://www.youtube.com/watch?v=0RRVV4Diomg',
    duration: '18:10',
    views: '2.9k'
  },
  
  // Physics HSC
  {
    id: 'phys-hsc-1',
    subjectId: 'physics-hsc',
    title: 'Electric Fields',
    lesson: 'Electricity',
    description: 'Introduction to electric fields, Coulomb\'s law, and electric potential. This lesson covers how charged particles interact and the principles of electrostatics.',
    url: 'https://www.youtube.com/watch?v=mdulzEfQXDE',
    duration: '20:05',
    views: '4.2k'
  },
  {
    id: 'phys-hsc-2',
    subjectId: 'physics-hsc',
    title: 'Electromagnetic Induction',
    lesson: 'Electricity',
    description: 'Learn about Faraday\'s law of electromagnetic induction, Lenz\'s law, and how changing magnetic fields generate electric currents. Applications in generators and transformers are discussed.',
    url: 'https://www.youtube.com/watch?v=pQp6bmJPU_0',
    duration: '22:15',
    views: '3.7k'
  },
  {
    id: 'phys-hsc-3',
    subjectId: 'physics-hsc',
    title: 'Quantum Phenomena',
    lesson: 'Modern Physics',
    description: 'Introduction to quantum physics concepts including wave-particle duality, the uncertainty principle, and quantum tunneling. This lesson bridges classical physics with modern concepts.',
    url: 'https://www.youtube.com/watch?v=7kb1VT0J3DE',
    duration: '25:30',
    views: '5.1k'
  },
  // Add more sample videos for other subjects as needed
  
  // Bengali language videos
  {
    id: 'bn-phys-ssc-1',
    subjectId: 'physics-ssc',
    title: 'গতি সম্পর্কে ভূমিকা',
    lesson: 'গতি এবং বল',
    description: 'গতির মৌলিক ধারণাগুলি শিখুন যার মধ্যে রয়েছে অবস্থান পরিবর্তন, বেগ এবং ত্বরণ। এই পাঠটি যান্ত্রিকতার ভিত্তিমূলক নীতিগুলি কভার করে।',
    url: 'https://www.youtube.com/watch?v=ZM8ECpBuQYE',
    duration: '12:45',
    views: '1.2k'
  },
  {
    id: 'bn-chem-ssc-1',
    subjectId: 'chemistry-ssc',
    title: 'পারমাণবিক গঠন',
    lesson: 'পরমাণু এবং অণু',
    description: 'পরমাণুর গঠন সম্পর্কে জানুন যার মধ্যে প্রোটন, নিউট্রন এবং ইলেকট্রন অন্তর্ভুক্ত। পারমাণবিক সংখ্যা, ভর সংখ্যা এবং কিভাবে ইলেকট্রনগুলি খোসায় সাজানো হয় সে সম্পর্কে শিখুন।',
    url: 'https://www.youtube.com/watch?v=LhAobPugvsk',
    duration: '14:20',
    views: '3.1k'
  }
];

const selectedLesson = ref('all');
const searchKeyword = ref('');

// Function to clear all filters
function clearFilters() {
  selectedLesson.value = 'all';
  searchKeyword.value = '';
}

// Filter videos based on selected subject
const subjectVideos = computed(() => {
  if (!props.subject) return [];
  return videos.filter(video => video.subjectId === props.subject);
});

// Get all lessons for the selected subject
const lessons = computed(() => {
  const uniqueLessons = new Set();
  subjectVideos.value.forEach(video => uniqueLessons.add(video.lesson));
  return [...uniqueLessons];
});

// Filter videos based on both selected lesson and search keyword
const filteredVideos = computed(() => {
  let result = subjectVideos.value;
  
  // Filter by lesson if not "all"
  if (selectedLesson.value !== 'all') {
    result = result.filter(video => video.lesson === selectedLesson.value);
  }
  
  // Filter by search keyword if provided with Unicode support
  if (searchKeyword.value.trim()) {
    // Normalize the search term for better Unicode handling (especially for Bangla)
    const keyword = searchKeyword.value.trim().normalize('NFC').toLowerCase();
    
    result = result.filter(video => {
      // Normalize all text fields for consistent Unicode comparison
      const normalizedTitle = (video.title || '').normalize('NFC').toLowerCase();
      const normalizedDescription = (video.description || '').normalize('NFC').toLowerCase();
      const normalizedLesson = (video.lesson || '').normalize('NFC').toLowerCase();
      
      return normalizedTitle.includes(keyword) || 
             normalizedDescription.includes(keyword) || 
             normalizedLesson.includes(keyword);
    });
  }
  
  return result;
});

// Helper function to extract YouTube video ID from URL
function getYoutubeId(url) {
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return (match && match[2].length === 11) ? match[2] : null;
}

// Function to highlight search keywords in text with Unicode support
function highlightText(text) {
  if (!searchKeyword.value.trim() || !text) return text;
  
  // Using function to handle Unicode characters properly
  const keyword = searchKeyword.value.trim();
  
  try {
    // Create a case-insensitive regex with Unicode support using 'u' flag
    const regex = new RegExp(`(${escapeRegExp(keyword)})`, 'giu');
    return text.replace(regex, '<span class="bg-yellow-100 text-yellow-800">$1</span>');
  } catch (e) {
    // Fallback for regex issues with special characters
    console.error('Regex error:', e);
    return text;
  }
}

// Helper function to check if text contains search keyword (Unicode aware)
function hasMatch(text) {
  if (!searchKeyword.value.trim() || !text) return false;
  
  // For Bangla and other Unicode scripts, we need to be careful with case conversion
  // Normalize both strings to improve matching across Unicode representations
  const keyword = searchKeyword.value.trim().normalize('NFC').toLowerCase();
  const normalizedText = text.normalize('NFC').toLowerCase();
  
  return normalizedText.includes(keyword);
}

// Helper function to escape special characters in regex (Unicode aware)
function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
}

// Helper function to check if text is Bangla
function isBanglaText(text) {
  if (!text) return false;
  // Bangla Unicode range: \u0980-\u09FF
  const banglaPattern = /[\u0980-\u09FF]/;
  return banglaPattern.test(text);
}

// Computed property to detect if search is in Bangla
const isBanglaSearch = computed(() => {
  return isBanglaText(searchKeyword.value);
});
</script>

<style scoped>
.aspect-w-16 {
  position: relative;
  padding-bottom: 56.25%; /* 16:9 Aspect Ratio */
}
.aspect-w-16 > * {
  position: absolute;
  height: 100%;
  width: 100%;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
}

/* Line clamp utility for truncating text at 2 lines */
.line-clamp-2 {
  display: -webkit-box;
  display: box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  box-orient: vertical;
  overflow: hidden;
}
</style>
