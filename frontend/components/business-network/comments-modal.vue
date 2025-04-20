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
                    Comments
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
                  
                  <div v-else-if="comments.length === 0" class="py-8 text-center">
                    <MessageCircleIcon class="h-12 w-12 text-gray-300 mx-auto mb-3" />
                    <p class="text-gray-500">No comments yet</p>
                    <p class="text-gray-400 text-sm mt-1">Be the first to comment</p>
                  </div>
                  
                  <ul v-else class="divide-y divide-gray-100 max-h-80 overflow-y-auto mb-4">
                    <li v-for="comment in comments" :key="comment.id" class="py-3">
                      <div class="flex space-x-3">
                        <div class="flex-shrink-0 relative">
                          <img 
                            :src="comment.user.avatar || '/images/placeholder.jpg?height=40&width=40'" 
                            :alt="comment.user.fullName" 
                            class="h-9 w-9 rounded-full object-cover"
                          />
                          <div v-if="comment.user.verified" class="absolute -right-0.5 -bottom-0.5 bg-blue-500 text-white rounded-full p-0.5">
                            <CheckIcon class="h-2 w-2" />
                          </div>
                        </div>
                        <div class="flex-1 min-w-0">
                          <div class="bg-gray-50 rounded-lg p-3 relative">
                            <div class="flex items-center justify-between mb-1">
                              <p class="text-sm font-medium text-gray-900">
                                {{ comment.user.fullName }}
                                <span v-if="comment.user.id === currentUserId" class="text-xs text-gray-400 ml-1">(You)</span>
                              </p>
                              <div class="flex items-center">
                                <span class="text-xs text-gray-500">{{ formatTimeAgo(comment.timestamp) }}</span>
                                <button 
                                  v-if="comment.user.id === currentUserId"
                                  @click="deleteComment(comment.id)" 
                                  class="ml-2 text-gray-400 hover:text-gray-600"
                                >
                                  <TrashIcon class="h-3.5 w-3.5" />
                                </button>
                              </div>
                            </div>
                            <p class="text-sm text-gray-700 whitespace-pre-line">{{ comment.text }}</p>
                            <div class="mt-2 flex items-center space-x-4">
                              <button 
                                @click="toggleLike(comment)"
                                class="flex items-center text-xs text-gray-500 hover:text-gray-700"
                              >
                                <HeartIcon 
                                  :class="[
                                    'h-3.5 w-3.5 mr-1', 
                                    comment.isLiked ? 'text-red-500 fill-red-500' : 'text-gray-400'
                                  ]" 
                                />
                                {{ comment.likeCount || '' }}
                              </button>
                              <button 
                                @click="replyToComment(comment)"
                                class="flex items-center text-xs text-gray-500 hover:text-gray-700"
                              >
                                <ReplyIcon class="h-3.5 w-3.5 mr-1 text-gray-400" />
                                Reply
                              </button>
                            </div>
                          </div>
                          
                          <!-- Nested replies -->
                          <div v-if="comment.replies && comment.replies.length > 0" class="mt-2 ml-4">
                            <div v-for="reply in comment.replies" :key="reply.id" class="flex space-x-3 mt-2">
                              <div class="flex-shrink-0 relative">
                                <img 
                                  :src="reply.user.avatar || '/images/placeholder.jpg?height=32&width=32'" 
                                  :alt="reply.user.fullName" 
                                  class="h-7 w-7 rounded-full object-cover"
                                />
                              </div>
                              <div class="flex-1 min-w-0">
                                <div class="bg-gray-50 rounded-lg p-2 relative">
                                  <div class="flex items-center justify-between">
                                    <p class="text-xs font-medium text-gray-900">
                                      {{ reply.user.fullName }}
                                      <span v-if="reply.user.id === currentUserId" class="text-xs text-gray-400 ml-1">(You)</span>
                                    </p>
                                    <span class="text-xs text-gray-500">{{ formatTimeAgo(reply.timestamp) }}</span>
                                  </div>
                                  <p class="text-xs text-gray-700">{{ reply.text }}</p>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </li>
                  </ul>
                </div>
                
                <!-- Comment input -->
                <div class="mt-4 relative">
                  <div class="flex items-start space-x-3">
                    <div class="flex-shrink-0">
                      <img 
                        :src="currentUserAvatar || '/images/placeholder.jpg?height=40&width=40'" 
                        alt="Your avatar" 
                        class="h-9 w-9 rounded-full object-cover"
                      />
                    </div>
                    <div class="flex-1 min-w-0">
                      <div 
                        class="relative rounded-lg border border-gray-300 shadow-sm focus-within:border-blue-500 focus-within:ring-1 focus-within:ring-blue-500"
                        :class="{ 'border-blue-500 ring-1 ring-blue-500': isCommentFocused }"
                      >
                        <textarea
                          ref="commentInput"
                          v-model="newComment"
                          rows="2"
                          placeholder="Write a comment..."
                          class="block w-full resize-none border-0 bg-transparent py-2 px-3 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"
                          @focus="isCommentFocused = true"
                          @blur="isCommentFocused = false"
                        ></textarea>
                        
                        <!-- Emoji picker button -->
                        <div class="absolute bottom-1 right-2 flex space-x-1">
                          <button 
                            type="button" 
                            @click="toggleEmojiPicker"
                            class="rounded-full p-1 text-gray-400 hover:text-gray-500"
                          >
                            <SmileIcon class="h-5 w-5" />
                          </button>
                        </div>
                      </div>
                      
                      <!-- Emoji picker -->
                      <div 
                        v-if="showEmojiPicker" 
                        class="absolute mt-1 right-0 z-10 bg-white rounded-lg shadow-lg border border-gray-200 p-2 w-64"
                      >
                        <div class="grid grid-cols-8 gap-1">
                          <button
                            v-for="(emoji, index) in commonEmojis"
                            :key="index"
                            class="w-7 h-7 flex items-center justify-center hover:bg-gray-100 rounded text-lg"
                            @click="addEmoji(emoji)"
                          >
                            {{ emoji }}
                          </button>
                        </div>
                      </div>
                      
                      <div class="mt-2 flex justify-between items-center">
                        <div class="text-xs text-gray-500" v-if="replyingTo">
                          Replying to <span class="font-medium">{{ replyingTo.user.fullName }}</span>
                          <button @click="cancelReply" class="ml-1 text-blue-500 hover:underline">Cancel</button>
                        </div>
                        <div class="flex-1"></div>
                        <button
                          @click="submitComment"
                          :disabled="!newComment.trim() || isSubmitting"
                          :class="[
                            'px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                            newComment.trim() && !isSubmitting
                              ? 'bg-blue-500 text-white hover:bg-blue-600'
                              : 'bg-gray-200 text-gray-500 cursor-not-allowed'
                          ]"
                        >
                          <span v-if="isSubmitting" class="flex items-center">
                            <LoaderIcon class="animate-spin h-3 w-3 mr-2" />
                            Posting...
                          </span>
                          <span v-else>Post</span>
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
  import { ref, watch, onMounted, nextTick, defineProps, defineEmits } from 'vue';
  import { 
    X as XIcon, 
    MessageCircle as MessageCircleIcon, 
    Check as CheckIcon, 
    Heart as HeartIcon,
    Reply as ReplyIcon,
    Trash as TrashIcon,
    Smile as SmileIcon,
    Loader as LoaderIcon
  } from 'lucide-vue-next';
  
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
  
  const emit = defineEmits(['close', 'comment-added', 'comment-deleted']);
  
  const comments = ref([]);
  const loading = ref(false);
  const newComment = ref('');
  const isSubmitting = ref(false);
  const commentInput = ref(null);
  const currentUserId = ref('current-user'); // This would come from your auth system
  const currentUserAvatar = ref('/images/placeholder.jpg?height=40&width=40'); // This would come from your auth system
  const isCommentFocused = ref(false);
  const showEmojiPicker = ref(false);
  const replyingTo = ref(null);
  
  // Common emojis for quick access
  const commonEmojis = [
    "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", 
    "👍", "👎", "👏", "🙌", "🤝", "👊", "✌️", "🤞", "🤟", "🤘", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "💔", "❣️", "💕"
  ];
  
  // Watch for modal opening to fetch comments
  watch(() => props.isOpen, (newVal) => {
    if (newVal && props.postId) {
      fetchComments();
      nextTick(() => {
        commentInput.value?.focus();
      });
    } else {
      // Reset state when modal closes
      newComment.value = '';
      replyingTo.value = null;
      showEmojiPicker.value = false;
    }
  });
  
  // Watch for postId changes to refetch comments if modal is open
  watch(() => props.postId, (newVal) => {
    if (props.isOpen && newVal) {
      fetchComments();
    }
  });
  
  // Fetch comments when component mounts if modal is open
  onMounted(() => {
    if (props.isOpen && props.postId) {
      fetchComments();
    }
    
    // Close emoji picker when clicking outside
    document.addEventListener('click', handleClickOutside);
  });
  
  // Fetch comments for the post
  const fetchComments = async () => {
    if (!props.postId) return;
    
    loading.value = true;
    
    try {
      // In a real app, this would be an API call
      // Simulating API call with setTimeout
      await new Promise(resolve => setTimeout(resolve, 800));
      
      // Mock data - replace with actual API call
      comments.value = [
        {
          id: 'comment-1',
          user: {
            id: 'user-1',
            fullName: 'Emma Johnson',
            avatar: '/images/placeholder.jpg?height=40&width=40',
            verified: true
          },
          text: 'This is really insightful! I\'ve been looking for this kind of analysis for a while now.',
          timestamp: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
          likeCount: 5,
          isLiked: false,
          replies: [
            {
              id: 'reply-1',
              user: {
                id: 'current-user',
                fullName: 'You',
                avatar: '/images/placeholder.jpg?height=40&width=40'
              },
              text: 'Thanks Emma! Glad you found it useful.',
              timestamp: new Date(Date.now() - 1800000).toISOString() // 30 minutes ago
            }
          ]
        },
        {
          id: 'comment-2',
          user: {
            id: 'current-user',
            fullName: 'You',
            avatar: '/images/placeholder.jpg?height=40&width=40',
            verified: true
          },
          text: 'Great post! I especially liked the part about market trends.',
          timestamp: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
          likeCount: 2,
          isLiked: true,
          replies: []
        },
        {
          id: 'comment-3',
          user: {
            id: 'user-3',
            fullName: 'Olivia Williams',
            avatar: '/images/placeholder.jpg?height=40&width=40',
            verified: false
          },
          text: 'Could you elaborate more on the second point? I\'m not sure I fully understand the implications.',
          timestamp: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
          likeCount: 0,
          isLiked: false,
          replies: []
        }
      ];
    } catch (error) {
      console.error('Error fetching comments:', error);
    } finally {
      loading.value = false;
    }
  };
  
  // Format timestamp to relative time (e.g., "2h ago")
  const formatTimeAgo = (dateString) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);
  
    if (diffInSeconds < 60) {
      return `${diffInSeconds}s ago`;
    }
  
    const diffInMinutes = Math.floor(diffInSeconds / 60);
    if (diffInMinutes < 60) {
      return `${diffInMinutes}m ago`;
    }
  
    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) {
      return `${diffInHours}h ago`;
    }
  
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 30) {
      return `${diffInDays}d ago`;
    }
  
    const diffInMonths = Math.floor(diffInDays / 30);
    return `${diffInMonths}mo ago`;
  };
  
  // Toggle like on a comment
  const toggleLike = (comment) => {
    comment.isLiked = !comment.isLiked;
    if (comment.isLiked) {
      comment.likeCount = (comment.likeCount || 0) + 1;
    } else {
      comment.likeCount = Math.max(0, (comment.likeCount || 0) - 1);
    }
  };
  
  // Reply to a comment
  const replyToComment = (comment) => {
    replyingTo.value = comment;
    nextTick(() => {
      commentInput.value?.focus();
    });
  };
  
  // Cancel reply
  const cancelReply = () => {
    replyingTo.value = null;
  };
  
  // Toggle emoji picker
  const toggleEmojiPicker = (event) => {
    event.stopPropagation();
    showEmojiPicker.value = !showEmojiPicker.value;
  };
  
  // Handle click outside to close emoji picker
  const handleClickOutside = (event) => {
    if (showEmojiPicker.value && !event.target.closest('.emoji-picker') && !event.target.closest('button')) {
      showEmojiPicker.value = false;
    }
  };
  
  // Add emoji to comment
  const addEmoji = (emoji) => {
    newComment.value += emoji;
    showEmojiPicker.value = false;
    nextTick(() => {
      commentInput.value?.focus();
    });
  };
  
  // Submit a new comment
  const submitComment = async () => {
    if (!newComment.value.trim() || isSubmitting.value) return;
    
    isSubmitting.value = true;
    
    try {
      // In a real app, this would be an API call
      // Simulating API call with setTimeout
      await new Promise(resolve => setTimeout(resolve, 800));
      
      const commentData = {
        id: `comment-${Date.now()}`,
        user: {
          id: currentUserId.value,
          fullName: 'You',
          avatar: currentUserAvatar.value,
          verified: true
        },
        text: newComment.value.trim(),
        timestamp: new Date().toISOString(),
        likeCount: 0,
        isLiked: false,
        replies: []
      };
      
      if (replyingTo.value) {
        // Add as a reply to an existing comment
        const parentComment = comments.value.find(c => c.id === replyingTo.value.id);
        if (parentComment) {
          if (!parentComment.replies) {
            parentComment.replies = [];
          }
          
          const replyData = {
            id: `reply-${Date.now()}`,
            user: {
              id: currentUserId.value,
              fullName: 'You',
              avatar: currentUserAvatar.value
            },
            text: newComment.value.trim(),
            timestamp: new Date().toISOString()
          };
          
          parentComment.replies.push(replyData);
        }
        replyingTo.value = null;
      } else {
        // Add as a new comment
        comments.value.unshift(commentData);
      }
      
      // Emit event to parent component
      emit('comment-added', commentData);
      
      // Clear input
      newComment.value = '';
    } catch (error) {
      console.error('Error submitting comment:', error);
    } finally {
      isSubmitting.value = false;
    }
  };
  
  // Delete a comment
  const deleteComment = async (commentId) => {
    try {
      // In a real app, this would be an API call
      // Simulating API call with setTimeout
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Remove comment from list
      comments.value = comments.value.filter(comment => comment.id !== commentId);
      
      // Emit event to parent component
      emit('comment-deleted', commentId);
    } catch (error) {
      console.error('Error deleting comment:', error);
    }
  };
  
  // Close the modal
  const close = () => {
    emit('close');
  };
  </script>
  
  <style scoped>
  /* Optional: Add any component-specific styles here */
  </style>