<template>
  <UContainer class="mt-2 flex-1">
    <!-- Lazyloader component -->
    <div v-if="loading" class="p-4">
      <div class="flex justify-center items-center mb-6">
        <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
      </div>
      <!-- Skeleton loader for post -->
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4">
        <div class="flex items-center space-x-3 mb-4">
          <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded animate-pulse w-1/4"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-1/5"></div>
          </div>
        </div>
        <div class="space-y-2 mb-4">
          <div class="h-5 bg-gray-200 rounded animate-pulse w-3/4"></div>
          <div class="h-4 bg-gray-200 rounded animate-pulse w-full"></div>
          <div class="h-4 bg-gray-200 rounded animate-pulse w-5/6"></div>
          <div class="h-4 bg-gray-200 rounded animate-pulse w-full"></div>
          <div class="h-4 bg-gray-200 rounded animate-pulse w-4/5"></div>
        </div>
        <div class="h-60 bg-gray-200 rounded animate-pulse mb-4"></div>
        <div class="flex justify-between pt-3">
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
        </div>
      </div>
    </div>

    <!-- Actual post content when loaded -->
    <BusinessNetworkPost v-if="!loading" :posts="posts" :id="user?.user?.id" />
  </UContainer>
</template>
<script setup>
definePageMeta({
  layout: "adsy-business-network",
});
import { Loader2 } from "lucide-vue-next";

const posts = ref([]);
const loading = ref(true);
const { get } = useApi();
const { user } = useAuth();
const { id } = useRoute().params;

// Fetch post data
async function fetchPost() {
  try {
    const { data } = await get(`/bn/posts/${id}/`);
    posts.value = [data];
    console.log("posts", data);
  } catch (error) {
    console.error("Error fetching post:", error);
  } finally {
    // Set loading to false when fetch completes
    loading.value = false;
  }
}

// Execute fetch
await fetchPost();
</script>
