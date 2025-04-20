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
                    Share Post
                  </h3>
                  <button 
                    @click="close" 
                    class="rounded-full p-1 hover:bg-gray-100 transition-colors"
                  >
                    <XIcon class="h-5 w-5 text-gray-500" />
                  </button>
                </div>
                
                <div class="mt-2">
                  <!-- Post preview -->
                  <div v-if="post" class="mb-4 p-3 bg-gray-50 rounded-lg">
                    <div class="flex items-center space-x-2 mb-2">
                      <img 
                        :src="post.author?.avatar || '/images/placeholder.jpg?height=32&width=32'" 
                        :alt="post.author?.fullName" 
                        class="h-6 w-6 rounded-full object-cover"
                      />
                      <span class="text-sm font-medium text-gray-900">{{ post.author?.fullName }}</span>
                    </div>
                    <p class="text-sm text-gray-700 line-clamp-2">{{ post.title }}</p>
                  </div>
                  
                  <!-- Share options -->
                  <div class="space-y-4">
                    <!-- Social media sharing -->
                    <div>
                      <h4 class="text-sm font-medium text-gray-700 mb-2">Share to social media</h4>
                      <div class="grid grid-cols-4 gap-2">
                        <button 
                          v-for="platform in socialPlatforms" 
                          :key="platform.name"
                          @click="shareTo(platform.name)"
                          class="flex flex-col items-center justify-center p-3 rounded-lg hover:bg-gray-50 transition-colors"
                        >
                          <component :is="platform.icon" class="h-6 w-6 mb-1" :class="platform.iconClass" />
                          <span class="text-xs">{{ platform.name }}</span>
                        </button>
                      </div>
                    </div>
                    
                    <!-- Copy link -->
                    <div>
                      <h4 class="text-sm font-medium text-gray-700 mb-2">Copy link</h4>
                      <div class="flex">
                        <input
                          type="text"
                          :value="shareUrl"
                          readonly
                          class="flex-1 min-w-0 block w-full px-3 py-2 rounded-l-md border border-gray-300 text-sm"
                        />
                        <button
                          @click="copyToClipboard"
                          class="inline-flex items-center px-3 py-2 border border-l-0 border-gray-300 bg-gray-50 text-sm font-medium rounded-r-md text-gray-700 hover:bg-gray-100"
                        >
                          <component :is="copied ? CheckIcon : CopyIcon" class="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                    
                    <!-- Share via email -->
                    <div>
                      <h4 class="text-sm font-medium text-gray-700 mb-2">Share via email</h4>
                      <div class="flex">
                        <input
                          v-model="emailRecipient"
                          type="email"
                          placeholder="Enter email address"
                          class="flex-1 min-w-0 block w-full px-3 py-2 rounded-l-md border border-gray-300 text-sm"
                        />
                        <button
                          @click="shareViaEmail"
                          :disabled="!isValidEmail"
                          :class="[
                            'inline-flex items-center px-3 py-2 border border-l-0 border-gray-300 text-sm font-medium rounded-r-md',
                            isValidEmail 
                              ? 'bg-blue-500 text-white hover:bg-blue-600 border-blue-500' 
                              : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                          ]"
                        >
                          <MailIcon class="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, computed, watch, defineProps, defineEmits } from 'vue';
  import { 
    X as XIcon, 
    Copy as CopyIcon,
    Check as CheckIcon,
    Mail as MailIcon,
    Twitter as TwitterIcon,
    Facebook as FacebookIcon,
    Linkedin as LinkedinIcon,
    MessageCircle as MessageCircleIcon
  } from 'lucide-vue-next';
  
  const props = defineProps({
    isOpen: {
      type: Boolean,
      default: false
    },
    postId: {
      type: [String, Number],
      default: null
    },
    post: {
      type: Object,
      default: null
    }
  });
  
  const emit = defineEmits(['close', 'share']);
  
  const copied = ref(false);
  const emailRecipient = ref('');
  const shareUrl = ref('');
  
  // Social media platforms
  const socialPlatforms = [
    { 
      name: 'Twitter', 
      icon: TwitterIcon, 
      iconClass: 'text-blue-400',
      url: (url) => `https://twitter.com/intent/tweet?url=${encodeURIComponent(url)}`
    },
    { 
      name: 'Facebook', 
      icon: FacebookIcon, 
      iconClass: 'text-blue-600',
      url: (url) => `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`
    },
    { 
      name: 'LinkedIn', 
      icon: LinkedinIcon, 
      iconClass: 'text-blue-700',
      url: (url) => `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`
    },
    { 
      name: 'Message', 
      icon: MessageCircleIcon, 
      iconClass: 'text-green-500',
      url: (url) => `sms:?body=${encodeURIComponent(`Check out this post: ${url}`)}`
    }
  ];
  
  // Validate email
  const isValidEmail = computed(() => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(emailRecipient.value);
  });
  
  // Watch for modal opening to set share URL
  watch(() => props.isOpen, (newVal) => {
    if (newVal && props.postId) {
      // In a real app, this would be a proper URL to the post
      shareUrl.value = `https://business-network.example/posts/${props.postId}`;
    }
  });
  
  // Watch for postId changes to update share URL if modal is open
  watch(() => props.postId, (newVal) => {
    if (props.isOpen && newVal) {
      shareUrl.value = `https://business-network.example/posts/${newVal}`;
    }
  });
  
  // Copy link to clipboard
  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl.value);
      copied.value = true;
      setTimeout(() => {
        copied.value = false;
      }, 2000);
    } catch (error) {
      console.error('Failed to copy text: ', error);
    }
  };
  
  // Share to social media
  const shareTo = (platform) => {
    const platformConfig = socialPlatforms.find(p => p.name === platform);
    if (platformConfig && platformConfig.url) {
      // In a real app, you might want to track this share event
      emit('share', { platform, url: shareUrl.value });
      
      // Open share URL in new window
      window.open(platformConfig.url(shareUrl.value), '_blank');
    }
  };
  
  // Share via email
  const shareViaEmail = () => {
    if (!isValidEmail.value) return;
    
    // In a real app, you might want to send this via your backend
    // For now, we'll just open the default mail client
    const subject = encodeURIComponent('Check out this post');
    const body = encodeURIComponent(`I thought you might be interested in this post: ${shareUrl.value}`);
    
    window.open(`mailto:${emailRecipient.value}?subject=${subject}&body=${body}`, '_blank');
    
    // Emit share event
    emit('share', { platform: 'email', recipient: emailRecipient.value, url: shareUrl.value });
    
    // Reset email field
    emailRecipient.value = '';
  };
  
  // Close the modal
  const close = () => {
    emit('close');
  };
  </script>
  
  <style scoped>
  /* Optional: Add any component-specific styles here */
  </style>