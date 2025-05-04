<template>
  <Transition>
    <div
      v-if="modelValue && problem"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <!-- Backdrop with blur -->
      <div
        class="absolute inset-0 bg-black/50 backdrop-blur-sm"
        @click="$emit('update:modelValue', false)"
      ></div>

      <!-- Modal -->
      <div
        class="relative bg-white rounded-xl shadow-xl w-full max-w-3xl mx-4 max-h-[80vh] overflow-y-auto"
      >
        <!-- Close button (X) -->
        <div class="px-2 sm:px-6 py-6">
          <!-- Problem Header -->
          <div class="flex justify-between items-start">
            <div class="flex items-center">
              <div
                class="h-12 w-12 rounded-full overflow-hidden border-2 border-white shadow-sm"
              >
                <img
                  :src="problem.user_details?.image || '/placeholder.svg'"
                  :alt="problem.user_details?.name"
                  class="h-full w-full object-cover"
                />
              </div>
              <div class="ml-3">
                <p class="text-md font-medium">
                  {{ problem.user_details?.name }}
                </p>
                <div class="flex items-center text-sm text-gray-500">
                  <Clock class="h-3 w-3 mr-1" />
                  <span>{{ formatTimeAgo(problem.created_at) }}</span>
                </div>
              </div>
            </div>

            <div v-if="isOwner" class="relative">
              <div class="flex items-center gap-1">
                <button
                  @click="toggleMenu"
                  class="inline-flex items-center justify-center rounded-lg text-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-gray-100 h-8 w-8 p-0"
                >
                  <MoreHorizontal class="h-4 w-4" />
                </button>
                <button
                  @click="$emit('update:modelValue', false)"
                  class="p-1 rounded-full hover:bg-gray-100 transition-colors"
                  aria-label="Close"
                >
                  <X class="h-5 w-5 text-gray-500" />
                </button>
              </div>

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
                  class="absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                >
                  <div class="py-1">
                    <button
                      class="flex w-full items-center px-4 py-2 text-md text-gray-700 hover:bg-gray-100"
                    >
                      <Edit class="h-4 w-4 mr-2" /> Edit Problem
                    </button>
                    <button
                      @click="$emit('delete')"
                      class="flex w-full items-center px-4 py-2 text-md text-red-600 hover:bg-red-50"
                    >
                      <Trash2 class="h-4 w-4 mr-2" /> Delete Problem
                    </button>
                  </div>
                </div>
              </Transition>
            </div>
          </div>

          <!-- Problem Category & Payment -->
          <div class="flex flex-wrap gap-2 mt-4">
            <span
              class="inline-flex items-center rounded-full px-2.5 py-1 text-md font-medium bg-gray-100 text-gray-800 shadow-sm"
            >
              {{ problem.category_details?.name }}
            </span>

            <span
              v-if="problem?.payment_option === 'paid'"
              class="inline-flex items-center rounded-full px-3 py-1 text-md font-medium transition-all border-0 bg-green-50 text-green-700"
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
                <UIcon name="i-mdi-currency-bdt" class="text-green-600" />
                {{ problem?.payment_amount }}
              </span>
            </span>
            <span
              v-else
              class="inline-flex items-center rounded-full px-3 py-1 text-md font-medium bg-blue-50 text-blue-700"
            >
              I need help for free
            </span>

            <span
              v-if="problem.status === 'solved'"
              class="inline-flex items-center rounded-full px-3 py-1 text-md font-medium bg-green-600 text-white shadow-sm"
            >
              <CheckCircle class="h-3 w-3 mr-1" />
              Solved
            </span>
          </div>

          <!-- Problem Title & Content -->
          <h1 class="text-lg mt-4 font-semibold text-green-900">
            {{ problem.title }}
          </h1>
          <p class="mt-3 text-gray-700 whitespace-pre-line leading-relaxed">
            {{ problem.description }}
          </p>

          <!-- Problem Stats -->
          <div
            class="mt-6 flex items-center justify-between border-t border-b border-gray-200 py-3"
          >
            <div class="flex items-center space-x-4">
              <span class="text-sm text-gray-600 flex items-center">
                <MessageSquare class="h-4 w-4 mr-1.5" />
                {{ problem.mindforce_comments?.length || 0 }} Advices
              </span>

              <span class="text-sm text-gray-600 flex items-center">
                <Eye class="h-4 w-4 mr-1.5" />
                {{ problem?.views || 0 }}
              </span>
            </div>
            
            <!-- Mark as Solved button (only visible for problem owner and when problem is not already solved) -->
            <button
              v-if="isOwner && problem.status !== 'solved'"
              @click="$emit('mark-as-solved')"
              class="inline-flex items-center rounded-md px-3 py-1.5 text-sm font-medium transition-all bg-green-600 text-white hover:bg-green-700 shadow-sm"
            >
              <CheckCircle class="h-4 w-4 mr-1.5" />
              Mark as Solved
            </button>
          </div>

          <!-- Comments Section -->
          <div class="mt-6">
            <h3 class="text-lg font-medium mb-4 text-gray-700">
              Advice ({{ problem.mindforce_comments?.length || 0 }})
            </h3>

            <!-- Comment List -->
            <div class="space-y-4">
              <div
                v-if="problem.comments?.length > 0"
                class="space-y-2"
              >
                <div
                  v-for="comment in problem.comments"
                  :key="comment.id"
                  :class="[
                    'px-2 py-2 sm:py-3 rounded-lg transition-all',
                    comment.is_solved
                      ? 'bg-green-50 border border-green-100 shadow-sm'
                      : 'bg-gray-50 hover:bg-gray-100',
                  ]"
                >
                  <div class="flex justify-between">
                    <div class="flex items-center">
                      <div
                        class="h-10 w-10 rounded-full overflow-hidden border-2 border-white shadow-sm"
                      >
                        <img
                          :src="comment?.author_details?.image || '/placeholder.svg'"
                          :alt="comment?.author_details?.name"
                          class="h-full w-full object-cover"
                        />
                      </div>
                      <div class="ml-3">
                        <div class="flex items-center">
                          <p class="font-medium">
                            {{ comment?.author_details?.name }}
                          </p>
                          
                        </div>
                        <p class="text-sm text-gray-500">
                          {{ formatTimeAgo(comment.created_at) }}
                        </p>
                      </div>
                    </div>

                    <button
                      v-if="isOwner"
                      @click="$emit('mark-solution', comment.id)"
                      :class="[
                        'inline-flex items-center justify-center rounded-md text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-8 px-3',
                        comment.is_solved
                          ? 'bg-green-600 text-white shadow-sm'
                          : 'border border-gray-200 bg-white hover:bg-gray-50 text-gray-700',
                      ]"
                    >
                      <CheckCircle class="h-3 w-3 mr-1" />
                      {{ comment.is_solved ? "Solution" : "Solution!" }}
                    </button>
                  </div>

                  <p class="mt-1 sm:mt-3 text-md text-gray-700 leading-relaxed">
                    {{ comment.content }}
                  </p>
                </div>
              </div>

              <div
                v-else
                class="flex flex-col items-center justify-center py-12 bg-gray-50 rounded-lg"
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
                  class="text-gray-400 mb-3"
                >
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="8" y1="12" x2="16" y2="12"></line>
                </svg>
                <p class="text-gray-500">
                  No advice have been posted yet. Be the first to help!
                </p>
              </div>
            </div>

            <!-- Add Comment with improved design -->
            <div class="mt-8" v-if="currentUserId && problem.status !== 'solved'">
              <h4 class="text-md font-medium mb-2">Write an advice</h4>
              <textarea
                v-model="newComment"
                placeholder="Share your solution or ask for clarification..."
                class="flex w-full rounded-lg border border-gray-200 bg-white px-4 py-3 text-md ring-offset-background placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all"
                rows="3"
              ></textarea>
              <div class="flex justify-end mt-3 mb-10">
                <button
                  @click="submitComment"
                  :disabled="!newComment.trim() || isSubmittingComment"
                  :class="[
                    'inline-flex items-center justify-center rounded-lg text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2',
                    newComment.trim() && !isSubmittingComment
                      ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-md hover:shadow-sm'
                      : 'bg-gray-200 text-gray-500',
                  ]"
                >
                  <span v-if="isSubmittingComment" class="flex items-center">
                    <svg
                      class="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      ></circle>
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      ></path>
                    </svg>
                    Submitting...
                  </span>
                  <span v-else class="flex items-center">
                    <Send class="h-4 w-4 mr-1.5" />
                    Submit
                  </span>
                </button>
              </div>
            </div>

            <!-- Message for solved problems -->
            <div v-else-if="problem.status === 'solved'" class="mt-8 p-4 bg-green-50 rounded-lg border border-green-100 mb-10">
              <div class="flex items-center">
                <CheckCircle class="h-5 w-5 text-green-600 mr-2" />
                <h4 class="text-md font-medium text-green-800">This problem has been marked as solved</h4>
              </div>
              <p class="mt-1 text-sm text-green-700">
                New advice cannot be added to solved problems.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref } from "vue";
import { 
  MessageSquare, 
  Eye, 
  CheckCircle, 
  Clock, 
  Send, 
  MoreHorizontal, 
  Edit, 
  Trash2,
  X 
} from "lucide-vue-next";

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  problem: {
    type: Object,
    default: null
  },
  currentUserId: {
    type: [String, Number],
    default: null
  },
  isSubmittingComment: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits([
  'update:modelValue', 
  'photo-view', 
  'mark-solution', 
  'add-comment',
  'delete'
]);

const isMenuOpen = ref(false);
const newComment = ref("");

const isOwner = computed(() => {
  return props.problem?.user_details?.id === props.currentUserId;
});

const toggleMenu = () => {
  isMenuOpen.value = !isMenuOpen.value;
};

const submitComment = () => {
  if (newComment.value.trim() && !props.isSubmittingComment) {
    emit('add-comment', newComment.value);
    newComment.value = ""; // Clear the comment
  }
};

// Time formatting function
const formatTimeAgo = (dateString) => {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
};

// Close the menu when clicking outside
onMounted(() => {
  document.addEventListener('click', (event) => {
    if (isMenuOpen.value) {
      isMenuOpen.value = false;
    }
  });
});

// Cleanup event listener
onUnmounted(() => {
  document.removeEventListener('click', () => {});
});
</script>