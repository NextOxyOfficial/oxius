<template>
  <PublicSection>
    <UContainer class="py-8">
      <UBreadcrumb :links="breadcrumbs" class="mb-6" />
      
      <h1 class="text-3xl font-bold mb-2 flex items-center">
        <UIcon 
          :name="categoryIcon" 
          class="mr-3 text-3xl" 
          :class="categoryTextClass"
        />
        {{ classTitle }} - {{ categoryTitle }}
      </h1>
      <p class="text-gray-600 mb-8">Select a subject from the sidebar and explore video lessons</p>

      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Left Sidebar - Subjects List -->
        <div class="w-full lg:w-1/4">
          <UCard>
            <template #header>
              <div :class="['p-3', categoryHeaderClass]">
                <h2 class="font-bold" :class="categoryTextClass">Subjects</h2>
              </div>
            </template>
            
            <!-- Subjects Navigation -->
            <nav class="space-y-1 p-2">
              <UButton
                v-for="subject in subjects"
                :key="subject.id"
                :label="subject.name"
                :icon="subject.icon"
                block
                color="gray"
                variant="ghost"
                :class="{ 
                  'bg-gray-100 font-medium': subject.id === activeSubject.id,
                  'hover:bg-gray-50': subject.id !== activeSubject.id
                }"
                @click="setActiveSubject(subject)"
              />
            </nav>
          </UCard>          <!-- Teacher Information Card -->
          <UCard class="mt-6">
            <template #header>
              <div class="p-3 bg-primary-50">
                <h2 class="font-bold text-primary-700">Teacher</h2>
              </div>
            </template>
            <div class="p-4">
              <div v-if="activeSubject.teacher" class="flex flex-col items-center">
                <img 
                  :src="activeSubject.teacher.image" 
                  :alt="activeSubject.teacher.name" 
                  class="w-24 h-24 rounded-full object-cover border-2 border-primary-100 mb-3"
                >
                <h3 class="text-lg font-semibold">{{ activeSubject.teacher.name }}</h3>
                <p class="text-sm text-primary-600 font-medium mb-1">{{ activeSubject.teacher.title }}</p>
                <div class="flex items-center mb-3">
                  <div class="flex">
                    <UIcon 
                      v-for="i in 5" 
                      :key="i"
                      :name="i <= activeSubject.teacher.rating 
                        ? 'i-heroicons-star' 
                        : (i - 0.5 <= activeSubject.teacher.rating ? 'i-heroicons-star-half' : 'i-heroicons-star')"
                      :class="i <= Math.ceil(activeSubject.teacher.rating) ? 'text-amber-400' : 'text-gray-300'"
                    />
                  </div>
                  <span class="text-xs ml-1">({{ activeSubject.teacher.rating }})</span>
                </div>
                <p class="text-sm text-gray-600 text-center">{{ activeSubject.teacher.bio }}</p>
                <UButton size="sm" color="primary" variant="soft" label="View Full Profile" class="mt-3" />
              </div>
              <div v-else class="flex flex-col items-center">
                <UIcon name="i-heroicons-user-circle" class="w-24 h-24 text-gray-300 mb-3" />
                <p class="text-gray-500">Teacher information not available</p>
              </div>
            </div>
          </UCard>
        </div>
        
        <!-- Right Content Area - Videos -->
        <div class="w-full lg:w-3/4">
          <!-- Page Number Filter -->
          <UCard class="mb-6">
            <template #header>
              <div class="p-3 bg-gray-50 flex justify-between items-center">
                <h2 class="font-bold text-gray-700">{{ activeSubject.name }} - Video Lessons</h2>
                <div class="flex items-center">
                  <span class="text-sm text-gray-600 mr-2">Page:</span>
                  <USelect
                    v-model="selectedPage"
                    :options="activeSubject.pages"
                    optionAttribute="name"
                    valueAttribute="id"
                    placeholder="Select page"
                    size="sm"
                    class="w-48"
                  />
                </div>
              </div>
            </template>
            <div class="p-4">
              <div class="flex justify-between items-center mb-4">
                <div v-if="activePage" class="text-sm text-gray-600">
                  <span class="font-medium">Current chapter:</span> {{ activePage.name }}
                </div>
                <UInput 
                  v-model="searchQuery"
                  placeholder="Search videos..."
                  icon="i-heroicons-magnifying-glass"
                  clearable
                  size="sm"
                  class="w-64"
                />
              </div>
              
              <!-- Video content count -->
              <p class="text-sm text-gray-500">
                {{ filteredVideos.length }} video{{ filteredVideos.length !== 1 ? 's' : '' }} available
              </p>
            </div>
          </UCard>
          
          <!-- Videos Grid -->
          <div v-if="filteredVideos.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <UCard
              v-for="video in filteredVideos"
              :key="video.id"
              class="hover:shadow-lg transition-all duration-300"
            >
              <!-- Video Preview -->
              <div class="relative group cursor-pointer bg-gray-100 h-48 overflow-hidden">
                <img :src="video.thumbnail" :alt="video.title" class="w-full h-full object-cover">
                <div class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                  <UButton color="white" icon="i-heroicons-play" variant="solid" label="Play" />
                </div>
                <div class="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white text-xs px-2 py-1 rounded">
                  {{ formatDuration(video.duration) }}
                </div>
              </div>
              
              <div class="p-4">
                <h3 class="font-medium text-gray-900 mb-1">{{ video.title }}</h3>
                <p class="text-gray-600 text-sm mb-3 line-clamp-2">{{ video.description }}</p>
                
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <UIcon name="i-heroicons-clock" class="text-gray-400 mr-1" />
                    <span class="text-xs text-gray-500">{{ formatDate(video.publishedAt) }}</span>
                  </div>
                  
                  <div class="flex gap-2">
                    <UBadge v-if="video.isNew" color="green" size="xs" variant="subtle" class="italic">New</UBadge>
                    <UBadge v-if="video.isFeatured" color="amber" size="xs" variant="subtle" class="italic">Featured</UBadge>
                  </div>
                </div>
              </div>
              
              <template #footer>
                <div class="flex justify-between items-center">
                  <div class="text-xs text-gray-500 flex items-center">
                    <UIcon name="i-heroicons-eye" class="mr-1" />
                    {{ formatViewCount(video.views) }} views
                  </div>
                  <UButton size="xs" color="primary" label="Watch Now" />
                </div>
              </template>
            </UCard>
          </div>
          
          <!-- Empty state -->
          <div v-else class="flex flex-col items-center justify-center p-8 bg-gray-50 rounded-lg">
            <UIcon name="i-heroicons-video-camera-slash" class="text-5xl text-gray-400 mb-4" />
            <h3 class="text-lg font-medium text-gray-700">No videos found</h3>
            <p class="text-gray-500">Try selecting a different page or adjusting your search.</p>
          </div>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const route = useRoute();
const classType = computed(() => route.params.classType); // 'ssc' or 'hsc'
const category = computed(() => route.params.category); // 'science', 'humanities', 'commerce'

// Search and filtering
const searchQuery = ref('');
const selectedPage = ref(null);

// Dynamic class title based on URL param
const classTitle = computed(() => {
  if (classType.value === 'ssc') {
    return 'SSC';
  } else if (classType.value === 'hsc') {
    return 'HSC';
  }
  return 'Classes';
});

// Dynamic category title and styling based on URL param
const categoryTitle = computed(() => {
  switch (category.value) {
    case 'science': return 'Science';
    case 'humanities': return 'Humanities';
    case 'commerce': return 'Commerce';
    default: return 'Category';
  }
});

const categoryIcon = computed(() => {
  switch (category.value) {
    case 'science': return 'i-heroicons-beaker';
    case 'humanities': return 'i-heroicons-language';
    case 'commerce': return 'i-heroicons-currency-dollar';
    default: return 'i-heroicons-academic-cap';
  }
});

const categoryHeaderClass = computed(() => {
  switch (category.value) {
    case 'science': return 'bg-green-50';
    case 'humanities': return 'bg-amber-50';
    case 'commerce': return 'bg-blue-50';
    default: return 'bg-gray-50';
  }
});

const categoryTextClass = computed(() => {
  switch (category.value) {
    case 'science': return 'text-green-700';
    case 'humanities': return 'text-amber-700';
    case 'commerce': return 'text-blue-700';
    default: return 'text-gray-700';
  }
});

// Mock subject data based on the category
// In a real application, this would come from an API
const subjectsData = computed(() => {
  if (category.value === 'science') {
    return [
      {
        id: 'physics',
        name: 'Physics',
        icon: 'i-heroicons-bolt',
        teacher: {
          name: 'Dr. Farhan Ahmed',
          title: 'PhD in Physics',
          image: 'https://i.pravatar.cc/150?img=1',
          rating: 4.8,
          bio: 'Specializing in modern physics and quantum mechanics with 10+ years of teaching experience.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Motion' },
          { id: 'ch2', name: 'Chapter 2: Force and Laws of Motion' },
          { id: 'ch3', name: 'Chapter 3: Gravitation' },
          { id: 'ch4', name: 'Chapter 4: Work and Energy' }
        ],
        videos: [
          {
            id: 'phy1',
            title: 'Introduction to Kinematics',
            description: 'Learn about the basic concepts of kinematics, displacement, velocity, and acceleration.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1636466497217-26a42372ead6',
            duration: 1245, // in seconds
            publishedAt: '2023-08-15',
            views: 12500,
            isNew: true,
            isFeatured: false
          },
          {
            id: 'phy2',
            title: 'Equations of Motion',
            description: 'Detailed explanation of the three equations of motion and their applications in solving problems.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb',
            duration: 1560, // in seconds
            publishedAt: '2023-08-18',
            views: 9800,
            isNew: true,
            isFeatured: true
          },
          {
            id: 'phy3',
            title: 'Newton\'s First Law of Motion',
            description: 'Detailed explanation of Newton\'s First Law with examples and applications.',
            pageId: 'ch2',
            thumbnail: 'https://images.unsplash.com/photo-1507413245164-6160d8298b31',
            duration: 1350, // in seconds
            publishedAt: '2023-08-22',
            views: 8500,
            isNew: false,
            isFeatured: false
          },
          {
            id: 'phy4',
            title: 'Newton\'s Second Law of Motion',
            description: 'Understanding force, mass and acceleration relationship with problem solving techniques.',
            pageId: 'ch2',
            thumbnail: 'https://images.unsplash.com/photo-1602720494904-e880be9fdb59',
            duration: 1480, // in seconds
            publishedAt: '2023-08-25',
            views: 7200,
            isNew: false,
            isFeatured: false
          }
        ]
      },
      {
        id: 'chemistry',
        name: 'Chemistry',
        icon: 'i-heroicons-flask',
        teacher: {
          name: 'Aisha Rahman',
          title: 'MSc in Chemistry',
          image: 'https://i.pravatar.cc/150?img=5',
          rating: 4.5,
          bio: 'Passionate about making chemistry fun and approachable with hands-on experiments and clear explanations.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Matter and Its Properties' },
          { id: 'ch2', name: 'Chapter 2: Atomic Structure' },
          { id: 'ch3', name: 'Chapter 3: Chemical Bonding' }
        ],
        videos: [
          {
            id: 'chem1',
            title: 'States of Matter',
            description: 'Understanding the properties of solids, liquids, and gases with demonstrations.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1603126857599-f6e157fa2fe6',
            duration: 1320, // in seconds
            publishedAt: '2023-09-01',
            views: 6300,
            isNew: false,
            isFeatured: true
          },
          {
            id: 'chem2',
            title: 'Atomic Models and Development',
            description: 'Evolution of atomic models from Dalton to modern quantum mechanical model.',
            pageId: 'ch2',
            thumbnail: 'https://images.unsplash.com/photo-1615900119312-2acd3a71f3aa',
            duration: 1650, // in seconds
            publishedAt: '2023-09-10',
            views: 5800,
            isNew: false,
            isFeatured: false
          }
        ]
      },
      {
        id: 'biology',
        name: 'Biology',
        icon: 'i-heroicons-puzzle-piece',
        teacher: {
          name: 'Mohammad Rahman',
          title: 'MSc in Biological Sciences',
          image: 'https://i.pravatar.cc/150?img=3',
          rating: 4.7,
          bio: 'Expert in making complex biological concepts easy to understand through visual aids and real-life examples.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Cell Structure and Functions' },
          { id: 'ch2', name: 'Chapter 2: Human Physiology' },
          { id: 'ch3', name: 'Chapter 3: Genetics and Evolution' }
        ],
        videos: [
          {
            id: 'bio1',
            title: 'Animal Cell vs Plant Cell',
            description: 'Detailed comparison between animal and plant cells with labeled diagrams and functions.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1594904351111-a072f80b1a71',
            duration: 1380, // in seconds
            publishedAt: '2023-09-05',
            views: 8900,
            isNew: true,
            isFeatured: true
          },
          {
            id: 'bio2',
            title: 'Cell Membrane Structure',
            description: 'Exploring the fluid mosaic model and functions of the cell membrane.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8',
            duration: 1230, // in seconds
            publishedAt: '2023-09-08',
            views: 7200,
            isNew: true,
            isFeatured: false
          }
        ]
      },
      {
        id: 'math',
        name: 'Mathematics',
        icon: 'i-heroicons-calculator',
        teacher: {
          name: 'Rakib Hossain',
          title: 'MSc in Mathematics',
          image: 'https://i.pravatar.cc/150?img=7',
          rating: 4.9,
          bio: 'Mathematics educator who breaks down complex problems into simple steps with helpful tricks and shortcuts.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Algebra' },
          { id: 'ch2', name: 'Chapter 2: Geometry' },
          { id: 'ch3', name: 'Chapter 3: Trigonometry' },
          { id: 'ch4', name: 'Chapter 4: Calculus' }
        ],
        videos: [
          {
            id: 'math1',
            title: 'Quadratic Equations',
            description: 'Methods to solve quadratic equations - factorization, completing the square, and quadratic formula.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1509228627152-72ae9ae6848d',
            duration: 1620, // in seconds
            publishedAt: '2023-08-12',
            views: 14500,
            isNew: false,
            isFeatured: true
          },
          {
            id: 'math2',
            title: 'Coordinate Geometry',
            description: 'Understanding the Cartesian plane, distance formula, and section formula with examples.',
            pageId: 'ch2',
            thumbnail: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb',
            duration: 1440, // in seconds
            publishedAt: '2023-08-20',
            views: 11200,
            isNew: false,
            isFeatured: false
          }
        ]
      }
    ];
  } else if (category.value === 'humanities') {
    return [
      {
        id: 'history',
        name: 'History',
        icon: 'i-heroicons-document-text',
        teacher: {
          name: 'Prof. Nusrat Jahan',
          title: 'MA in History',
          image: 'https://i.pravatar.cc/150?img=5',
          rating: 4.6,
          bio: 'History expert with a knack for storytelling that makes historical events memorable and engaging.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Ancient Civilizations' },
          { id: 'ch2', name: 'Chapter 2: Medieval History' },
          { id: 'ch3', name: 'Chapter 3: Modern History' }
        ],
        videos: [
          {
            id: 'hist1',
            title: 'The Indus Valley Civilization',
            description: 'Exploring the achievements and daily life in one of the world\'s oldest urban civilizations.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1566026284572-7605c1e64266',
            duration: 1520, // in seconds
            publishedAt: '2023-09-02',
            views: 9300,
            isNew: true,
            isFeatured: true
          }
        ]
      },
      {
        id: 'geography',
        name: 'Geography',
        icon: 'i-heroicons-globe-alt',
        teacher: {
          name: 'Salma Begum',
          title: 'MSc in Geography',
          image: 'https://i.pravatar.cc/150?img=23',
          rating: 4.4,
          bio: 'Specializes in physical and human geography with interactive mapping techniques and case studies.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Physical Geography' },
          { id: 'ch2', name: 'Chapter 2: Human Geography' },
          { id: 'ch3', name: 'Chapter 3: Maps and Directions' }
        ],
        videos: [
          {
            id: 'geo1',
            title: 'Understanding Climate Zones',
            description: 'Learn about different climate zones around the world and factors affecting climate.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1593991341138-9a9db56a8bf6',
            duration: 1380, // in seconds
            publishedAt: '2023-09-05',
            views: 7200,
            isNew: false,
            isFeatured: false
          }
        ]
      },
      {
        id: 'literature',
        name: 'Literature',
        icon: 'i-heroicons-book-open',
        teacher: {
          name: 'Abdul Karim',
          title: 'MA in English Literature',
          image: 'https://i.pravatar.cc/150?img=6',
          rating: 4.8,
          bio: 'Passionate about poetry and prose with expertise in literary analysis and creative writing techniques.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Poetry' },
          { id: 'ch2', name: 'Chapter 2: Prose' },
          { id: 'ch3', name: 'Chapter 3: Drama' }
        ],
        videos: [
          {
            id: 'lit1',
            title: 'Understanding Poetic Devices',
            description: 'A comprehensive guide to metaphors, similes, alliteration, and more with examples from famous poems.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1476275466078-4007374efbbe',
            duration: 1620, // in seconds
            publishedAt: '2023-08-15',
            views: 8400,
            isNew: true,
            isFeatured: true
          }
        ]
      }
    ];
  } else if (category.value === 'commerce') {
    return [
      {
        id: 'accounting',
        name: 'Accounting',
        icon: 'i-heroicons-calculator',
        teacher: {
          name: 'Kamal Hossain',
          title: 'CPA, MBA in Accounting',
          image: 'https://i.pravatar.cc/150?img=3',
          rating: 4.7,
          bio: 'Certified accountant with teaching experience that makes accounting principles clear and practical.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Basic Accounting' },
          { id: 'ch2', name: 'Chapter 2: Financial Statements' },
          { id: 'ch3', name: 'Chapter 3: Cost Accounting' }
        ],
        videos: [
          {
            id: 'acc1',
            title: 'Accounting Equation',
            description: 'Understanding the fundamental equation: Assets = Liabilities + Owner\'s Equity',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1554224155-8d04cb21ed6c',
            duration: 1350, // in seconds
            publishedAt: '2023-09-01',
            views: 9200,
            isNew: false,
            isFeatured: true
          }
        ]
      },
      {
        id: 'economics',
        name: 'Economics',
        icon: 'i-heroicons-chart-bar',
        teacher: {
          name: 'Nazia Islam',
          title: 'MA in Economics',
          image: 'https://i.pravatar.cc/150?img=25',
          rating: 4.5,
          bio: 'Makes complex economic theories accessible through real-world examples and current affairs.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Microeconomics' },
          { id: 'ch2', name: 'Chapter 2: Macroeconomics' },
          { id: 'ch3', name: 'Chapter 3: International Trade' }
        ],
        videos: [
          {
            id: 'eco1',
            title: 'Supply and Demand',
            description: 'Understanding the basic economic model of supply and demand and market equilibrium.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3',
            duration: 1480, // in seconds
            publishedAt: '2023-08-20',
            views: 8500,
            isNew: true,
            isFeatured: false
          }
        ]
      },
      {
        id: 'business',
        name: 'Business Studies',
        icon: 'i-heroicons-briefcase',
        teacher: {
          name: 'Tahmid Khan',
          title: 'MBA in Business Management',
          image: 'https://i.pravatar.cc/150?img=8',
          rating: 4.6,
          bio: 'Former business executive bringing real-world experience into the classroom with practical insights.'
        },
        pages: [
          { id: 'ch1', name: 'Chapter 1: Business Organization' },
          { id: 'ch2', name: 'Chapter 2: Marketing' },
          { id: 'ch3', name: 'Chapter 3: Business Finance' }
        ],
        videos: [
          {
            id: 'bus1',
            title: 'Forms of Business Organization',
            description: 'Comparing sole proprietorship, partnership, and corporations with advantages and disadvantages.',
            pageId: 'ch1',
            thumbnail: 'https://images.unsplash.com/photo-1542744173-8e7e53415bb0',
            duration: 1560, // in seconds
            publishedAt: '2023-09-05',
            views: 7800,
            isNew: false,
            isFeatured: true
          }
        ]
      }
    ];
  } else {
    return [];
  }
});

// Initialize with the first subject
const subjects = computed(() => subjectsData.value);
const activeSubject = ref({});

// Set initial active subject
onMounted(() => {
  console.log(`Category page mounted: ${classType.value}/${category.value}`);
  console.log('Subjects available:', subjects.value.length);
  
  if (subjects.value && subjects.value.length > 0) {
    setActiveSubject(subjects.value[0]);
  } else {
    // Initialize with empty subject if no subjects are available
    setActiveSubject({
      id: 'empty',
      name: 'No Subjects Available',
      icon: 'i-heroicons-question-mark-circle',
      teacher: null,
      pages: [],
      videos: []
    });
    console.warn(`No subjects found for ${classType.value}/${category.value}`);
  }
});

// Set active subject and reset page filter
function setActiveSubject(subject) {
  activeSubject.value = subject || {};
  selectedPage.value = subject && subject.pages && subject.pages.length > 0 ? subject.pages[0].id : null;
}

// Active page computed property
const activePage = computed(() => {
  if (!selectedPage.value || !activeSubject.value.pages) return null;
  return activeSubject.value.pages.find(page => page.id === selectedPage.value);
});

// Filtered videos based on selected page and search query
const filteredVideos = computed(() => {
  if (!activeSubject.value || !activeSubject.value.videos) return [];
  
  return activeSubject.value.videos.filter(video => {
    if (!video) return false;
    
    // Filter by page
    const matchesPage = !selectedPage.value || video.pageId === selectedPage.value;
    
    // Filter by search query
    const searchLower = searchQuery.value ? searchQuery.value.toLowerCase() : '';
    const matchesSearch = !searchQuery.value || 
      (video.title && video.title.toLowerCase().includes(searchLower)) || 
      (video.description && video.description.toLowerCase().includes(searchLower));
    
    return matchesPage && matchesSearch;
  });
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

// Display a notification in the console to confirm the page is loaded
onMounted(() => {
  console.log(`Category page loaded: ${classType.value}/${category.value}`);
});
</script>

<style scoped>
/* Any additional custom styles */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;  
  overflow: hidden;
}
</style>
