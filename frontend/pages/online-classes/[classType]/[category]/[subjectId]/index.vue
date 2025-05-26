<template>
  <PublicSection>
    <UContainer class="py-8">
      <UBreadcrumb :links="breadcrumbs" class="mb-6" />
      
      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Left Sidebar - Subject Info and Pages -->
        <div class="w-full lg:w-1/4">
          <!-- Subject Info Card -->
          <UCard class="mb-6">
            <template #header>
              <div :class="['p-3', categoryHeaderClass]">
                <div class="flex items-center">
                  <UIcon :name="subjectIcon" class="mr-2 text-xl" :class="categoryTextClass" />
                  <h2 class="font-bold" :class="categoryTextClass">{{ subjectTitle }}</h2>
                </div>
              </div>
            </template>
            <div class="p-4">
              <p class="text-gray-600 mb-4">{{ subjectDescription }}</p>
              
              <div class="flex flex-wrap gap-2">
                <UBadge 
                  :color="getCategoryColor(category)"
                  class="font-medium"
                >{{ categoryTitle }}</UBadge>
                <UBadge color="gray" class="font-medium">
                  {{ classTitle }}
                </UBadge>
              </div>
              
              <div class="mt-4 flex items-center justify-between text-sm text-gray-600">
                <div class="flex items-center">
                  <UIcon name="i-heroicons-video-camera" class="mr-1" />
                  <span>{{ totalVideos }} Videos</span>
                </div>
                <div class="flex items-center">
                  <UIcon name="i-heroicons-book-open" class="mr-1" />
                  <span>{{ totalChapters }} Chapters</span>
                </div>
              </div>
            </div>
          </UCard>
          
          <!-- Teacher Info Card -->
          <UCard class="mb-6">
            <template #header>
              <div class="p-3 bg-primary-50">
                <h2 class="font-bold text-primary-700">Teacher</h2>
              </div>
            </template>
            <div class="p-4">
              <div class="flex flex-col items-center">
                <img 
                  :src="subjectTeacher.image" 
                  :alt="subjectTeacher.name" 
                  class="w-24 h-24 rounded-full object-cover border-2 border-primary-100 mb-3"
                >
                <h3 class="text-lg font-semibold">{{ subjectTeacher.name }}</h3>
                <p class="text-sm text-primary-600 font-medium mb-1">{{ subjectTeacher.title }}</p>
                <div class="flex items-center mb-3">
                  <div class="flex">
                    <UIcon 
                      v-for="i in 5" 
                      :key="i"
                      :name="i <= subjectTeacher.rating ? 'i-heroicons-star' : 'i-heroicons-star'"
                      :class="i <= Math.ceil(subjectTeacher.rating) ? 'text-amber-400' : 'text-gray-300'"
                    />
                  </div>
                  <span class="text-xs ml-1">({{ subjectTeacher.rating }})</span>
                </div>
                <p class="text-sm text-gray-600 text-center">{{ subjectTeacher.bio }}</p>
                <UButton size="sm" color="primary" variant="soft" label="View Full Profile" class="mt-3" />
              </div>
            </div>
          </UCard>
          
          <!-- Pages/Chapters Navigation -->
          <UCard>
            <template #header>
              <div class="p-3 bg-gray-50">
                <h2 class="font-bold text-gray-700">Chapters</h2>
              </div>
            </template>
            
            <!-- Chapters Navigation -->
            <nav class="space-y-1 p-2">
              <UButton
                v-for="page in subjectPages"
                :key="page.id"
                :label="page.name"
                block
                color="gray"
                variant="ghost"
                :class="{ 
                  'bg-gray-100 font-medium': page.id === selectedPage,
                  'hover:bg-gray-50': page.id !== selectedPage
                }"
                @click="selectPage(page.id)"
              />
            </nav>
          </UCard>
        </div>
        
        <!-- Right Content Area - Videos by Chapter -->
        <div class="w-full lg:w-3/4">
          <!-- Search and Filter -->
          <UCard class="mb-6">
            <div class="p-4">
              <div class="flex flex-col sm:flex-row justify-between gap-4">
                <UInput 
                  v-model="searchQuery"
                  placeholder="Search videos..."
                  icon="i-heroicons-magnifying-glass"
                  clearable
                  class="w-full sm:w-64"
                />
                
                <div class="flex gap-2">
                  <USelect
                    v-model="sortBy"
                    :options="sortOptions"
                    placeholder="Sort by"
                    size="sm"
                    class="w-40"
                  />
                  
                  <UButton 
                    color="primary" 
                    variant="soft" 
                    icon="i-heroicons-arrow-path" 
                    @click="resetFilters"
                  />
                </div>
              </div>
            </div>
          </UCard>
          
          <!-- Chapter Header -->
          <UCard class="mb-6" v-if="currentPage">
            <template #header>
              <div class="p-3 bg-gray-50">
                <h2 class="font-bold text-gray-700">{{ currentPage.name }}</h2>
              </div>
            </template>
            <div class="p-4">
              <p class="text-gray-600">{{ currentPage.description }}</p>
              
              <!-- Learning outcomes -->
              <div class="mt-4">
                <h3 class="text-sm font-medium mb-2">Learning Outcomes:</h3>
                <ul class="text-sm text-gray-600 space-y-1">
                  <li v-for="(outcome, index) in currentPage.outcomes" :key="index" class="flex items-start">
                    <UIcon name="i-heroicons-check-circle" class="text-green-500 mr-2 mt-0.5 flex-shrink-0" />
                    <span>{{ outcome }}</span>
                  </li>
                </ul>
              </div>
            </div>
          </UCard>
          
          <!-- Videos Grid -->
          <div v-if="filteredVideos.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <UCard
              v-for="video in filteredVideos"
              :key="video.id"
              class="hover:shadow-lg transition-all duration-300 cursor-pointer"
              @click="navigateToVideo(video.id)"
            >
              <!-- Video Preview -->
              <div class="relative group bg-gray-100 h-48 overflow-hidden">
                <img :src="video.thumbnail" :alt="video.title" class="w-full h-full object-cover">
                <div class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                  <UButton color="white" icon="i-heroicons-play" variant="solid" label="Play" />
                </div>
                <div class="absolute bottom-2 right-2 bg-black bg-opacity-75 text-white text-xs px-2 py-1 rounded">
                  {{ formatDuration(video.duration) }}
                </div>
              </div>
              
              <div class="p-4">
                <h3 class="font-medium text-gray-900 mb-1 line-clamp-2">{{ video.title }}</h3>
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
            <p class="text-gray-500">Try adjusting your search or selecting a different chapter.</p>
          </div>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const route = useRoute();
const router = useRouter();

const classType = computed(() => route.params.classType); // 'ssc' or 'hsc'
const category = computed(() => route.params.category); // 'science', 'humanities', 'commerce'
const subjectId = computed(() => route.params.subjectId); // 'physics', 'chemistry', etc.

// UI state
const searchQuery = ref('');
const selectedPage = ref('');
const sortBy = ref('newest');

// Sort options
const sortOptions = [
  { label: 'Newest First', value: 'newest' },
  { label: 'Oldest First', value: 'oldest' },
  { label: 'Most Viewed', value: 'views' },
  { label: 'Title (A-Z)', value: 'title_asc' },
  { label: 'Title (Z-A)', value: 'title_desc' }
];

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

// Subject details based on subjectId
const subjectDetails = computed(() => {
  // This would come from an API in a real application
  const details = {
    physics: {
      title: 'Physics',
      description: 'Explore the fundamental principles that govern the physical world through interactive video lessons covering mechanics, waves, electricity, and more.',
      icon: 'i-heroicons-bolt',
      teacher: {
        name: 'Dr. Farhan Ahmed',
        title: 'PhD in Physics',
        image: 'https://i.pravatar.cc/150?img=1',
        rating: 4.8,
        bio: 'Specializing in modern physics and quantum mechanics with 10+ years of teaching experience.'
      },
      pages: [
        { 
          id: 'ch1', 
          name: 'Chapter 1: Motion', 
          description: 'Understanding the basic concepts of kinematics including distance, displacement, speed, velocity, and acceleration.',
          outcomes: [
            'Differentiate between scalar and vector quantities',
            'Apply equations of motion to solve problems',
            'Interpret position-time and velocity-time graphs',
            'Calculate displacement, velocity, and acceleration'
          ]
        },
        { 
          id: 'ch2', 
          name: 'Chapter 2: Force and Laws of Motion',
          description: 'Study of Newton\'s laws of motion and their applications in various physical scenarios.',
          outcomes: [
            'State and apply Newton\'s three laws of motion',
            'Calculate force, mass, and acceleration',
            'Understand the concept of inertia',
            'Solve problems involving multiple forces'
          ]
        },
        { 
          id: 'ch3', 
          name: 'Chapter 3: Gravitation',
          description: 'Exploring gravitational force, Kepler\'s laws, and the motion of planets and satellites.',
          outcomes: [
            'Apply the universal law of gravitation',
            'Calculate gravitational field strength',
            'Understand orbital motion and Kepler\'s laws',
            'Differentiate between mass and weight'
          ]
        },
        { 
          id: 'ch4', 
          name: 'Chapter 4: Work and Energy',
          description: 'Understanding the concepts of work, energy, and power with their applications.',
          outcomes: [
            'Define and calculate work done by a force',
            'Understand different forms of energy',
            'Apply the principle of conservation of energy',
            'Calculate power and efficiency'
          ]
        }
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
        },
        {
          id: 'phy5',
          title: 'Newton\'s Third Law of Motion',
          description: 'Action and reaction forces explained with real-world examples.',
          pageId: 'ch2',
          thumbnail: 'https://images.unsplash.com/photo-1454789548928-9efd52dc4031',
          duration: 1290, // in seconds
          publishedAt: '2023-08-28',
          views: 6800,
          isNew: false,
          isFeatured: false
        },
        {
          id: 'phy6',
          title: 'Universal Law of Gravitation',
          description: 'Newton\'s law of universal gravitation and its importance in physics.',
          pageId: 'ch3',
          thumbnail: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa',
          duration: 1620, // in seconds
          publishedAt: '2023-09-01',
          views: 5900,
          isNew: false,
          isFeatured: true
        },
        {
          id: 'phy7',
          title: 'Kepler\'s Laws of Planetary Motion',
          description: 'Understanding the motion of planets with Kepler\'s three laws.',
          pageId: 'ch3',
          thumbnail: 'https://images.unsplash.com/photo-1614732414444-096e5f1122d5',
          duration: 1380, // in seconds
          publishedAt: '2023-09-05',
          views: 5200,
          isNew: false,
          isFeatured: false
        },
        {
          id: 'phy8',
          title: 'Work, Energy and Power',
          description: 'Concept of work in physics and its relation to energy and power.',
          pageId: 'ch4',
          thumbnail: 'https://images.unsplash.com/photo-1617791160505-6f00504e3519',
          duration: 1530, // in seconds
          publishedAt: '2023-09-10',
          views: 4800,
          isNew: true,
          isFeatured: false
        }
      ]
    },
    chemistry: {
      title: 'Chemistry',
      description: 'Discover the fascinating world of atoms, molecules, and chemical reactions through comprehensive lessons on atomic structure, bonding, and more.',
      icon: 'i-heroicons-flask',
      teacher: {
        name: 'Aisha Rahman',
        title: 'MSc in Chemistry',
        image: 'https://i.pravatar.cc/150?img=5',
        rating: 4.5,
        bio: 'Passionate about making chemistry fun and approachable with hands-on experiments and clear explanations.'
      },
      pages: [
        { 
          id: 'ch1', 
          name: 'Chapter 1: Matter and Its Properties',
          description: 'Understanding the physical and chemical properties of matter and its states.',
          outcomes: [
            'Distinguish between physical and chemical properties',
            'Understand the states of matter and their interconversion',
            'Apply the kinetic theory of matter',
            'Identify common chemical and physical changes'
          ]
        },
        { 
          id: 'ch2', 
          name: 'Chapter 2: Atomic Structure',
          description: 'Exploring the structure of atoms, their properties, and the development of atomic models.',
          outcomes: [
            'Trace the historical development of atomic models',
            'Understand the structure of an atom',
            'Calculate atomic mass and isotopic abundance',
            'Interpret electron configurations'
          ]
        },
        { 
          id: 'ch3', 
          name: 'Chapter 3: Chemical Bonding',
          description: 'Study of different types of chemical bonds and molecular structures.',
          outcomes: [
            'Differentiate between ionic, covalent, and metallic bonds',
            'Draw Lewis structures for molecules',
            'Explain VSEPR theory and predict molecular shapes',
            'Understand bond polarity and intermolecular forces'
          ]
        }
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
          title: 'Physical vs Chemical Changes',
          description: 'Learn to identify and distinguish between physical and chemical changes in matter.',
          pageId: 'ch1',
          thumbnail: 'https://images.unsplash.com/photo-1554475900-0a0350e3fc7b',
          duration: 1230, // in seconds
          publishedAt: '2023-09-04',
          views: 5900,
          isNew: false,
          isFeatured: false
        },
        {
          id: 'chem3',
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
    }
    // Additional subjects would be defined here
  };
  
  return details[subjectId.value] || {
    title: 'Subject Not Found',
    description: 'The requested subject information could not be found.',
    icon: 'i-heroicons-question-mark-circle',
    teacher: {
      name: 'Not Available',
      title: '',
      image: 'https://via.placeholder.com/150',
      rating: 0,
      bio: 'No teacher information available.'
    },
    pages: [],
    videos: []
  };
});

// Extract subject details
const subjectTitle = computed(() => subjectDetails.value.title);
const subjectDescription = computed(() => subjectDetails.value.description);
const subjectIcon = computed(() => subjectDetails.value.icon);
const subjectTeacher = computed(() => subjectDetails.value.teacher);
const subjectPages = computed(() => subjectDetails.value.pages);
const subjectVideos = computed(() => subjectDetails.value.videos);

// Computed values for display
const totalVideos = computed(() => subjectVideos.value.length);
const totalChapters = computed(() => subjectPages.value.length);

// Get current page details
const currentPage = computed(() => {
  if (!selectedPage.value) return null;
  return subjectPages.value.find(page => page.id === selectedPage.value);
});

// Filtered videos based on selected page and search
const filteredVideos = computed(() => {
  let videos = [...subjectVideos.value];
  
  // Filter by page/chapter
  if (selectedPage.value) {
    videos = videos.filter(video => video.pageId === selectedPage.value);
  }
  
  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    videos = videos.filter(video => 
      video.title.toLowerCase().includes(query) ||
      video.description.toLowerCase().includes(query)
    );
  }
  
  // Apply sorting
  switch (sortBy.value) {
    case 'newest':
      return videos.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
    case 'oldest':
      return videos.sort((a, b) => new Date(a.publishedAt) - new Date(b.publishedAt));
    case 'views':
      return videos.sort((a, b) => b.views - a.views);
    case 'title_asc':
      return videos.sort((a, b) => a.title.localeCompare(b.title));
    case 'title_desc':
      return videos.sort((a, b) => b.title.localeCompare(a.title));
    default:
      return videos;
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
  }
]);

// Set initial page selection
onMounted(() => {
  // Select the first page by default
  if (subjectPages.value.length > 0) {
    selectedPage.value = subjectPages.value[0].id;
  }
});

// Methods
function selectPage(pageId) {
  selectedPage.value = pageId;
}

function resetFilters() {
  searchQuery.value = '';
  sortBy.value = 'newest';
  // Default to first page if there is one
  if (subjectPages.value.length > 0) {
    selectedPage.value = subjectPages.value[0].id;
  }
}

function navigateToVideo(videoId) {
  router.push(`/online-classes/${classType.value}/${category.value}/${subjectId.value}/${videoId}`);
}

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

function getCategoryColor(categoryValue) {
  switch (categoryValue) {
    case 'science': return 'green';
    case 'humanities': return 'amber';
    case 'commerce': return 'blue';
    default: return 'gray';
  }
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;  
  overflow: hidden;
}
</style>
