<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <!-- Background overlay -->
        <div class="fixed inset-0 bg-black/50 backdrop-blur-sm transition-opacity" @click="close"></div>
  
        <!-- Modal panel -->
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="w-full">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title">
                    Likes
                  </h3>
                  <button 
                    @click="close" 
                    class="rounded-full p-1 hover:bg-gray-100 transition-colors"
                  >
                    <XIcon class="h-5 w-5 text-gray-500" />
                  </button>
                </div>
                
                <div class="mt-2">
                  <div v-if="loading" class="flex justify-center py-6">
                    <LoaderIcon class="h-6 w-6 animate-spin text-blue-500" />
                  </div>
                  
                  <div v-else-if="likes.length === 0" class="py-8 text-center">
                    <HeartIcon class="h-12 w-12 text-gray-300 mx-auto mb-3" />
                    <p class="text-gray-500">No likes yet</p>
                  </div>
                  
                  <ul v-else class="divide-y divide-gray-200 max-h-96 overflow-y-auto">
                    <li v-for="user in likes" :key="user.id" class="py-3 flex items-center justify-between">
                      <div class="flex items-center">
                        <div class="relative">
                          <img 
                            :src="user.avatar || '/images/placeholder.jpg?height=40&width=40'" 
                            :alt="user.fullName" 
                            class="h-10 w-10 rounded-full object-cover"
                          />
                          <div v-if="user.verified" class="absolute -right-0.5 -bottom-0.5 bg-blue-500 text-white rounded-full p-0.5">
                            <CheckIcon class="h-2.5 w-2.5" />
                          </div>
                        </div>
                        <div class="ml-3">
                          <p class="text-sm font-medium text-gray-900">{{ user.fullName }}</p>
                          <p class="text-xs text-gray-500">@{{ user.username || user.id }}</p>
                        </div>
                      </div>
                      <button 
                        v-if="user.id !== currentUserId"
                        @click="toggleFollow(user)"
                        :class="[
                          'text-xs px-3 py-1 rounded-full transition-colors',
                          user.isFollowing 
                            ? 'bg-gray-200 text-gray-800 hover:bg-gray-300' 
                            : 'bg-blue-500 text-white hover:bg-blue-600'
                        ]"
                      >
                        {{ user.isFollowing ? 'Following' : 'Follow' }}
                      </button>
                      <span v-else class="text-xs text-gray-400 px-3">You</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, watch, onMounted, defineProps, defineEmits } from 'vue';
  import { X as XIcon, Heart as HeartIcon, Check as CheckIcon, Loader as LoaderIcon } from 'lucide-vue-next';
  
  const props = defineProps({
    isOpen: {
      type: Boolean,
      default: false
    },
    postId: {
      type: [String, Number],
      default: null
    }
  });
  
  const emit = defineEmits(['close', 'follow']);
  
  const likes = ref([]);
  const loading = ref(false);
  const currentUserId = ref('current-user'); // This would come from your auth system
  
  // Watch for modal opening to fetch likes
  watch(() => props.isOpen, (newVal) => {
    if (newVal && props.postId) {
      fetchLikes();
    }
  });
  
  // Watch for postId changes to refetch likes if modal is open
  watch(() => props.postId, (newVal) => {
    if (props.isOpen && newVal) {
      fetchLikes();
    }
  });
  
  // Fetch likes when component mounts if modal is open
  onMounted(() => {
    if (props.isOpen && props.postId) {
      fetchLikes();
    }
  });
  
  // Fetch likes for the post
  const fetchLikes = async () => {
    if (!props.postId) return;
    
    loading.value = true;
    
    try {
      // In a real app, this would be an API call
      // Simulating API call with setTimeout
      await new Promise(resolve => setTimeout(resolve, 800));
      
      // Mock data - replace with actual API call
      likes.value = [
        { 
          id: 'user-1', 
          fullName: 'Emma Johnson', 
          username: 'emmaj', 
          avatar: '/images/placeholder.jpg?height=40&width=40', 
          verified: true,
          isFollowing: true 
        },
        { 
          id: 'user-2', 
          fullName: 'Liam Smith', 
          username: 'liamsmith', 
          avatar: '/images/placeholder.jpg?height=40&width=40', 
          verified: false,
          isFollowing: false 
        },
        { 
          id: 'current-user', 
          fullName: 'You', 
          username: 'yourusername', 
          avatar: '/images/placeholder.jpg?height=40&width=40', 
          verified: true,
          isFollowing: false 
        },
        { 
          id: 'user-3', 
          fullName: 'Olivia Williams', 
          username: 'oliviaw', 
          avatar: '/images/placeholder.jpg?height=40&width=40', 
          verified: true,
          isFollowing: false 
        },
        { 
          id: 'user-4', 
          fullName: 'Noah Brown', 
          username: 'noahb', 
          avatar: '/images/placeholder.jpg?height=40&width=40', 
          verified: false,
          isFollowing: true 
        }
      ];
    } catch (error) {
      console.error('Error fetching likes:', error);
    } finally {
      loading.value = false;
    }
  };
  
  // Toggle follow status for a user
  const toggleFollow = (user) => {
    user.isFollowing = !user.isFollowing;
    emit('follow', { userId: user.id, isFollowing: user.isFollowing });
  };
  
  // Close the modal
  const close = () => {
    emit('close');
  };
  </script>
  
  <style scoped>
  /* Optional: Add any component-specific styles here */
  </style>