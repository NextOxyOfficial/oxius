<template>
  <div
    class="bg-white border border-gray-100 rounded-lg px-2 py-3 hover:shadow-sm transition-all duration-300 cursor-pointer relative overflow-hidden"
    @click="$emit('click', problem)"
  >
    <!-- Highlight effect on hover that doesn't obscure text -->
    <div
      :class="[
        'absolute inset-0 opacity-0 hover:opacity-10 transition-opacity duration-300 pointer-events-none',
        problem.status === 'solved' ? 'bg-green-50' : (isOwnerProblem ? 'bg-indigo-50' : 'bg-blue-50')
      ]"
    ></div>

    <div class="flex justify-between items-start mb-1 relative">
      <div class="flex items-center">
        <div
          class="h-8 w-8 sm:h-10 sm:w-10 rounded-full overflow-hidden border-2 border-white shadow-sm"
        >
          <img
            :src="problem?.user_details?.image || '/placeholder.svg'"
            :alt="problem?.user_details?.name"
            class="h-full w-full object-cover"
          />
        </div>
        <div class="ml-2 sm:ml-3">
          <p class="text-md sm:text-base font-medium">
            {{ problem?.user_details?.name }}
          </p>
          <p class="text-sm text-gray-500">
            {{ formatTimeAgo(problem?.created_at) }}
          </p>
        </div>
      </div>
      <div class="flex flex-col items-end gap-1">
        <span
          v-if="problem?.payment_option === 'paid'"
          class="inline-flex items-center rounded-full px-2 py-0.5 sm:px-3 sm:py-1 text-sm font-medium transition-all border-0 bg-green-50 text-green-700"
        >
          {{ problem?.payment_amount > 0 ? `I can pay ` : "Paid Help" }}
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
          class="inline-flex items-center rounded-full px-2 py-0.5 sm:px-3 sm:py-1 text-sm font-medium transition-all border-0 bg-blue-50 text-blue-700"
        >
          I need free help!
        </span>
        <span
          class="inline-flex items-center rounded-full px-2 py-0.5 text-sm font-medium transition-all bg-gray-100 text-gray-700 shadow-sm"
        >
          {{ problem?.category_details?.name }}
        </span>
      </div>
    </div>

    <h3
      class="text-base text-gray-700 hover:text-blue-700 transition-colors"
      :class="{ 'hover:text-green-700': problem.status === 'solved', 'hover:text-indigo-700': isOwnerProblem }"
    >
      {{ problem?.title }}
    </h3>


    <div
      class="mt-3 sm:mt-4 flex items-center justify-between relative"
    >
      <div class="flex items-center space-x-3 sm:space-x-4">
        <span class="text-sm text-gray-600 flex items-center">
          <MessageSquare class="h-3 w-3 sm:h-3.5 sm:w-3.5 mr-1" />
          {{ problem?.mindforce_comments?.length || 0 }} Advices
        </span>

        <span class="text-sm text-gray-500 flex items-center">
          <Eye class="h-3 w-3 sm:h-3.5 sm:w-3.5 mr-1" />
          {{ problem?.views || 0 }} views
        </span>
      </div>

      <span
        v-if="problem?.status === 'solved'"
        class="inline-flex items-center rounded-full px-2 py-0.5 text-sm font-medium bg-green-600 text-white"
      >
        <CheckCircle class="h-3 w-3 mr-1" /> Solved
      </span>
    </div>
  </div>
</template>

<script setup>
import { MessageSquare, Eye, CheckCircle } from "lucide-vue-next";

const props = defineProps({
  problem: {
    type: Object,
    required: true
  },
  currentUserId: {
    type: [String, Number],
    default: null
  }
});

const emit = defineEmits(['click', 'photo-view']);

const isOwnerProblem = computed(() => {
  return props.problem?.user_details?.id === props.currentUserId;
});

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
</script>