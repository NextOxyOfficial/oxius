<template>  
  <div v-if="subject" class="bg-white rounded-lg shadow-sm p-4 mt-3">
    <!-- Header with title and icon -->
    <div class="flex items-center mb-4">
      <div class="bg-gradient-to-br from-red-500 to-rose-600 text-white rounded-full p-1.5 mr-2.5 shadow-sm">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
        </svg>
      </div>
      <div>
        <h2 class="text-lg font-bold">Video Lessons</h2>
        <p class="text-xs text-gray-500 hidden sm:block">Interactive educational content for your selected subject</p>
      </div>
      
      <!-- Total videos count badge -->
      <span class="ml-auto text-xs bg-gray-50 text-gray-700 px-2.5 py-1 rounded-full border border-gray-100 shadow-sm flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1 text-gray-500" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
        </svg>
        <span>{{ subjectVideos.length }} videos</span>
      </span>
    </div>

    <!-- Modern search and filter card -->
    <div class="bg-gradient-to-r from-gray-50 to-slate-50 rounded-lg border border-gray-100 p-4 mb-5 shadow-sm">
      <!-- Top section title -->
      <div class="flex items-center mb-3 pb-2 border-b border-gray-200">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600 mr-2" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M3 3a1 1 0 011-1h12a1 1 0 011 1v3a1 1 0 01-.293.707L12 11.414V15a1 1 0 01-.293.707l-2 2A1 1 0 018 17v-5.586L3.293 6.707A1 1 0 013 6V3z" clip-rule="evenodd" />
        </svg>
        <h3 class="text-sm font-semibold text-gray-700">Filter & Search Options</h3>
      </div>
      
      <!-- Search and filter controls - redesigned layout -->
      <div class="space-y-4 md:space-y-0 md:grid md:grid-cols-12 md:gap-4">
        <!-- Lesson filter - styled select with icon -->
        <div class="md:col-span-5">
          <label class="block text-xs font-medium text-gray-700 mb-1.5 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-gray-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
              <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z" />
              <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z" clip-rule="evenodd" />
            </svg>
            {{ isBanglaSearch ? 'পাঠ অনুসারে ফিল্টার:' : 'Filter by Lesson:' }}
          </label>
          <div class="relative">
            <select 
              v-model="selectedLesson" 
              class="appearance-none block w-full bg-white border border-gray-200 rounded-md py-2 pl-3.5 pr-8 text-sm text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">{{ isBanglaSearch ? 'সমস্ত পাঠ' : 'All Lessons' }}</option>
              <option v-for="lesson in lessons" :key="lesson" :value="lesson">
                {{ lesson }}
              </option>
            </select>
            <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700">
              <svg class="h-4 w-4 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
              </svg>
            </div>
          </div>
        </div>
        
        <!-- Search input - modern design with context indicator -->
        <div class="md:col-span-7">
          <label class="block text-xs font-medium text-gray-700 mb-1.5 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-gray-500 mr-1" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd" />
            </svg>
            {{ isBanglaSearch ? 'অনুসন্ধান করুন:' : 'Search Content:' }}
            <span v-if="selectedLesson !== 'all'" class="ml-1.5 bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 rounded-md font-medium">
              {{ selectedLesson }}
            </span>
          </label>
          <div class="relative">
            <input
              v-model="searchKeyword"
              type="text"
              :placeholder="searchPlaceholder"
              class="block w-full bg-white border border-gray-200 rounded-md py-2 pl-10 pr-9 text-sm text-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <!-- Search icon positioned inside input -->
            <div class="absolute left-0 inset-y-0 flex items-center pl-3 pointer-events-none">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            
            <!-- Clear search button with animation -->
            <button 
              v-if="searchKeyword.trim()"
              @click="searchKeyword = ''" 
              class="absolute right-2 inset-y-0 flex items-center text-gray-400 hover:text-gray-600 transition-colors duration-200"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Filter actions and status -->
      <div class="mt-3 flex items-center justify-between">
        <!-- Filter status badges -->
        <div v-if="searchKeyword.trim() || selectedLesson !== 'all'" class="flex flex-wrap gap-1.5">
          <div v-if="selectedLesson !== 'all'" class="inline-flex items-center px-2 py-1 rounded-md text-xs bg-green-50 text-green-700 border border-green-100">
            <span>{{ isBanglaSearch ? 'পাঠ:' : 'Lesson:' }}</span>
            <span class="font-medium ml-1">{{ selectedLesson }}</span>
            <button @click="selectedLesson = 'all'" class="ml-1.5 text-green-500 hover:text-green-700">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>
          
          <div v-if="searchKeyword.trim()" class="inline-flex items-center px-2 py-1 rounded-md text-xs bg-blue-50 text-blue-700 border border-blue-100">
            <span>{{ isBanglaSearch ? 'কীওয়ার্ড:' : 'Keyword:' }}</span>
            <span class="font-medium ml-1">"{{ searchKeyword }}"</span>
            <button @click="searchKeyword = ''" class="ml-1.5 text-blue-500 hover:text-blue-700">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>
        </div>
        
        <!-- Results count and clear all button -->
        <div class="flex items-center gap-2">
          <div v-if="filteredVideos.length > 0" class="text-xs text-gray-500">
            <span class="font-medium text-gray-700">{{ filteredVideos.length }}</span> 
            {{ filteredVideos.length === 1 ? 'result' : 'results' }}
          </div>
          
          <button 
            v-if="searchKeyword.trim() || selectedLesson !== 'all'"
            @click="clearFilters" 
            class="text-xs bg-gray-100 hover:bg-gray-200 text-gray-600 px-2.5 py-1.5 rounded-md flex items-center transition-colors duration-200 border border-gray-200"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            {{ isBanglaSearch ? 'ফিল্টার মুছুন' : 'Clear All' }}
          </button>
        </div>
      </div>
    </div>
    
    <!-- No results message - Styled -->
    <div v-if="filteredVideos.length === 0" class="text-center py-8 px-4 bg-gray-50 rounded-lg border border-gray-100">
      <div class="bg-white w-16 h-16 mx-auto mb-3 rounded-full shadow-sm flex items-center justify-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
        </svg>
      </div>
      <h3 class="text-sm font-semibold text-gray-700">No Videos Found</h3>
      <p class="mt-2 text-xs text-gray-500 max-w-sm mx-auto">
        {{ searchKeyword.trim() ? 'No videos match your search criteria. Try different keywords or clear filters.' : 'No videos available for this lesson yet.' }}
        <span v-if="isBanglaSearch" class="block mt-1 text-gray-500">
          কোন ভিডিও আপনার অনুসন্ধান মানদণ্ড মেলে না
        </span>
      </p>
      <button 
        v-if="searchKeyword.trim() || selectedLesson !== 'all'"
        @click="clearFilters" 
        class="mt-4 inline-flex items-center px-3 py-1.5 border border-blue-300 text-xs font-medium rounded-md text-blue-700 bg-blue-50 hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="-ml-0.5 mr-1.5 h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd" />
        </svg>
        Reset Search
      </button>
    </div>
    
    <!-- Video grid - Keep the existing grid but with minor styling improvements -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
      <div 
        v-for="video in filteredVideos" 
        :key="video.id"
        class="overflow-hidden rounded-lg border transition-all hover:shadow-sm"
      >
        <!-- Video player -->
        <div class="aspect-w-16 aspect-h-9 bg-gray-100">
          <youtube-player :video-id="getYoutubeId(video.url)" :video="video" />
        </div>
        
        <!-- Video metadata -->
        <div class="p-3">
          <h3 class="font-medium text-gray-900 text-sm" v-html="highlightText(video.title)"></h3>
          <p class="text-xs text-gray-600 mt-1">Lesson: <span v-html="highlightText(video.lesson)"></span></p>
            <!-- Description with enhanced View More button -->
          <div class="relative mt-1">
            <p class="text-xs text-gray-600 line-clamp-2" v-html="highlightText(video.description)"></p>
            <button 
              @click="openDescriptionModal(video)" 
              class="text-xs text-blue-600 hover:text-blue-800 font-medium mt-1.5 flex items-center transition-all duration-200 hover:translate-x-0.5"
            >
              <span class="border-b border-blue-300 hover:border-blue-600 pb-0.5">View more</span>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 ml-0.5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>
          
          <!-- Match indicators when searching -->
          <div v-if="searchKeyword.trim()" class="flex flex-wrap gap-1 mt-1.5">
            <span v-if="hasMatch(video.title)" 
                  class="text-xs px-1.5 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200">
              {{ isBanglaSearch ? 'শিরোনাম মিল' : 'Title match' }}
            </span>
            <span v-if="hasMatch(video.description)" 
                  class="text-xs px-1.5 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200">
              {{ isBanglaSearch ? 'বিবরণে মিল' : 'Description match' }}
            </span>
            <span v-if="hasMatch(video.lesson)" 
                  class="text-xs px-1.5 py-0.5 bg-yellow-100 text-yellow-800 rounded-full border border-yellow-200">
              {{ isBanglaSearch ? 'পাঠ মিল' : 'Lesson match' }}
            </span>
          </div>
          
          <!-- Video stats -->
          <div class="flex items-center mt-2">
            <span class="text-xs bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full">
              {{ video.duration }}
            </span>
            <span class="ml-2 text-xs text-gray-500">
              {{ video.views }} views
            </span>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Description Modal with enhanced styling -->
    <Teleport to="body">
      <div v-if="showDescriptionModal" class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
          <!-- Background overlay with improved animation -->
          <div 
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity modal-backdrop" 
            aria-hidden="true" 
            @click="closeDescriptionModal"
          ></div>
          
          <!-- Modal panel with enhanced styling and animation -->
          <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full modal-content">
            <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <!-- Modal header with video title -->
              <div class="flex items-start justify-between mb-3">
                <h3 class="text-lg leading-6 font-medium text-gray-900 pr-6" id="modal-title">
                  {{ activeVideo?.title }}
                </h3>
                <!-- Close button (X) in top-right corner -->
                <button 
                  @click="closeDescriptionModal" 
                  class="text-gray-400 hover:text-gray-500 focus:outline-none"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                  </svg>
                </button>
              </div>
              
              <!-- Subject and lesson info -->
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4">
                <div>
                  <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded">
                    {{ activeVideo?.lesson }}
                  </span>
                </div>
                <div class="mt-1 sm:mt-0 text-xs text-gray-500 flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span class="mr-2">{{ activeVideo?.duration }}</span>
                  
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 mr-1 ml-1 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <span>{{ activeVideo?.views }} views</span>
                </div>
              </div>
              
              <!-- Full description with scrollable area if content is too long -->
              <div class="border-t border-gray-100 pt-3">
                <h4 class="text-sm font-medium text-gray-700 mb-1.5 flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Description:
                </h4>
                <div class="max-h-60 overflow-y-auto pr-1">
                  <p class="text-sm text-gray-600" v-html="highlightText(activeVideo?.description)"></p>
                </div>
              </div>
            </div>
            
            <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              
              <!-- Close button -->
              <button 
                @click="closeDescriptionModal" 
                type="button" 
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm transition-colors duration-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
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

// Dynamic placeholder text based on selected lesson
const searchPlaceholder = computed(() => {
  if (selectedLesson.value === 'all') {
    return isBanglaSearch.value 
      ? "সমস্ত পাঠের মধ্যে অনুসন্ধান করুন..." 
      : "Search in all lessons...";
  } else {
    return isBanglaSearch.value 
      ? `"${selectedLesson.value}" পাঠে অনুসন্ধান করুন...` 
      : `Search in "${selectedLesson.value}" lesson...`;
  }
});

// Detect if the search text is in Bangla
const isBanglaSearch = computed(() => {
  const banglaPattern = /[\u0980-\u09FF]/;
  return banglaPattern.test(searchKeyword.value);
});

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

// State for modal dialog
const showDescriptionModal = ref(false);
const activeVideo = ref(null);

// Function to open the description modal
function openDescriptionModal(video) {
  activeVideo.value = video;
  showDescriptionModal.value = true;
}

// Function to close the description modal
function closeDescriptionModal() {
  showDescriptionModal.value = false;
  setTimeout(() => {
    activeVideo.value = null;
  }, 300); // Delay clearing the video for smoother animation
}

// Helper function to extract YouTube video ID from URL
function getYoutubeId(url) {
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return (match && match[2].length === 11) ? match[2] : null;
}

// Check if search keyword is found in a text
function hasMatch(text) {
  if (!text || !searchKeyword.value.trim()) return false;
  return text.toLowerCase().includes(searchKeyword.value.trim().toLowerCase());
}

// Highlight search term in text
function highlightText(text) {
  if (!text || !searchKeyword.value.trim()) return text;
  
  const keyword = searchKeyword.value.trim();
  const regex = new RegExp(`(${keyword})`, 'gi');
  
  return text.replace(regex, '<mark class="bg-yellow-200 rounded px-0.5">$1</mark>');
}

// Note: Modal state and functions are already defined above
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
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  max-height: 2.5rem; /* Fallback for browsers that don't support line-clamp */
}

/* Background gradient animation for search card */
.bg-gradient-to-r {
  background-size: 200% 200%;
  animation: gradientShift 15s ease infinite;
}

@keyframes gradientShift {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

/* Modal animations */
.modal-backdrop {
  animation: fadeIn 0.3s ease forwards;
}

.modal-content {
  animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translate3d(0, 40px, 0);
  }
  to {
    opacity: 1;
    transform: translate3d(0, 0, 0);
  }
}

/* Custom scrollbar for modal description */
.max-h-60::-webkit-scrollbar {
  width: 6px;
}

.max-h-60::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 8px;
}

.max-h-60::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 8px;
  border: 1px solid #f1f1f1;
}

.max-h-60::-webkit-scrollbar-thumb:hover {
  background-color: #94a3b8;
}
</style>
