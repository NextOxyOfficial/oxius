<template>
  <div class="flex items-center justify-between mb-2 px-2">
    <div class="flex items-center space-x-3 flex-1">
      <div class="relative">
        <NuxtLink :to="`/business-network/profile/${post.author}`">
          <img
            :src="post?.author_details?.image || '/placeholder.svg'"
            :alt="post?.author_details?.name"
            class="size-14 rounded-full cursor-pointer object-cover"
          />
        </NuxtLink>
      </div>
      <div class="flex-1">
        <NuxtLink
          :to="`/business-network/profile/${post.author}`"
          class="font-semibold text-gray-900 text-md hover:cursor-pointer flex gap-1 w-full"
        >
          <p class="">
            {{ post?.author_details?.name }}
          </p>
          <div
            v-if="post?.author_details?.kyc"
            class="text-blue-500 flex items-center"
          >
            <UIcon name="i-mdi-check-decagram" class="w-3.5 h-3.5" />
            <span
              v-if="post?.author_details?.is_pro"
              class="text-2xs px-1 py-0.5 font-medium"
            >
              <div class="flex items-center gap-0.5">
                <UIcon
                  name="i-heroicons-shield-check"
                  class="size-4 text-indigo-700 font-semibold"
                />
                <span class="text-xs font-semibold text-indigo-700">Pro</span>
              </div>
            </span>
          </div>
        </NuxtLink>
        <p class="text-sm font-semibold bg-white py-0.5 text-slate-500">
          {{ post?.author_details?.profession || "" }}
        </p>
        <p class="text-sm text-gray-500">
          {{ formatTimeAgo(post?.created_at) }}
        </p>
      </div>
    </div>

    <div class="flex items-center gap-2">
      <div class="relative">
        <button
          class="h-8 w-8 rounded-full hover:bg-gray-100 flex items-center justify-center"
          @click.stop="$emit('toggle-dropdown', post)"
        >
          <MoreHorizontal class="h-4 w-4" />
        </button>

        <!-- Dropdown Menu -->
        <div
          v-if="post.showDropdown"
          class="absolute right-0 mt-1 w-56 bg-white rounded-lg shadow-lg border border-gray-200 z-10"
        >
          <div class="py-1">
            <button
              class="flex items-center w-full px-4 py-2 text-sm text-gray-800 hover:bg-gray-100"
              @click.stop="$emit('toggle-save', post)"
              v-if="user"
            >
              <Bookmark
                :class="[
                  'h-4 w-4 mr-2',
                  post.isSaved ||
                  savedPosts.some(
                    (i) => i.post === post.id && i.user === user.user.id
                  )
                    ? 'text-blue-600 fill-blue-600'
                    : '',
                ]"
              />
              {{
                post.isSaved ||
                savedPosts.some(
                  (i) => i.post === post.id && i.user === user.user.id
                )
                  ? "Unsave post"
                  : "Save post"
              }}
            </button>
            <button
              class="flex items-center w-full px-4 py-2 text-sm text-gray-800 hover:bg-gray-100"
              @click="openPostDeleteModal(post)"
              v-if="post.author_details.id === user.user.id"
            >
              <UIcon
                name="i-material-symbols-light-delete-outline"
                class="h-4 w-4 mr-2 text-red-600"
              />
              Delete post
            </button>
            <button
              class="flex items-center w-full px-4 py-2 text-sm text-gray-800 hover:bg-gray-100"
              @click.stop="$emit('copy-link', post)"
            >
              <Link2 class="h-4 w-4 mr-2" />
              Copy link
            </button>
            <hr class="my-1 border-gray-200" v-if="user" />

            <button
              class="flex items-center w-full px-4 py-2 text-sm text-gray-800 hover:bg-gray-100"
              v-if="user"
            >
              <Flag class="h-4 w-4 mr-2" />
              Report post
            </button>
          </div>
        </div>
      </div>
    </div>
    <Teleport to="body">
      <div
        v-if="postToDelete"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="$emit('cancel-delete-comment')"
      >
        <div class="bg-white rounded-lg max-w-sm w-full p-4" @click.stop>
          <h3 class="text-lg font-semibold mb-2">Delete Post</h3>
          <p class="text-gray-600 mb-4">
            Are you sure you want to delete this Post? This action cannot be
            undone.
          </p>
          <div class="flex justify-end space-x-2">
            <button
              @click="postToDelete = null"
              class="px-4 py-2 border border-gray-200 text-gray-800 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              @click="handlePostDelete(postToDelete)"
              class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
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

defineEmits(["toggle-follow", "toggle-dropdown", "toggle-save", "copy-link"]);

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

// Format time ago function
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
</script>
