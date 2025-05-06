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
        <div
          class="px-2 sm:px-6 py-6 overflow-y-auto custom-scrollbar max-h-[80vh]"
        >
          <!-- Problem Header with enhanced design -->
          <div class="flex justify-between items-start">
            <div class="flex items-center">
              <div
                class="h-12 w-12 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 shadow-sm relative glow-effect"
              >
                <!-- Pro user border with gradient effect -->
                <div
                  v-if="problem.user_details?.is_pro"
                  class="absolute inset-0 rounded-full pro-border-ring z-20"
                  style="pointer-events: none"
                ></div>
                <div
                  class="absolute inset-0 bg-gradient-to-br from-blue-400 to-violet-500 opacity-0 z-50"
                ></div>
                <img
                  :src="problem.user_details?.image || '/placeholder.svg'"
                  :alt="problem.user_details?.name"
                  class="h-full w-full object-cover relative z-15 rounded-full overflow-hidden"
                  style="object-fit: cover; aspect-ratio: 1/1"
                />
                <!-- Pro badge with increased z-index and white border -->
                <div
                  v-if="problem.user_details?.is_pro"
                  class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1.5 py-0.5 flex items-center justify-center shadow-lg z-30 text-[9px] font-bold"
                  style="border: 1px solid rgba(255, 255, 255, 0.5)"
                >
                  PRO
                </div>
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
              <div
                v-if="user?.user && problem.user === user.user.id"
                class="relative"
              >
                <button
                  @click.stop="toggleMenu"
                  class="inline-flex items-center justify-center rounded-lg text-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-slate-100 dark:hover:bg-slate-700 h-8 w-8 p-0"
                >
                  <MoreHorizontal
                    class="h-4 w-4 text-slate-600 dark:text-slate-300"
                  />
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
              {{ problem?.payment_amount > 0 ? `I can pay ` : "Paid Help" }}
              <span
                v-if="problem?.payment_amount > 0"
                class="inline-flex items-center"
              >
                <UIcon
                  name="i-mdi-currency-bdt"
                  class="text-emerald-600 dark:text-emerald-400"
                />
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
          <div
            class="mt-3 text-slate-700 dark:text-slate-300 whitespace-pre-line leading-relaxed prose dark:prose-invert max-w-none"
          >
            {{ problem.description }}
          </div>

          <!-- Problem Stats - Enhanced styling -->
          <div
            class="mt-6 flex items-center justify-between border-t border-b border-slate-200 dark:border-slate-700 py-3"
          >
            <div class="flex items-center space-x-4">
              <span
                class="text-sm text-slate-600 dark:text-slate-400 flex items-center group"
              >
                <MessageSquare
                  class="h-4 w-4 mr-1.5 group-hover:text-blue-500 transition-colors"
                />
                <span class="group-hover:text-blue-500 transition-colors">
                  {{ localComments.length || 0 }} Advices
                </span>
              </span>

              <span
                class="text-sm text-slate-600 dark:text-slate-400 flex items-center"
              >
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
            <h3
              class="text-lg font-medium mb-4 text-slate-700 dark:text-slate-300 flex items-center"
            >
              <MessageSquare class="h-5 w-5 mr-2 text-blue-500" />
              Advice ({{ localComments.length || 0 }})
            </h3>

            <!-- Comment List with enhanced styling -->
            <div class="space-y-4">
              <div v-if="localComments.length > 0" class="space-y-3">
                <div
                  v-for="comment in sortedComments"
                  :key="comment.id"
                  :class="[
                    'px-3 py-3 sm:py-4 rounded-lg transition-all transform hover:scale-[1.01]',
                    comment.is_solved
                      ? 'bg-gradient-to-br from-emerald-50 to-green-50 dark:from-emerald-900/20 dark:to-green-900/20 border border-emerald-100 dark:border-emerald-900/30 shadow-sm'
                      : 'bg-slate-50 dark:bg-slate-800/50 hover:bg-slate-100 dark:hover:bg-slate-800 border border-slate-100 dark:border-slate-700/50',
                    comment.is_temp ? 'opacity-70' : '',
                  ]"
                >
                  <div class="flex justify-between">
                    <div class="flex items-center">
                      <div
                        :class="[
                          'h-10 w-10 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 shadow-sm relative',
                          isCommentAuthorPro(comment) ? 'pro-ring' : '',
                        ]"
                      >
                        <!-- Pro user border with gradient effect -->
                        <div
                          v-if="isCommentAuthorPro(comment)"
                          class="absolute inset-0 rounded-full pro-border-ring z-20"
                        ></div>
                        <div
                          class="absolute inset-0 bg-gradient-to-br from-blue-400 to-violet-500 opacity-0 z-50"
                        ></div>
                        <img
                          :src="
                            comment?.author_details?.image || '/placeholder.svg'
                          "
                          :alt="comment?.author_details?.name"
                          class="h-full w-full object-cover relative z-15 rounded-full overflow-hidden"
                          style="object-fit: cover; aspect-ratio: 1/1"
                        />
                        <!-- Pro text badge with fixed z-index -->
                        <div
                          v-if="isCommentAuthorPro(comment)"
                          class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1.5 py-0.5 flex items-center justify-center shadow-lg z-40 text-[9px] font-bold"
                          style="border: 1px solid rgba(255, 255, 255, 0.5)"
                        >
                          PRO
                        </div>
                      </div>
                      <div class="ml-3">
                        <div class="flex items-center">
                          <p
                            class="font-medium text-slate-800 dark:text-slate-200"
                          >
                            {{ comment?.author_details?.name }}
                            <span
                              v-if="comment.is_temp"
                              class="italic text-sm opacity-70"
                              >(Posted!)</span
                            >
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
                    <!-- Updated Mark Solution button with spinner and conditionally showing -->
                    <button
                      v-if="
                        isOwner &&
                        problem.status !== 'solved' &&
                        !comment.is_solved
                      "
                      @click="$emit('mark-solution', comment.id)"
                      :disabled="processingCommentIds.includes(comment.id)"
                      :class="[
                        'inline-flex items-center justify-center rounded-md text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-70 h-8 px-3 transform hover:-translate-y-0.5 active:translate-y-0',
                        processingCommentIds.includes(comment.id)
                          ? 'bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400'
                          : 'border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300',
                      ]"
                    >
                      <span
                        v-if="processingCommentIds.includes(comment.id)"
                        class="loading-spinner mr-1.5"
                      ></span>
                      <CheckCircle v-else class="h-3 w-3 mr-1" />
                      Mark Solution
                    </button>
                  </div>

                  <p
                    class="mt-2 sm:mt-3 text-md text-slate-700 dark:text-slate-300 leading-relaxed"
                  >
                    {{ comment.content }}
                  </p>
                  
                  <!-- Comment Media Gallery -->
                  <div 
                    v-if="comment.media && comment.media.length > 0" 
                    class="mt-3 flex flex-wrap gap-2"
                  >
                    <div 
                      v-for="(media, index) in comment.media" 
                      :key="index"
                      class="relative h-20 w-20 overflow-hidden rounded-md border border-slate-200 dark:border-slate-700 cursor-pointer"
                      @click="openMediaViewer(comment, index)"
                    >
                      <img 
                        :src="media.preview || media.image" 
                        alt="Comment media" 
                        class="h-full w-full object-cover transition-transform hover:scale-105"
                      />
                    </div>
                  </div>
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
                  No advice has been posted yet. Be the first to help!
                </p>
              </div>
            </div>

            <!-- Add Comment with premium styling -->
            <div
              class="mt-8"
              v-if="currentUserId && problem.status !== 'solved'"
            >
              <h4
                class="text-md font-medium mb-2 text-slate-700 dark:text-slate-300 flex items-center"
              >
                <Send class="h-4 w-4 mr-2 text-blue-500" />
                Write an advice
              </h4>
              <textarea
                v-model="newComment"
                placeholder="Share your solution or ask for clarification..."
                class="flex w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-3 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 dark:focus-visible:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 min-h-[120px] transition-all resize-none"
                rows="3"
              ></textarea>
              
              <!-- Media upload section -->
              <div class="mt-3">
                <div class="flex items-center space-x-2">
                  <button
                    @click="triggerMediaUpload"
                    type="button"
                    class="flex items-center space-x-1.5 px-3 py-1.5 text-sm text-blue-600 bg-blue-50 hover:bg-blue-100 dark:bg-blue-900/20 dark:hover:bg-blue-900/30 dark:text-blue-400 rounded-lg transition-colors"
                  >
                    <ImagePlus class="h-4 w-4" />
                    <span>Add Photo</span>
                  </button>
                  <span class="text-sm text-slate-500 dark:text-slate-400">{{ commentMedia.length }}/3 images</span>
                  <input 
                    type="file"
                    ref="mediaFileInput"
                    accept="image/*"
                    class="hidden"
                    @change="handleMediaUpload"
                  />
                </div>
                
                <!-- Media preview section -->
                <div v-if="commentMedia.length > 0" class="mt-3 flex flex-wrap gap-2">
                  <div 
                    v-for="(media, index) in commentMedia" 
                    :key="index"
                    class="relative h-20 w-20 rounded-md overflow-hidden border border-slate-200 dark:border-slate-700 group"
                  >
                    <img 
                      :src="media.preview" 
                      alt="Media preview" 
                      class="h-full w-full object-cover"
                    />
                    <button
                      @click="removeMedia(index)"
                      class="absolute top-1 right-1 bg-red-500 rounded-full p-1 hover:bg-red-600 transition-colors opacity-0 group-hover:opacity-100"
                    >
                      <X class="h-3 w-3 text-white" />
                    </button>
                  </div>
                </div>
              </div>
              
              <div class="flex justify-end mt-3 mb-10">
                <button
                  @click="submitComment"
                  :disabled="(!newComment.trim() && commentMedia.length === 0) || isSubmittingComment"
                  :class="[
                    'inline-flex items-center justify-center rounded-lg text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-5 py-2',
                    (!newComment.trim() && commentMedia.length === 0) || isSubmittingComment
                      ? 'bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400'
                      : 'bg-gradient-to-r from-blue-500 to-violet-500 hover:from-blue-600 hover:to-violet-600 text-white shadow-sm hover:shadow-lg transform hover:-translate-y-0.5 active:translate-y-0',
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

            <!-- Login prompt for non-logged in users -->
            <div
              v-else-if="!currentUserId && problem.status !== 'solved'"
              class="mt-8 p-4 bg-gradient-to-br from-amber-50 to-orange-50 dark:from-amber-900/20 dark:to-orange-900/20 rounded-lg border border-amber-100 dark:border-amber-900/30 mb-10"
            >
              <div class="flex items-center">
                <div
                  class="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-full mr-3"
                >
                  <LockIcon
                    class="h-5 w-5 text-amber-600 dark:text-amber-400"
                  />
                </div>
                <div>
                  <h4
                    class="text-md font-medium text-amber-800 dark:text-amber-400"
                  >
                    Authentication Required
                  </h4>
                  <p class="mt-1 text-sm text-amber-700 dark:text-amber-500">
                    Please
                    <NuxtLink to="/auth/login" class="font-medium underline"
                      >login</NuxtLink
                    >
                    or
                    <NuxtLink to="/auth/register" class="font-medium underline"
                      >register</NuxtLink
                    >
                    first to add your advice.
                  </p>
                </div>
              </div>
            </div>

            <!-- Message for solved problems with enhanced styling -->
            <div
              v-else-if="problem.status === 'solved'"
              class="mt-8 p-4 bg-gradient-to-br from-emerald-50 to-green-50 dark:from-emerald-900/20 dark:to-green-900/20 rounded-lg border border-emerald-100 dark:border-emerald-900/30 mb-10"
            >
              <div class="flex items-center">
                <div
                  class="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-full mr-3"
                >
                  <CheckCircle
                    class="h-5 w-5 text-emerald-600 dark:text-emerald-400"
                  />
                </div>
                <div>
                  <h4
                    class="text-md font-medium text-emerald-800 dark:text-emerald-400"
                  >
                    This problem has been marked as solved
                  </h4>
                  <p
                    class="mt-1 text-sm text-emerald-700 dark:text-emerald-500"
                  >
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
  Clock,
  LockIcon,
  ImagePlus,
} from "lucide-vue-next";

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  problem: {
    type: Object,
    default: () => ({}),
  },
  currentUserId: {
    type: Number,
    default: null,
  },
  isSubmittingComment: {
    type: Boolean,
    default: false,
  },
  processingCommentIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits([
  "update:modelValue",
  "submit-comment",
  "mark-as-solved",
  "mark-solution",
  "delete",
  "add-comment", // Add this event to support the parent component
  "photo-view", // Add this event for media viewer functionality
]);

const { user } = useAuth();

// State management
const newComment = ref("");
const isMenuOpen = ref(false);
const localComments = ref([]);
const commentSubmitStatus = ref(false);
const commentMedia = ref([]);
const mediaFileInput = ref(null);

// Computed properties
const isOwner = computed(() => {
  return props.currentUserId === props.problem?.user;
});

// Check if user is premium/pro
const isUserPro = computed(() => {
  return (
    props.problem?.user_details?.is_premium ||
    props.problem?.user_details?.subscription_active
  );
});

// Display comments in chronological order (oldest to newest)
const sortedComments = computed(() => {
  // Use localComments to ensure we display what's in our local state
  if (!localComments.value || localComments.value.length === 0) return [];

  // First ensure we don't have duplicate comments (identify by ID)
  const uniqueComments = [];
  const seenIds = new Set();

  localComments.value.forEach((comment) => {
    // Skip temporary comments if we have their real counterparts
    if (
      comment.is_temp &&
      localComments.value.some(
        (c) => !c.is_temp && c.content === comment.content
      )
    ) {
      return;
    }

    // For real comments, check by ID
    if (!comment.is_temp) {
      if (!seenIds.has(comment.id)) {
        seenIds.add(comment.id);
        uniqueComments.push(comment);
      }
    } else {
      // Always include temporary comments
      uniqueComments.push(comment);
    }
  });

  // Then sort them chronologically
  return uniqueComments.sort((a, b) => {
    return new Date(a.created_at) - new Date(b.created_at);
  });
});

// Check if comment author is premium/pro
const isCommentAuthorPro = (comment) => {
  return (
    comment?.author_details?.is_premium ||
    comment?.author_details?.subscription_active
  );
};

// Methods
const toggleMenu = () => {
  isMenuOpen.value = !isMenuOpen.value;
};

const submitComment = () => {
  if (newComment.value.trim() || commentMedia.value.length > 0) {
    // Create temporary local comment while API call is in progress
    const tempComment = createTempComment(newComment.value, commentMedia.value);
    localComments.value.push(tempComment);
    commentSubmitStatus.value = true;

    // Emit events for backend submission
    emit("submit-comment", { content: newComment.value, media: commentMedia.value });
    emit("add-comment", { content: newComment.value, media: commentMedia.value });

    // Clear input and media after submission
    if (!props.isSubmittingComment) {
      newComment.value = "";
      commentMedia.value = [];
    }

    // Auto-scroll to the bottom to see new comment
    scrollToBottom();
  }
};

// Create a temporary comment while waiting for server response
const createTempComment = (content, media) => {
  return {
    id: "temp-" + Date.now(),
    content: content,
    media: media,
    created_at: new Date().toISOString(),
    author_details: {
      id: props.currentUserId,
      name: user.value?.user?.name || "You", // This will be replaced when real data comes back
      image: user.value?.user?.image || "/placeholder.svg", // Temporary placeholder
    },
    is_solved: false,
    is_temp: true, // Flag to identify temporary comments
  };
};

// Scroll to the bottom of comments container
const scrollToBottom = () => {
  setTimeout(() => {
    const container = document.querySelector(".custom-scrollbar");
    if (container) {
      container.scrollTop = container.scrollHeight;
    }
  }, 100);
};

const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
};

const triggerMediaUpload = () => {
  mediaFileInput.value.click();
};

const handleMediaUpload = (event) => {
  const files = event.target.files;
  if (files && files.length > 0) {
    Array.from(files).forEach((file) => {
      if (commentMedia.value.length < 3) {
        const reader = new FileReader();
        reader.onload = (e) => {
          commentMedia.value.push({ file, preview: e.target.result });
        };
        reader.readAsDataURL(file);
      }
    });
  }
};

const removeMedia = (index) => {
  commentMedia.value.splice(index, 1);
};

const openMediaViewer = (comment, index) => {
  if (comment.media && comment.media.length > 0) {
    // Emit an event to open the photo viewer with the comment media
    emit('photo-view', {
      media: comment.media,
      startIndex: index
    });
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
  if (event.key === "Escape" && props.modelValue) {
    emit("update:modelValue", false);
  }
};

// Add event listeners
onMounted(() => {
  document.addEventListener("click", handleClickOutside);
  document.addEventListener("keydown", handleKeydown);
  // Initialize local comments from props
  if (props.problem?.mindforce_comments) {
    localComments.value = [...props.problem.mindforce_comments];
  }
});

// Watch for modal opening to reset state
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal) {
      newComment.value = "";
      isMenuOpen.value = false;
      commentSubmitStatus.value = false;
      commentMedia.value = [];
      if (props.problem?.mindforce_comments) {
        localComments.value = [...props.problem.mindforce_comments];
      }
    }
  }
);

// Watch for changes in problem comments and update local state
watch(
  () => props.problem?.mindforce_comments,
  (newComments) => {
    if (!newComments) return;

    if (commentSubmitStatus.value) {
      // We have local temporary comments waiting to be replaced
      // Remove any temporary comments first
      localComments.value = localComments.value.filter(
        (comment) => !comment.is_temp
      );

      // Then add all server comments that aren't already in our local state
      newComments.forEach((serverComment) => {
        const alreadyExists = localComments.value.some(
          (c) => c.id === serverComment.id
        );
        if (!alreadyExists) {
          localComments.value.push(serverComment);
        }
      });

      // Reset submission status
      commentSubmitStatus.value = false;
    } else {
      // Normal update from parent component, no temporary comments involved
      localComments.value = [...newComments];
    }
  },
  { deep: true }
);
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
  content: "";
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

/* Pro user border with gradient effect */
.pro-border-ring {
  border-radius: 9999px; /* Ensure full circle */
  border: 2px solid transparent;
  background: linear-gradient(to right, #7f00ff, #e100ff, #9500ff, #d700ff)
    border-box;
  -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
}
</style>
