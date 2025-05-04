<template>
  <Transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="opacity-0 scale-95"
    enter-to-class="opacity-100 scale-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="opacity-100 scale-100"
    leave-to-class="opacity-0 scale-95"
  >
    <div
      v-if="modelValue && problem"
      class="fixed inset-0 z-50 flex items-center justify-center perspective-1000"
    >
      <!-- Enhanced backdrop with subtle blur effect -->
      <div
        class="absolute inset-0 bg-gradient-to-br from-slate-900/70 to-blue-900/70 backdrop-blur-md"
        @click="$emit('update:modelValue', false)"
      ></div>

      <!-- Modal with enhanced styling -->
      <div
        class="relative bg-white dark:bg-slate-800 rounded-xl shadow-2xl w-full max-w-3xl mx-4 max-h-[85vh] overflow-hidden border border-slate-100 dark:border-slate-700 animate-fade-in-up"
        @click.stop
      >
        <!-- Premium scrollbar styling -->
        <div class="px-4 sm:px-6 py-6 overflow-y-auto custom-scrollbar max-h-[85vh]">
          <!-- Problem Header with enhanced design -->
          <div class="flex justify-between items-start">
            <div class="flex items-center">
              <div
                class="h-12 w-12 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 shadow-sm relative glow-effect"
              >
                <div class="absolute inset-0 bg-gradient-to-br from-blue-400 to-violet-500 opacity-30"></div>
                <img
                  :src="problem.user_details?.image || '/placeholder.svg'"
                  :alt="problem.user_details?.name"
                  class="h-full w-full object-cover relative z-10"
                />
              </div>
              <div class="ml-3">
                <p class="text-md font-medium dark:text-white">
                  {{ problem.user_details?.name }}
                </p>
                <div class="flex items-center text-sm text-slate-500">
                  <Clock class="h-3 w-3 mr-1" />
                  <span>{{ formatTimeAgo(problem.created_at) }}</span>
                </div>
              </div>
            </div>

            <div class="flex items-center gap-1">
              <div v-if="isOwner" class="relative">
                <button
                  @click.stop="toggleMenu"
                  class="inline-flex items-center justify-center rounded-lg text-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-slate-100 dark:hover:bg-slate-700 h-8 w-8 p-0"
                >
                  <MoreHorizontal class="h-4 w-4 text-slate-600 dark:text-slate-300" />
                </button>

                <Transition
                  enter-active-class="transition duration-200 ease-out"
                  enter-from-class="opacity-0 scale-95"
                  enter-to-class="opacity-100 scale-100"
                  leave-active-class="transition duration-100 ease-in"
                  leave-from-class="opacity-100 scale-100"
                  leave-to-class="opacity-0 scale-95"
                >
                  <div
                    v-if="isMenuOpen"
                    class="absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-lg bg-white dark:bg-slate-800 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none dark:ring-slate-700 animate-fade-in-down"
                  >
                    <div class="py-1">
                      <button
                        class="flex w-full items-center px-4 py-2 text-md text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700"
                      >
                        <Edit class="h-4 w-4 mr-2" /> Edit Problem
                      </button>
                      <button
                        @click="$emit('delete')"
                        class="flex w-full items-center px-4 py-2 text-md text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
                      >
                        <Trash2 class="h-4 w-4 mr-2" /> Delete Problem
                      </button>
                    </div>
                  </div>
                </Transition>
              </div>
              <!-- Fixed X button - Made it larger and more visible -->
              <button
                @click.stop="$emit('update:modelValue', false)"
                class="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
                aria-label="Close"
              >
                <X class="h-5 w-5 text-slate-500 dark:text-slate-400" />
              </button>
            </div>
          </div>

          <!-- Problem Category & Payment - Enhanced styling -->
          <div class="flex flex-wrap gap-2 mt-4">
            <span
              class="inline-flex items-center rounded-full px-2.5 py-1 text-md font-medium bg-slate-100 dark:bg-slate-700 text-slate-800 dark:text-slate-200 shadow-sm"
            >
              {{ problem.category_details?.name }}
            </span>

            <span
              v-if="problem?.payment_option === 'paid'"
              class="inline-flex items-center rounded-full px-3 py-1 text-md font-medium transition-all border-0 bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
            >
              {{
                problem?.payment_amount > 0
                  ? `I can pay `
                  : "Paid Help"
              }}
              <span
                v-if="problem?.payment_amount > 0"
                class="inline-flex items-center"
              >
                <UIcon name="i-mdi-currency-bdt" class="text-emerald-600 dark:text-emerald-400" />
                {{ problem?.payment_amount }}
              </span>
            </span>
            <span
              v-else
              class="inline-flex items-center rounded-full px-3 py-1 text-md font-medium bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
            >
              I need help for free
            </span>

            <span
              v-if="problem.status === 'solved'"
              class="inline-flex items-center rounded-full px-3 py-1 text-md font-medium bg-gradient-to-r from-emerald-500 to-green-500 text-white shadow-sm"
            >
              <CheckCircle class="h-3 w-3 mr-1" />
              Solved
            </span>
          </div>

          <!-- Problem Title & Content with improved typography -->
          <h1 class="text-xl mt-4 font-bold text-slate-900 dark:text-white">
            {{ problem.title }}
          </h1>
          <div class="mt-3 text-slate-700 dark:text-slate-300 whitespace-pre-line leading-relaxed prose dark:prose-invert max-w-none">
            {{ problem.description }}
          </div>

          <!-- Problem Stats - Enhanced styling -->
          <div
            class="mt-6 flex items-center justify-between border-t border-b border-slate-200 dark:border-slate-700 py-3"
          >
            <div class="flex items-center space-x-4">
              <span class="text-sm text-slate-600 dark:text-slate-400 flex items-center group">
                <MessageSquare class="h-4 w-4 mr-1.5 group-hover:text-blue-500 transition-colors" />
                <span class="group-hover:text-blue-500 transition-colors">
                  {{ problem.mindforce_comments?.length || 0 }} Advices
                </span>
              </span>

              <span class="text-sm text-slate-600 dark:text-slate-400 flex items-center">
                <Eye class="h-4 w-4 mr-1.5" />
                {{ problem?.views || 0 }}
              </span>
            </div>
            
            <!-- Mark as Solved button with premium styling -->
            <button
              v-if="isOwner && problem.status !== 'solved'"
              @click="$emit('mark-as-solved')"
              class="inline-flex items-center rounded-md px-3 py-1.5 text-sm font-medium transition-all bg-gradient-to-r from-emerald-500 to-green-500 hover:from-emerald-600 hover:to-green-600 text-white shadow-sm hover:shadow-lg transform hover:-translate-y-0.5 active:translate-y-0"
            >
              <CheckCircle class="h-4 w-4 mr-1.5" />
              Mark as Solved
            </button>
          </div>

          <!-- Comments Section - Enhanced styling -->
          <div class="mt-6">
            <h3 class="text-lg font-medium mb-4 text-slate-700 dark:text-slate-300 flex items-center">
              <MessageSquare class="h-5 w-5 mr-2 text-blue-500" />
              Advice ({{ problem.mindforce_comments?.length || 0 }})
            </h3>

            <!-- Comment List with enhanced styling -->
            <div class="space-y-4">
              <div
                v-if="problem.comments?.length > 0"
                class="space-y-3"
              >
                <div
                  v-for="comment in problem.comments"
                  :key="comment.id"
                  :class="[
                    'px-3 py-3 sm:py-4 rounded-lg transition-all transform hover:scale-[1.01]',
                    comment.is_solved
                      ? 'bg-gradient-to-br from-emerald-50 to-green-50 dark:from-emerald-900/20 dark:to-green-900/20 border border-emerald-100 dark:border-emerald-900/30 shadow-sm'
                      : 'bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:hover:bg-slate-800 border border-slate-100 dark:border-slate-700/50',
                  ]"
                >
                  <div class="flex justify-between">
                    <div class="flex items-center">
                      <div
                        class="h-10 w-10 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 shadow-sm"
                      >
                        <img
                          :src="comment?.author_details?.image || '/placeholder.svg'"
                          :alt="comment?.author_details?.name"
                          class="h-full w-full object-cover"
                        />
                      </div>
                      <div class="ml-3">
                        <div class="flex items-center">
                          <p class="font-medium text-slate-800 dark:text-slate-200">
                            {{ comment?.author_details?.name }}
                          </p>
                          <span
                            v-if="comment.is_solved"
                            class="ml-2 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-gradient-to-r from-emerald-500 to-green-500 text-white shadow-sm"
                          >
                            <CheckCircle class="h-3 w-3 mr-1" /> Solution
                          </span>
                        </div>
                        <p class="text-sm text-slate-500 dark:text-slate-400">
                          {{ formatTimeAgo(comment.created_at) }}
                        </p>
                      </div>
                    </div>

                    <button>
                      v-if="isOwner && problem.status !== 'solved'"
                      @click="$emit('mark-solution', comment.id)"
                      :class="[
                        'inline-flex items-center justify-center rounded-md text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-8 px-3 transform hover:-translate-y-0.5 active:translate-y-0',
                        comment.is_solved
                          ? 'bg-gradient-to-r from-emerald-500 to-green-500 text-white shadow-sm'
                          : 'border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300',
                      ]"
                    </button>
                      <CheckCircle class="h-3 w-3 mr-1" />
                  </div>

                  <p class="mt-2 sm:mt-3 text-md text-slate-700 dark:text-slate-300 leading-relaxed">
                    {{ comment.content }}
                  </p>
                </div>
              </div>

              <div
                v-else
                class="flex flex-col items-center justify-center py-12 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-dashed border-slate-200 dark:border-slate-700"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="40"
                  height="40"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  class="text-slate-400 dark:text-slate-500 mb-3"
                >
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="8" y1="12" x2="16" y2="12"></line>
                </svg>
                <p class="text-slate-500 dark:text-slate-400">
                  No advice have been posted yet. Be the first to help!
                </p>
              </div>
            </div>

            <!-- Add Comment with premium styling -->
            <div class="mt-8" v-if="currentUserId && problem.status !== 'solved'">
              <h4 class="text-md font-medium mb-2 text-slate-700 dark:text-slate-300 flex items-center">
                <Send class="h-4 w-4 mr-2 text-blue-500" />
                Write an advice
              </h4>
              <textarea
                v-model="newComment"
                placeholder="Share your solution or ask for clarification..."
                class="flex w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-3 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 dark:focus-visible:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all resize-none"
                rows="3"
              ></textarea>
              <div class="flex justify-end mt-3 mb-10">
                <button
                  @click="submitComment"
                  :disabled="!newComment.trim() || isSubmittingComment"
                  :class="[
                    'inline-flex items-center justify-center rounded-lg text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2',
                    !newComment.trim() || isSubmittingComment
                      ? 'bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400'
                      : 'bg-gradient-to-r from-blue-500 to-violet-500 hover:from-blue-600 hover:to-violet-600 text-white shadow-sm hover:shadow-lg transform hover:-translate-y-0.5 active:translate-y-0'
                  ]"
                >
                  <span v-if="isSubmittingComment" class="flex items-center">
                    <span class="loading-spinner mr-2"></span>
                    Submitting...
                  </span>
                  <span v-else class="flex items-center">
                    <Send class="h-4 w-4 mr-1.5" />
                    Submit
                  </span>
                </button>
              </div>
            </div>

            <!-- Message for solved problems with enhanced styling -->
            <div v-else-if="problem.status === 'solved'" class="mt-8 p-4 bg-gradient-to-br from-emerald-50 to-green-50 dark:from-emerald-900/20 dark:to-green-900/20 rounded-lg border border-emerald-100 dark:border-emerald-900/30 mb-10">
              <div class="flex items-center">
                <div class="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-full mr-3">
                  <CheckCircle class="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
                </div>
                <div>
                  <h4 class="text-md font-medium text-emerald-800 dark:text-emerald-400">This problem has been marked as solved</h4>
                  <p class="mt-1 text-sm text-emerald-700 dark:text-emerald-500">
                    New advice cannot be added to solved problems.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, computed, onMounted, watch } from "vue";
import {
  X,
  Send,
  MessageSquare,
  CheckCircle,
  MoreHorizontal,
  Trash2,
  Eye,
  Edit,
  Clock
} from "lucide-vue-next";

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  problem: {
    type: Object,
    default: () => ({})
  },
  currentUserId: {
    type: Number,
    default: null
  },
  isSubmittingComment: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits([
  'update:modelValue',
  'submit-comment',
  'mark-as-solved',
  'mark-solution',
  'delete',
  'add-comment'  // Add this event to support the parent component
]);

// State management
const newComment = ref("");
const isMenuOpen = ref(false);

// Computed properties
const isOwner = computed(() => {
  return props.currentUserId === props.problem?.user;
});

// Methods
const toggleMenu = () => {
  isMenuOpen.value = !isMenuOpen.value;
};

const submitComment = () => {
  if (newComment.value.trim()) {
    // Update to emit both events for compatibility
    emit('submit-comment', { content: newComment.value });
    emit('add-comment', newComment.value);
    // Reset comment after submission
    if (!props.isSubmittingComment) {
      newComment.value = "";
    }
  }
};

const formatTimeAgo = (dateString) => {
  if (!dateString) return "";
  
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now - date) / 1000);
  
  if (diffInSeconds < 60) {
    return "just now";
  } else if (diffInSeconds < 3600) {
    const minutes = Math.floor(diffInSeconds / 60);
    return `${minutes} ${minutes === 1 ? "minute" : "minutes"} ago`;
  } else if (diffInSeconds < 86400) {
    const hours = Math.floor(diffInSeconds / 3600);
    return `${hours} ${hours === 1 ? "hour" : "hours"} ago`;
  } else if (diffInSeconds < 604800) {
    const days = Math.floor(diffInSeconds / 86400);
    return `${days} ${days === 1 ? "day" : "days"} ago`;
  } else {
    // Format as date if more than a week
    return date.toLocaleDateString();
  }
};

// Close dropdown when clicking outside
const handleClickOutside = (event) => {
  if (isMenuOpen.value) {
    isMenuOpen.value = false;
  }
};

// Handle escape key to close modal
const handleKeydown = (event) => {
  if (event.key === 'Escape' && props.modelValue) {
    emit('update:modelValue', false);
  }
};

// Add event listeners
onMounted(() => {
  document.addEventListener('click', handleClickOutside);
  document.addEventListener('keydown', handleKeydown);
});

// Watch for modal opening to reset state
watch(() => props.modelValue, (newVal) => {
  if (newVal) {
    newComment.value = "";
    isMenuOpen.value = false;
  }
});
</script>

<style scoped>
/* Custom scrollbar styling */
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background-color: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.15);
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.25);
}

/* Dark mode scrollbar */
@media (prefers-color-scheme: dark) {
  .custom-scrollbar::-webkit-scrollbar-track {
    background-color: rgba(255, 255, 255, 0.05);
  }

  .custom-scrollbar::-webkit-scrollbar-thumb {
    background-color: rgba(255, 255, 255, 0.15);
  }

  .custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background-color: rgba(255, 255, 255, 0.25);
  }
}

/* Animations */
.animate-fade-in-up {
  animation: fadeInUp 0.3s ease-out forwards;
}

.animate-fade-in-down {
  animation: fadeInDown 0.2s ease-out forwards;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Glowing effect for profile images */
.glow-effect {
  transition: all 0.3s ease;
}

.glow-effect:hover::before {
  content: '';
  position: absolute;
  inset: -4px;
  background: linear-gradient(45deg, #3b82f6, #8b5cf6, #3b82f6);
  border-radius: 50%;
  z-index: 0;
  animation: rotate 2s linear infinite;
  opacity: 0.7;
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

/* Perspective for 3D effects */
.perspective-1000 {
  perspective: 1000px;
}

/* Loading spinner */
.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid #3b82f6;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>