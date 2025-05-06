<template>
  <div
    class="flex items-center justify-between mb-3 bg-slate-50 py-3 rounded-xl"
  >
    <div class="flex items-center space-x-3 flex-1 pl-2">
      <div class="relative group">
        <NuxtLink :to="`/business-network/profile/${post.author}`">
          <!-- Pro user badge with improved color ring around profile picture -->
          <div
            v-if="post?.author_details?.is_pro"
            class="absolute inset-0 rounded-full border-2 pro-border-ring z-10"
          ></div>
          <img
            :src="post?.author_details?.image || '/placeholder.svg'"
            :alt="post?.author_details?.name"
            class="size-14 rounded-full cursor-pointer object-cover border-2 border-white dark:border-slate-700 shadow-md transition-all duration-300 group-hover:shadow-lg transform group-hover:scale-105"
          />
          <!-- Pro text badge -->
          <div
            v-if="post?.author_details?.is_pro"
            class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1.5 py-0.5 flex items-center justify-center shadow-lg z-20 text-[9px] font-bold"
          >
            PRO
          </div>
          <!-- Subtle glow effect on hover -->
          <div
            :class="[
              'absolute inset-0 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-md -z-10',
              'bg-gradient-to-r from-[#7f00ff]/20 to-[#e100ff]/20',
            ]"
          ></div>
        </NuxtLink>
      </div>

      <div class="flex-1">
        <NuxtLink
          :to="`/business-network/profile/${post.author}`"
          class="font-semibold text-gray-900 dark:text-white text-md hover:cursor-pointer flex gap-1 w-full items-center transition-colors hover:text-blue-600 dark:hover:text-blue-400"
        >
          <p class="truncate max-w-[220px]">
            {{ post?.author_details?.name }}
          </p>
          <!-- Removed Pro text badge next to username -->
          <div
            v-if="post?.author_details?.kyc"
            class="text-blue-500 flex items-center"
          >
            <UIcon name="i-mdi-check-decagram" class="w-3.5 h-3.5" />
          </div>
        </NuxtLink>

        <p
          class="text-sm font-medium bg-transparent py-0.5 text-slate-600 dark:text-slate-400 truncate max-w-[220px]"
        >
          {{ post?.author_details?.profession || "" }}
        </p>

        <p
          class="text-sm text-gray-500 dark:text-gray-400 flex items-center gap-1"
        >
          <UIcon name="i-heroicons-clock" class="h-3 w-3" />
          {{ formatTimeAgo(post?.created_at) }}
        </p>
      </div>
    </div>

    <div class="flex items-center gap-2">
      <!-- Follow button removed from feed posts -->

      <div class="relative">
        <button
          class="h-8 w-8 rounded-full hover:bg-gray-100/80 dark:hover:bg-slate-700/80 flex items-center justify-center transition-colors backdrop-blur-sm"
          @click.stop="$emit('toggle-dropdown', post)"
        >
          <MoreHorizontal class="h-4 w-4 text-gray-600 dark:text-gray-300" />
        </button>

        <!-- Dropdown Menu with glassmorphism effect -->
        <div
          v-if="post?.showDropdown"
          class="absolute right-0 mt-1 w-56 bg-white/90 dark:bg-slate-800/90 backdrop-blur-md rounded-lg shadow-xl border border-gray-100/50 dark:border-slate-700/50 z-20 premium-shadow transform transition-all duration-200 animate-fade-in-down"
          @click.stop
        >
          <div class="py-1.5">
            <button
              class="flex items-center w-full px-4 py-2.5 text-sm text-gray-800 dark:text-gray-200 hover:bg-blue-50/50 dark:hover:bg-slate-700/50 transition-colors"
              @click.stop="$emit('toggle-save', post)"
              v-if="user?.user"
            >
              <Bookmark
                :class="[
                  'h-4 w-4 mr-2.5',
                  post.isSaved ||
                  savedPosts.some(
                    (i) => i.post === post.id && i.user === user.user.id
                  )
                    ? 'text-blue-600 dark:text-blue-500 fill-blue-600 dark:fill-blue-500'
                    : '',
                ]"
              />
              <span>
                {{
                  post.isSaved ||
                  savedPosts.some(
                    (i) => i.post === post.id && i.user === user?.user?.id
                  )
                    ? "Unsave post"
                    : "Save post"
                }}
              </span>
            </button>

            <button
              class="flex items-center w-full px-4 py-2.5 text-sm text-gray-800 dark:text-gray-200 hover:bg-blue-50/50 dark:hover:bg-slate-700/50 transition-colors"
              @click="openPostDeleteModal(post)"
              v-if="post.author_details?.id === user?.user?.id"
            >
              <UIcon
                name="i-material-symbols-light-delete-outline"
                class="h-4 w-4 mr-2.5 text-red-500 dark:text-red-400"
              />
              <span>Delete post</span>
            </button>

            <button
              class="flex items-center w-full px-4 py-2.5 text-sm text-gray-800 dark:text-gray-200 hover:bg-blue-50/50 dark:hover:bg-slate-700/50 transition-colors"
              @click.stop="$emit('copy-link', post)"
            >
              <Link2
                class="h-4 w-4 mr-2.5 text-purple-600 dark:text-purple-400"
              />
              <span>Copy link</span>
            </button>

            <hr
              class="my-1.5 border-gray-200/50 dark:border-gray-700/50"
              v-if="user"
            />

            <button
              class="flex items-center w-full px-4 py-2.5 text-sm text-gray-800 dark:text-gray-200 hover:bg-blue-50/50 dark:hover:bg-slate-700/50 transition-colors"
              v-if="user"
            >
              <Flag class="h-4 w-4 mr-2.5 text-amber-600 dark:text-amber-400" />
              <span>Report post</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete modal with glassmorphism effect -->
    <Teleport to="body">
      <div
        v-if="postToDelete"
        class="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in"
        @click="postToDelete = null"
      >
        <div
          class="bg-white/90 dark:bg-slate-800/90 backdrop-blur-md rounded-xl max-w-sm w-full p-6 shadow-2xl border border-white/20 dark:border-slate-700/30 transform transition-all duration-300 animate-scale-in"
          @click.stop
        >
          <div class="flex items-center justify-between mb-4">
            <h3
              class="text-lg font-semibold text-gray-900 dark:text-white flex items-center"
            >
              <UIcon
                name="i-heroicons-exclamation-triangle"
                class="w-5 h-5 text-red-500 mr-2"
              />
              <span>Delete Post</span>
            </h3>
            <button
              @click="postToDelete = null"
              class="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
            >
              <UIcon name="i-heroicons-x-mark" class="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <p class="text-gray-600 dark:text-gray-300 mb-5">
            Are you sure you want to delete this post? This action cannot be
            undone.
          </p>

          <div class="flex justify-end space-x-3">
            <button
              @click="postToDelete = null"
              class="px-4 py-2 border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
            >
              Cancel
            </button>
            <button
              @click="handlePostDelete(postToDelete)"
              class="px-4 py-2 bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 text-white rounded-lg shadow-md hover:shadow-lg transition-all"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import {
  UserPlus,
  Check,
  MoreHorizontal,
  Bookmark,
  Link2,
  UserX,
  Flag,
} from "lucide-vue-next";

const { user } = useAuth();
const { get, del } = useApi();
const savedPosts = ref([]);
const postToDelete = ref();
const toast = useToast();
const selectedEditPost = ref(null);
const isCreatePostOpen = ref(false);

defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    default: null,
  },
});

defineEmits(["toggle-dropdown", "toggle-save", "copy-link"]);

async function getSavedPosts() {
  const { data } = await get(`/bn/posts/save/`);
  if (data) savedPosts.value = data;
}
await getSavedPosts();

function openPostDeleteModal(post) {
  postToDelete.value = post;
}

async function handlePostDelete(post) {
  const res = await del(`/bn/posts/${post.id}/`);
  if (res.data === undefined) {
    postToDelete.value = null;
    toast.add({
      title: "Post deleted",
      description: "Post has been deleted successfully.",
    });
    window.location.reload();
    return;
  }
}

function editPost(post) {
  // Pass the post to the component
  selectedEditPost.value = post;
}

// Format time ago function
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
</script>

<style scoped>
/* Animation for dropdown */
.animate-fade-in-down {
  animation: fadeInDown 0.2s ease-out;
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out;
}

.animate-scale-in {
  animation: scaleIn 0.3s ease-out;
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

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes scaleIn {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

/* Improved Pro user border with proper rounded style */
.pro-border-ring {
  border-radius: 9999px; /* Ensure full circle */
  border: 2px solid transparent;
  background: linear-gradient(to right, #7f00ff, #e100ff, #9500ff, #d700ff)
    border-box;
  -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
}

/* Premium shadow effect */
.premium-shadow {
  box-shadow: 0 8px 16px -2px rgba(0, 0, 0, 0.1),
    0 4px 8px -2px rgba(0, 0, 0, 0.05);
}
</style>
