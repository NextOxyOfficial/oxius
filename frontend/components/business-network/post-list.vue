<template>
    <div class="space-y-4">
      <div 
        v-for="(post, index) in posts" 
        :key="post.id"
        class="transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-md"
        :style="{
          animationDelay: `${index * 0.05}s`,
          animation: 'fadeIn 0.5s ease-out forwards'
        }"
      >
        <BusinessNetworkPostCard 
          :post="post" 
          @update:post="updatePost($event, index)" 
        />
      </div>
  
      <div v-if="loading" class="flex justify-center py-6">
        <LoaderIcon class="h-6 w-6 animate-spin text-blue-500" />
      </div>
  
      <div v-if="!loading && posts.length === 0" class="flex flex-col items-center justify-center py-12 text-center">
        <p class="text-gray-500 mb-2">No posts available</p>
        <button 
          class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors"
          @click="loadPosts"
        >
          Refresh
        </button>
      </div>
    </div>
  </template>
  
  <script setup>
  

import { Loader as LoaderIcon } from 'lucide-vue-next';
  
  
  const props = defineProps({
    filter: {
      type: Object,
      default: () => ({})
    }
  });
  
  const { getPosts } = usePost();
  
  const posts = ref([]);
  const loading = ref(false);
  const page = ref(1);
  const hasMore = ref(true);
  const isMounted = ref(false);
  
  // Load posts with optional filtering
  const loadPosts = async () => {
    if (loading.value || !hasMore.value) return;
    
    loading.value = true;
    
    try {
      const newPosts = await getPosts({
        page: page.value,
        limit: 10,
        ...props.filter
      });
      
      if (newPosts.length === 0) {
        hasMore.value = false;
      } else {
        posts.value = [...posts.value, ...newPosts];
        page.value++;
      }
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      loading.value = false;
    }
  };
  
  // Update a post in the list
  const updatePost = (updatedPost, index) => {
    posts.value[index] = updatedPost;
  };
  
  // Handle infinite scroll
  const handleScroll = () => {
    if (!isMounted.value) return;
    const scrollPosition = window.scrollY + window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight;
    
    // Load more posts when user scrolls near the bottom
    if (scrollPosition > documentHeight - 500 && !loading.value && hasMore.value) {
      loadPosts();
    }
  };
  
  // Lifecycle hooks
  onMounted(() => {
    loadPosts();
    window.addEventListener('scroll', handleScroll);
    isMounted.value = true;
  });
  
  onUnmounted(() => {
    window.removeEventListener('scroll', handleScroll);
    isMounted.value = false;
  });
  </script>
  
  <style scoped>
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  </style>