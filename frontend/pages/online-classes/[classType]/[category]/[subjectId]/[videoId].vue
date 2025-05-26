<template>
  <PublicSection>
    <UContainer class="py-8">
      <UBreadcrumb :links="breadcrumbs" class="mb-6" />
      
      <!-- Video Player and Information -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Video Player Section -->
        <div class="lg:col-span-2">
          <!-- Video Player -->
          <div class="bg-black rounded-lg overflow-hidden relative aspect-video mb-6 shadow-lg">
            <!-- Loading state or thumbnail -->
            <div v-if="isLoading" class="absolute inset-0 flex items-center justify-center bg-gray-900">
              <div class="flex flex-col items-center">
                <UIcon name="i-heroicons-arrow-path" class="text-4xl text-white animate-spin" />
                <span class="text-white mt-2">Loading video...</span>
              </div>
            </div>
            
            <!-- Video player placeholder (would integrate with real video player) -->
            <div v-else class="w-full h-full bg-black flex items-center justify-center">
              <img 
                :src="videoData.thumbnail" 
                alt="Video thumbnail" 
                class="w-full h-full object-contain"
              >
              <div class="absolute inset-0 flex items-center justify-center">
                <button 
                  class="bg-primary-600 bg-opacity-80 hover:bg-opacity-100 transition-all rounded-full w-16 h-16 flex items-center justify-center"
                  @click="isPlaying = !isPlaying"
                >
                  <UIcon 
                    :name="isPlaying ? 'i-heroicons-pause' : 'i-heroicons-play'" 
                    class="text-white text-2xl ml-0.5"
                  />
                </button>
              </div>
              
              <!-- Video Controls (bottom) -->
              <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-3">
                <div class="flex flex-col">
                  <!-- Progress bar -->
                  <div class="w-full h-1 bg-gray-600 rounded-full mb-2 relative">
                    <div class="absolute h-1 bg-primary-500 rounded-full" :style="{ width: `${videoProgress}%` }"></div>
                    <div 
                      class="absolute h-3 w-3 bg-white rounded-full -mt-1 -ml-1.5" 
                      :style="{ left: `${videoProgress}%` }"
                    ></div>
                  </div>
                  
                  <!-- Controls row -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-3">
                      <!-- Play/Pause button -->
                      <button class="text-white hover:text-primary-400">
                        <UIcon :name="isPlaying ? 'i-heroicons-pause' : 'i-heroicons-play'" class="text-lg" />
                      </button>
                      
                      <!-- Volume control -->
                      <div class="flex items-center">
                        <button class="text-white hover:text-primary-400">
                          <UIcon name="i-heroicons-speaker-wave" class="text-lg" />
                        </button>
                        <div class="w-16 h-1 bg-gray-600 rounded-full ml-2">
                          <div class="h-1 bg-white rounded-full" style="width: 70%"></div>
                        </div>
                      </div>
                      
                      <!-- Time display -->
                      <span class="text-white text-xs">02:34 / 15:48</span>
                    </div>
                    
                    <div class="flex items-center space-x-3">
                      <!-- Playback speed -->
                      <UDropdown>
                        <button class="text-white text-xs hover:text-primary-400">
                          1.0x
                        </button>
                        
                        <template #items>
                          <UDropdownItem>0.5x</UDropdownItem>
                          <UDropdownItem>0.75x</UDropdownItem>
                          <UDropdownItem>1.0x</UDropdownItem>
                          <UDropdownItem>1.25x</UDropdownItem>
                          <UDropdownItem>1.5x</UDropdownItem>
                          <UDropdownItem>2.0x</UDropdownItem>
                        </template>
                      </UDropdown>
                      
                      <!-- Quality button -->
                      <UDropdown>
                        <button class="text-white text-xs hover:text-primary-400">
                          HD
                        </button>
                        
                        <template #items>
                          <UDropdownItem>Auto</UDropdownItem>
                          <UDropdownItem>1080p (HD)</UDropdownItem>
                          <UDropdownItem>720p (HD)</UDropdownItem>
                          <UDropdownItem>480p</UDropdownItem>
                          <UDropdownItem>360p</UDropdownItem>
                        </template>
                      </UDropdown>
                      
                      <!-- Fullscreen button -->
                      <button class="text-white hover:text-primary-400">
                        <UIcon name="i-heroicons-arrows-pointing-out" class="text-lg" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Video Information -->
          <div>
            <h1 class="text-2xl font-bold mb-2">{{ videoData.title }}</h1>
            <div class="flex flex-wrap items-center gap-2 text-sm text-gray-600 mb-4">
              <span class="flex items-center">
                <UIcon name="i-heroicons-calendar" class="mr-1" />
                {{ formatDate(videoData.publishedAt) }}
              </span>
              <span class="flex items-center">
                <UIcon name="i-heroicons-eye" class="mr-1" />
                {{ formatViewCount(videoData.views) }} views
              </span>
              <span>•</span>
              <span class="flex items-center">
                <UIcon name="i-heroicons-clock" class="mr-1" />
                {{ formatDuration(videoData.duration) }}
              </span>
              
              <div class="ml-auto">
                <UButton
                  size="xs"
                  icon="i-heroicons-bookmark"
                  color="gray"
                  variant="soft"
                  class="mr-2"
                  label="Save"
                />
                <UButton
                  size="xs"
                  icon="i-heroicons-share"
                  color="gray"
                  variant="soft"
                  label="Share"
                />
              </div>
            </div>
            
            <!-- Video description -->
            <UCard class="mb-6">
              <div class="prose max-w-none">
                <h3 class="text-lg font-medium mb-2">Description</h3>
                <p>{{ videoData.description }}</p>
                
                <div class="mt-4">
                  <h4 class="font-medium">Topics Covered:</h4>
                  <ul class="list-disc list-inside ml-2">
                    <li v-for="(topic, index) in videoData.topics" :key="index">
                      {{ topic }}
                    </li>
                  </ul>
                </div>
              </div>
            </UCard>
            
            <!-- Notes and attachments -->
            <UCard v-if="videoData.resources && videoData.resources.length > 0" class="mb-6">
              <template #header>
                <div class="p-3 bg-gray-50">
                  <h3 class="font-medium">Study Materials & Resources</h3>
                </div>
              </template>
              <div class="p-4">
                <ul class="space-y-2">
                  <li v-for="(resource, index) in videoData.resources" :key="index">
                    <a 
                      href="#" 
                      class="flex items-center p-2 rounded-md hover:bg-gray-50 transition-colors"
                    >
                      <UIcon 
                        :name="getResourceIcon(resource.type)" 
                        class="mr-2" 
                        :class="getResourceIconClass(resource.type)" 
                      />
                      <span>{{ resource.name }}</span>
                      <UBadge color="gray" size="xs" class="ml-2">{{ resource.type }}</UBadge>
                      <UIcon name="i-heroicons-arrow-down-tray" class="ml-auto text-gray-500" />
                    </a>
                  </li>
                </ul>
              </div>
            </UCard>
          </div>
        </div>
        
        <!-- Sidebar - Related Videos & Teacher Info -->
        <div class="lg:col-span-1">
          <!-- Teacher Information -->
          <UCard class="mb-6">
            <template #header>
              <div class="p-3 bg-primary-50">
                <h3 class="font-medium text-primary-700">Teacher</h3>
              </div>
            </template>
            <div class="p-4">
              <div class="flex items-center">
                <img 
                  :src="videoData.teacher.image" 
                  :alt="videoData.teacher.name" 
                  class="w-16 h-16 rounded-full object-cover border-2 border-primary-100"
                >
                <div class="ml-3">
                  <h4 class="font-medium">{{ videoData.teacher.name }}</h4>
                  <p class="text-sm text-primary-600">{{ videoData.teacher.title }}</p>
                  <div class="flex items-center mt-1">
                    <div class="flex">
                      <UIcon 
                        v-for="i in 5" 
                        :key="i"
                        :name="i <= videoData.teacher.rating ? 'i-heroicons-star' : 'i-heroicons-star-half'"
                        :class="i <= Math.ceil(videoData.teacher.rating) ? 'text-amber-400' : 'text-gray-300'"
                      />
                    </div>
                    <span class="text-xs ml-1">({{ videoData.teacher.rating }})</span>
                  </div>
                </div>
              </div>
              <p class="text-sm text-gray-600 mt-3">{{ videoData.teacher.bio }}</p>
              <UButton size="sm" color="primary" variant="soft" label="View Full Profile" class="mt-3 w-full" />
            </div>
          </UCard>
          
          <!-- Related Videos -->
          <UCard>
            <template #header>
              <div class="p-3 bg-gray-50">
                <h3 class="font-medium">Related Videos</h3>
              </div>
            </template>
            <nav class="divide-y">
              <a 
                v-for="video in relatedVideos" 
                :key="video.id"
                href="#" 
                class="flex p-3 hover:bg-gray-50"
              >
                <div class="flex-shrink-0 relative w-20 h-12">
                  <img :src="video.thumbnail" :alt="video.title" class="w-full h-full object-cover rounded">
                  <div class="absolute bottom-1 right-1 bg-black bg-opacity-75 text-white text-xs px-1 rounded">
                    {{ formatDuration(video.duration) }}
                  </div>
                </div>
                <div class="ml-3">
                  <h4 class="text-sm font-medium line-clamp-2">{{ video.title }}</h4>
                  <div class="flex items-center mt-1 text-xs text-gray-500">
                    <UIcon name="i-heroicons-eye" class="mr-1" />
                    {{ formatViewCount(video.views) }} views
                  </div>
                </div>
              </a>
            </nav>
          </UCard>
        </div>
      </div>
      
      <!-- Notes and Questions Section -->
      <div class="mt-8">
        <UTabs :items="tabItems">
          <template #item-notes>
            <div class="prose max-w-none">
              <h3 class="text-lg font-medium">Class Notes</h3>
              <p class="text-gray-600">Comprehensive notes for this lesson:</p>
              
              <div class="bg-gray-50 p-4 rounded-md border border-gray-200 mt-4">
                <h4>Key Concepts</h4>
                <ul>
                  <li><strong>Kinematics:</strong> The study of motion without considering the causes of motion.</li>
                  <li><strong>Distance vs Displacement:</strong> Distance is a scalar quantity representing the total path length, while displacement is a vector quantity representing the change in position.</li>
                  <li><strong>Speed vs Velocity:</strong> Speed is a scalar quantity representing distance covered per unit of time, while velocity is a vector quantity representing displacement per unit of time.</li>
                  <li><strong>Acceleration:</strong> The rate of change of velocity per unit of time.</li>
                </ul>
                
                <h4 class="mt-4">Formulas</h4>
                <div class="bg-white p-3 rounded border border-gray-200">
                  <p>\( v = u + at \)</p>
                  <p>\( s = ut + \frac{1}{2}at^2 \)</p>
                  <p>\( v^2 = u^2 + 2as \)</p>
                  <p>Where:</p>
                  <ul>
                    <li>\( u \) = initial velocity</li>
                    <li>\( v \) = final velocity</li>
                    <li>\( a \) = acceleration</li>
                    <li>\( t \) = time</li>
                    <li>\( s \) = displacement</li>
                  </ul>
                </div>
                
                <h4 class="mt-4">Important Points to Remember</h4>
                <ol>
                  <li>For an object moving with uniform velocity, acceleration is zero.</li>
                  <li>The area under a velocity-time graph gives the displacement.</li>
                  <li>The slope of a velocity-time graph gives the acceleration.</li>
                </ol>
                
                <div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400">
                  <p class="font-medium">Exam Tips:</p>
                  <p>Pay special attention to the sign conventions for displacement, velocity, and acceleration. A common mistake is to ignore the direction of vectors in calculations.</p>
                </div>
              </div>
            </div>
          </template>
          
          <template #item-questions>
            <div>
              <h3 class="text-lg font-medium mb-4">Practice Questions</h3>
              
              <div class="space-y-6">
                <!-- Question 1 -->
                <UCard>
                  <div class="p-4">
                    <h4 class="font-medium mb-2">Question 1:</h4>
                    <p>A car accelerates uniformly from rest to a speed of 20 m/s in 5 seconds. Calculate:</p>
                    <ol class="list-decimal list-inside mt-2 ml-4 space-y-2">
                      <li>The acceleration of the car</li>
                      <li>The distance covered by the car in these 5 seconds</li>
                    </ol>
                    
                    <UButton 
                      class="mt-4" 
                      size="sm" 
                      color="gray" 
                      variant="soft" 
                      label="Show Answer" 
                      @click="showAnswer1 = !showAnswer1" 
                    />
                    
                    <div v-if="showAnswer1" class="mt-4 bg-green-50 p-4 rounded-md border border-green-200">
                      <p class="font-medium text-green-800">Solution:</p>
                      <ol class="list-decimal list-inside mt-2 space-y-2">
                        <li>
                          Acceleration = (final velocity - initial velocity) / time<br>
                          a = (20 m/s - 0 m/s) / 5 s = 4 m/s²
                        </li>
                        <li>
                          Distance = (initial velocity × time) + (½ × acceleration × time²)<br>
                          s = (0 × 5) + (½ × 4 × 5²)<br>
                          s = 50 m
                        </li>
                      </ol>
                    </div>
                  </div>
                </UCard>
                
                <!-- Question 2 -->
                <UCard>
                  <div class="p-4">
                    <h4 class="font-medium mb-2">Question 2:</h4>
                    <p>A ball is thrown vertically upward with an initial velocity of 15 m/s. If the acceleration due to gravity is 10 m/s², find:</p>
                    <ol class="list-decimal list-inside mt-2 ml-4 space-y-2">
                      <li>The maximum height reached by the ball</li>
                      <li>The total time taken by the ball to return to its starting point</li>
                    </ol>
                    
                    <UButton 
                      class="mt-4" 
                      size="sm" 
                      color="gray" 
                      variant="soft" 
                      label="Show Answer" 
                      @click="showAnswer2 = !showAnswer2" 
                    />
                    
                    <div v-if="showAnswer2" class="mt-4 bg-green-50 p-4 rounded-md border border-green-200">
                      <p class="font-medium text-green-800">Solution:</p>
                      <ol class="list-decimal list-inside mt-2 space-y-2">
                        <li>
                          At maximum height, velocity = 0<br>
                          Using v² = u² + 2as<br>
                          0 = 15² + 2(-10)h<br>
                          h = 15² / 20 = 11.25 m
                        </li>
                        <li>
                          Time to reach the maximum height:<br>
                          v = u + at<br>
                          0 = 15 + (-10)t<br>
                          t = 1.5 s<br><br>
                          Time to return = 2 × time to reach max height = 2 × 1.5 s = 3 s
                        </li>
                      </ol>
                    </div>
                  </div>
                </UCard>
              </div>
            </div>
          </template>
        </UTabs>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const route = useRoute();
const classType = computed(() => route.params.classType); // 'ssc' or 'hsc'
const category = computed(() => route.params.category); // 'science', 'humanities', 'commerce'
const subjectId = computed(() => route.params.subjectId);
const videoId = computed(() => route.params.videoId);

// UI state
const isLoading = ref(false);
const isPlaying = ref(false);
const videoProgress = ref(25); // Mock video progress (0-100)
const showAnswer1 = ref(false);
const showAnswer2 = ref(false);

// Tab items for notes and questions
const tabItems = [
  {
    id: 'notes',
    label: 'Notes & Summary',
    icon: 'i-heroicons-document-text'
  },
  {
    id: 'questions',
    label: 'Practice Questions',
    icon: 'i-heroicons-academic-cap'
  }
];

// Mock video data - would come from an API in real application
const videoData = ref({
  id: 'phy1',
  title: 'Introduction to Kinematics',
  description: 'This comprehensive lesson covers the fundamental concepts of kinematics including displacement, velocity, and acceleration. You\'ll learn how to distinguish between scalar and vector quantities, understand the equations of motion, and solve basic kinematics problems. Perfect for SSC Physics preparation.',
  thumbnail: 'https://images.unsplash.com/photo-1636466497217-26a42372ead6',
  duration: 1245, // in seconds
  publishedAt: '2023-08-15',
  views: 12500,
  topics: [
    'Difference between distance and displacement',
    'Average velocity vs instantaneous velocity',
    'Acceleration and its significance',
    'Three equations of motion and their applications',
    'Graphical representation of motion'
  ],
  resources: [
    {
      name: 'Kinematics Formula Sheet',
      type: 'PDF',
      url: '#'
    },
    {
      name: 'Practice Problems Set',
      type: 'PDF',
      url: '#'
    },
    {
      name: 'Motion Graphs Cheatsheet',
      type: 'Image',
      url: '#'
    },
    {
      name: 'Interactive Physics Simulation',
      type: 'Link',
      url: '#'
    }
  ],
  teacher: {
    name: 'Dr. Farhan Ahmed',
    title: 'PhD in Physics',
    image: 'https://i.pravatar.cc/150?img=1',
    rating: 4.8,
    bio: 'Specializing in modern physics and quantum mechanics with 10+ years of teaching experience in preparing students for board examinations.'
  }
});

// Mock related videos
const relatedVideos = ref([
  {
    id: 'phy2',
    title: 'Equations of Motion',
    description: 'Detailed explanation of the three equations of motion.',
    thumbnail: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb',
    duration: 1560,
    views: 9800
  },
  {
    id: 'phy3',
    title: 'Graphical Analysis of Motion',
    description: 'Understanding position-time and velocity-time graphs.',
    thumbnail: 'https://images.unsplash.com/photo-1598618356794-eb1720430eb4',
    duration: 1125,
    views: 7200
  },
  {
    id: 'phy4',
    title: 'Problem Solving in Kinematics',
    description: 'Step by step approach to solve kinematics problems.',
    thumbnail: 'https://images.unsplash.com/photo-1596496181871-9681eacf9764',
    duration: 1350,
    views: 6500
  },
  {
    id: 'phy5',
    title: 'Motion Under Gravity',
    description: 'Free fall and projectile motion explained.',
    thumbnail: 'https://images.unsplash.com/photo-1454789415558-bdda08f4eabb',
    duration: 1420,
    views: 5800
  }
]);

// Dynamic class and category titles based on URL params
const classTitle = computed(() => {
  if (classType.value === 'ssc') {
    return 'SSC';
  } else if (classType.value === 'hsc') {
    return 'HSC';
  }
  return 'Classes';
});

const categoryTitle = computed(() => {
  switch (category.value) {
    case 'science': return 'Science';
    case 'humanities': return 'Humanities';
    case 'commerce': return 'Commerce';
    default: return 'Category';
  }
});

const subjectTitle = computed(() => {
  switch (subjectId.value) {
    case 'physics': return 'Physics';
    case 'chemistry': return 'Chemistry';
    case 'biology': return 'Biology';
    case 'math': return 'Mathematics';
    case 'history': return 'History';
    case 'geography': return 'Geography';
    case 'accounting': return 'Accounting';
    case 'economics': return 'Economics';
    default: return 'Subject';
  }
});

// Dynamic breadcrumbs based on current path
const breadcrumbs = computed(() => [
  {
    label: 'Home',
    to: '/'
  },
  {
    label: 'Online Classes',
    to: '/online-classes'
  },
  {
    label: classTitle.value,
    to: `/online-classes/${classType.value}`
  },
  {
    label: categoryTitle.value,
    to: `/online-classes/${classType.value}/${category.value}`
  },
  {
    label: subjectTitle.value,
    to: `/online-classes/${classType.value}/${category.value}/${subjectId.value}`
  },
  {
    label: videoData.value.title,
    to: `/online-classes/${classType.value}/${category.value}/${subjectId.value}/${videoId.value}`
  }
]);

// Utility functions
function formatDuration(seconds) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds < 10 ? '0' : ''}${remainingSeconds}`;
}

function formatDate(dateString) {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function formatViewCount(count) {
  if (count >= 1000000) {
    return (count / 1000000).toFixed(1) + 'M';
  } else if (count >= 1000) {
    return (count / 1000).toFixed(1) + 'K';
  }
  return count.toString();
}

function getResourceIcon(type) {
  switch (type.toLowerCase()) {
    case 'pdf': return 'i-heroicons-document-text';
    case 'image': return 'i-heroicons-photo';
    case 'link': return 'i-heroicons-link';
    case 'video': return 'i-heroicons-video-camera';
    default: return 'i-heroicons-document';
  }
}

function getResourceIconClass(type) {
  switch (type.toLowerCase()) {
    case 'pdf': return 'text-red-600';
    case 'image': return 'text-blue-600';
    case 'link': return 'text-green-600';
    case 'video': return 'text-purple-600';
    default: return 'text-gray-600';
  }
}

// Simulate loading on mount
onMounted(() => {
  isLoading.value = true;
  
  // Simulating video loading
  setTimeout(() => {
    isLoading.value = false;
  }, 1000);
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;  
  overflow: hidden;
}

/* Add Math formula styling if needed */
</style>
