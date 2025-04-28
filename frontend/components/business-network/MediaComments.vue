<template>
  <div class="max-h-[20vh] overflow-y-auto mb-3">
    <h4 class="text-sm font-medium text-gray-500 mb-2">Comments</h4>
    <div class="space-y-2">
      <div
        v-for="comment in mediaComments"
        :key="comment.id"
        class="flex items-start space-x-2"
      >
        <div class="flex items-start space-x-2">
          <NuxtLink
            :to="`/business-network/profile/${comment.author_details.id}`"
          >
            <img
              v-if="comment.author_details.image"
              :src="comment.author_details.image"
              alt="User"
              class="w-6 h-6 rounded-full cursor-pointer"
            />
          </NuxtLink>
          <div class="flex-1">
            <div class="bg-gray-50 rounded-lg p-2">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-1.5">
                  <NuxtLink
                    :to="`/business-network/profile/${comment.author_details.id}`"
                    class="text-sm font-medium hover:underline"
                  >
                    {{ comment.author_details.name }}
                  </NuxtLink>
                  <!-- Verified Badge -->
                  <div
                    v-if="comment.author_details.kyc"
                    class="text-blue-500 flex items-center"
                  >
                    <UIcon
                      name="i-mdi-check-decagram"
                      class="w-3 h-3"
                    />
                  </div>
                </div>
              </div>
              <p class="text-sm mt-1">{{ comment.content }}</p>
            </div>
            <div class="flex items-center mt-1 space-x-3">
              <span class="text-sm text-gray-500">{{
                formatTimeAgo(comment.created_at)
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  mediaComments: {
    type: Array,
    required: true
  }
});

defineEmits(['edit-comment', 'delete-comment']);

// Format time ago function
const formatTimeAgo = (dateString) => {
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
